// =============================================================================
// sync_service.dart — Sincroniza decks, flashcards e progresso com a nuvem
// -----------------------------------------------------------------------------
// Como funciona:
//  1) O SQLite continua sendo a fonte usada pelo app (funciona sem internet).
//  2) Toda alteração fica marcada como "pendente" (sync_pendente = 1) e itens
//     apagados vão para a tabela sync_apagados.
//  3) Com internet: ENVIA os pendentes e depois BAIXA o que mudou na nuvem.
//  4) Se o mesmo item foi mudado em dois aparelhos, vale o mais recente.
//  5) Ouvimos a nuvem em tempo real: mudou em outro aparelho → baixa na hora.
// =============================================================================

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart' as sql;

import '../banco_de_dados/auth_helper.dart';
import '../banco_de_dados/sql_helper.dart';
import 'nuvem_dados.dart';

class SyncService {
  /// Nuvem usada. Fica nula nos testes (aí nada é sincronizado).
  static NuvemDados? nuvem;

  /// Aumenta toda vez que chegam dados novos da nuvem (telas podem escutar).
  static final ValueNotifier<int> mudancasRecebidas = ValueNotifier<int>(0);

  /// Mensagem do último erro de sincronização (null = tudo certo).
  static String? ultimoErro;

  static Timer? _timer;
  static StreamSubscription<void>? _escuta;
  static String? _uidEscutado;
  static bool _rodando = false;
  static bool _repetir = false;

  static Duration atraso = const Duration(seconds: 2);

  /// Liga a sincronização para o usuário logado (chamar após login/abertura).
  static Future<void> iniciar() async {
    if (nuvem == null) return;
    SQLHelper.aoMudarDados = agendar;
    final uid = await _uidAtual();
    if (uid == null) return;
    if (_uidEscutado != uid) {
      await _paraEscuta();
      _uidEscutado = uid;
      try {
        _escuta = nuvem!.ouveMudancas(uid).listen((_) => agendar(),
            onError: (_) {});
      } catch (_) {}
    }
    agendar();
  }

  /// Desliga tudo (logout).
  static Future<void> parar() async {
    _timer?.cancel();
    _timer = null;
    SQLHelper.aoMudarDados = null;
    await _paraEscuta();
  }

  static Future<void> _paraEscuta() async {
    await _escuta?.cancel();
    _escuta = null;
    _uidEscutado = null;
  }

  /// Pede uma sincronização em breve (junta várias alterações seguidas).
  static void agendar() {
    if (nuvem == null) return;
    _timer?.cancel();
    _timer = Timer(atraso, () {
      sincronizar();
    });
  }

  static Future<String?> _uidAtual() async {
    final id = Sessao.usuarioId;
    if (id == null) return null;
    final u = await SQLHelper.pegaUmUsuario(id);
    if (u.isEmpty) return null;
    final uid = (u.first['firebase_uid'] ?? '').toString();
    return uid.isEmpty ? null : uid;
  }

  /// Faz uma rodada completa: envia pendências e baixa novidades.
  /// Devolve true se deu certo.
  static Future<bool> sincronizar() async {
    final n = nuvem;
    final usuarioId = Sessao.usuarioId;
    if (n == null || usuarioId == null) return false;
    final uid = await _uidAtual();
    if (uid == null) return false;

    if (_rodando) {
      _repetir = true;
      return false;
    }
    _rodando = true;
    var ok = true;
    try {
      do {
        _repetir = false;
        await _envia(n, uid, usuarioId);
        final mudou = await _baixa(n, uid, usuarioId);
        if (mudou) mudancasRecebidas.value++;
      } while (_repetir);
      ultimoErro = null;
    } catch (e) {
      ok = false;
      ultimoErro = e.toString();
      debugPrint('Sincronização falhou: $e');
    } finally {
      _rodando = false;
    }
    return ok;
  }

  // ---------------------------------------------------------------------------
  // ENVIO
  // ---------------------------------------------------------------------------
  static Future<void> _envia(NuvemDados n, String uid, int usuarioId) async {
    final db = await SQLHelper.db();

    // apagados primeiro (para o "baixar" não ressuscitar nada)
    final apagados = await db.query('sync_apagados',
        where: 'user_id = ?', whereArgs: [usuarioId]);
    for (final tipo in ['reviews', 'cards', 'decks']) {
      final doTipo = apagados.where((a) => a['tipo'] == tipo).toList();
      if (doTipo.isEmpty) continue;
      await n.enviaLote(uid, tipo, {
        for (final a in doTipo)
          a['uuid'] as String: {
            'deleted': true,
            'updatedAt': a['apagado_em'],
          },
      });
      for (final a in doTipo) {
        await db.delete('sync_apagados',
            where: 'uuid = ? AND tipo = ?', whereArgs: [a['uuid'], a['tipo']]);
      }
    }

    // decks
    final decks = await db.query('decks',
        where: 'user_id = ? AND sync_pendente = 1', whereArgs: [usuarioId]);
    if (decks.isNotEmpty) {
      await n.enviaLote(uid, 'decks', {
        for (final d in decks)
          d['uuid'] as String: {
            'deleted': false,
            'title': d['title'],
            'description': d['description'],
            'color': d['color'],
            'createdAt': d['createdAt'],
            'updatedAt': d['updated_at'],
          },
      });
      for (final d in decks) {
        await db.update('decks', {'sync_pendente': 0},
            where: 'id = ? AND updated_at = ?',
            whereArgs: [d['id'], d['updated_at']]);
      }
    }

    // cards
    final cards = await db.rawQuery(
      'SELECT f.*, d.uuid AS deck_uuid FROM flashcards f '
      'JOIN decks d ON d.id = f.deck_id '
      'WHERE d.user_id = ? AND f.sync_pendente = 1',
      [usuarioId],
    );
    if (cards.isNotEmpty) {
      await n.enviaLote(uid, 'cards', {
        for (final c in cards)
          c['uuid'] as String: {
            'deleted': false,
            'deckUuid': c['deck_uuid'],
            'question': c['question'],
            'answer': c['answer'],
            'isMastered': c['is_mastered'],
            'easeFactor': c['ease_factor'],
            'intervalDays': c['interval_days'],
            'repetitions': c['repetitions'],
            'nextReview': c['next_review'],
            'lastReview': c['last_review'],
            'createdAt': c['createdAt'],
            'updatedAt': c['updated_at'],
          },
      });
      for (final c in cards) {
        await db.update('flashcards', {'sync_pendente': 0},
            where: 'id = ? AND updated_at = ?',
            whereArgs: [c['id'], c['updated_at']]);
      }
    }

    // revisões (histórico de estudo)
    final revs = await db.rawQuery(
      'SELECT r.*, f.uuid AS card_uuid FROM revisoes r '
      'JOIN flashcards f ON f.id = r.flashcard_id '
      'JOIN decks d ON d.id = f.deck_id '
      'WHERE d.user_id = ? AND r.sync_pendente = 1',
      [usuarioId],
    );
    if (revs.isNotEmpty) {
      await n.enviaLote(uid, 'reviews', {
        for (final r in revs)
          r['uuid'] as String: {
            'deleted': false,
            'cardUuid': r['card_uuid'],
            'quality': r['quality'],
            'reviewedAt': r['reviewed_at'],
            'updatedAt': r['reviewed_at'],
          },
      });
      for (final r in revs) {
        await db.update('revisoes', {'sync_pendente': 0},
            where: 'id = ?', whereArgs: [r['id']]);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // DOWNLOAD
  // ---------------------------------------------------------------------------
  static Future<int?> _cursor(sql.Database db, String chave) async {
    final r = await db.query('sync_meta',
        where: 'chave = ?', whereArgs: [chave], limit: 1);
    if (r.isEmpty) return null;
    return int.tryParse((r.first['valor'] ?? '').toString());
  }

  static Future<void> _salvaCursor(
      sql.DatabaseExecutor ex, String chave, int valor) async {
    await ex.insert('sync_meta', {'chave': chave, 'valor': '$valor'},
        conflictAlgorithm: sql.ConflictAlgorithm.replace);
  }

  static DateTime _data(Object? v) =>
      DateTime.tryParse((v ?? '').toString()) ??
      DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

  static Future<bool> _baixa(NuvemDados n, String uid, int usuarioId) async {
    final db = await SQLHelper.db();
    var mudou = false;

    for (final tipo in ['decks', 'cards', 'reviews']) {
      final chave = 'pull_${uid}_$tipo';
      final docs = await n.busca(uid, tipo, depoisDe: await _cursor(db, chave));
      if (docs.isEmpty) continue;

      await db.transaction((txn) async {
        for (final d in docs) {
          final alterou = switch (tipo) {
            'decks' => await _aplicaDeck(txn, d, usuarioId),
            'cards' => await _aplicaCard(txn, d, usuarioId),
            _ => await _aplicaRevisao(txn, d, usuarioId),
          };
          if (alterou) mudou = true;
        }
        await _salvaCursor(txn, chave,
            docs.map((d) => d.sincronizadoEm).reduce((a, b) => a > b ? a : b));
      });
    }
    return mudou;
  }

  static Future<bool> _foiApagadoAqui(
      sql.DatabaseExecutor ex, String uuid, String tipo) async {
    final r = await ex.query('sync_apagados',
        where: 'uuid = ? AND tipo = ?', whereArgs: [uuid, tipo], limit: 1);
    return r.isNotEmpty;
  }

  static Future<bool> _aplicaDeck(
      sql.DatabaseExecutor ex, DocNuvem d, int usuarioId) async {
    final x = d.dados;
    final local = await ex.query('decks',
        where: 'uuid = ?', whereArgs: [d.id], limit: 1);
    final apagado = x['deleted'] == true;
    final remotoEm = _data(x['updatedAt']);

    if (local.isNotEmpty) {
      final l = local.first;
      if (!_data(l['updated_at']).isBefore(remotoEm) && !apagado) return false;
      if (apagado) {
        // apagar vale se for mais novo que a última mudança daqui
        if (_data(l['updated_at']).isAfter(remotoEm)) return false;
        await ex.delete('decks', where: 'id = ?', whereArgs: [l['id']]);
        return true;
      }
      await ex.update(
          'decks',
          {
            'title': x['title'],
            'description': x['description'],
            'color': x['color'],
            'updated_at': x['updatedAt'],
            'sync_pendente': 0,
          },
          where: 'id = ?',
          whereArgs: [l['id']]);
      return true;
    }
    if (apagado || await _foiApagadoAqui(ex, d.id, 'decks')) return false;
    await ex.insert('decks', {
      'user_id': usuarioId,
      'title': x['title'] ?? '',
      'description': x['description'],
      'color': x['color'] ?? 0xFF6C4DFF,
      'uuid': d.id,
      'updated_at': x['updatedAt'],
      'sync_pendente': 0,
      if (x['createdAt'] != null) 'createdAt': x['createdAt'],
    });
    return true;
  }

  static Future<bool> _aplicaCard(
      sql.DatabaseExecutor ex, DocNuvem d, int usuarioId) async {
    final x = d.dados;
    final local = await ex.query('flashcards',
        where: 'uuid = ?', whereArgs: [d.id], limit: 1);
    final apagado = x['deleted'] == true;
    final remotoEm = _data(x['updatedAt']);

    if (local.isNotEmpty) {
      final l = local.first;
      if (apagado) {
        if (_data(l['updated_at']).isAfter(remotoEm)) return false;
        await ex.delete('flashcards', where: 'id = ?', whereArgs: [l['id']]);
        return true;
      }
      if (!_data(l['updated_at']).isBefore(remotoEm)) return false;
      await ex.update('flashcards', _camposCard(x),
          where: 'id = ?', whereArgs: [l['id']]);
      return true;
    }
    if (apagado || await _foiApagadoAqui(ex, d.id, 'cards')) return false;
    final deck = await ex.query('decks',
        columns: ['id'],
        where: 'uuid = ? AND user_id = ?',
        whereArgs: [x['deckUuid'], usuarioId],
        limit: 1);
    if (deck.isEmpty) return false; // deck não existe (mais): ignora
    await ex.insert('flashcards', {
      'deck_id': deck.first['id'],
      'uuid': d.id,
      ..._camposCard(x),
      if (x['createdAt'] != null) 'createdAt': x['createdAt'],
    });
    return true;
  }

  static Map<String, Object?> _camposCard(Map<String, dynamic> x) => {
        'question': x['question'] ?? '',
        'answer': x['answer'] ?? '',
        'is_mastered': x['isMastered'] ?? 0,
        'ease_factor': (x['easeFactor'] as num?)?.toDouble() ?? 2.5,
        'interval_days': x['intervalDays'] ?? 0,
        'repetitions': x['repetitions'] ?? 0,
        'next_review': x['nextReview'] ?? DateTime.now().toIso8601String(),
        'last_review': x['lastReview'],
        'updated_at': x['updatedAt'],
        'sync_pendente': 0,
      };

  static Future<bool> _aplicaRevisao(
      sql.DatabaseExecutor ex, DocNuvem d, int usuarioId) async {
    final x = d.dados;
    if (x['deleted'] == true) return false;
    final ja = await ex.query('revisoes',
        columns: ['id'], where: 'uuid = ?', whereArgs: [d.id], limit: 1);
    if (ja.isNotEmpty) return false;
    final card = await ex.rawQuery(
      'SELECT f.id FROM flashcards f JOIN decks d ON d.id = f.deck_id '
      'WHERE f.uuid = ? AND d.user_id = ?',
      [x['cardUuid'], usuarioId],
    );
    if (card.isEmpty) return false;
    await ex.insert('revisoes', {
      'flashcard_id': card.first['id'],
      'quality': x['quality'] ?? 0,
      'reviewed_at': x['reviewedAt'] ?? DateTime.now().toIso8601String(),
      'uuid': d.id,
      'sync_pendente': 0,
    });
    return true;
  }
}

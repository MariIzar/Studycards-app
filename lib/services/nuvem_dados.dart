// =============================================================================
// nuvem_dados.dart — Armazenamento dos dados do usuário na nuvem (Firestore)
// -----------------------------------------------------------------------------
// Estrutura no Firestore (cada usuário só enxerga a própria pasta, pelas regras):
//   users/{uid}/decks/{uuid}    users/{uid}/cards/{uuid}    users/{uid}/reviews/{uuid}
// Cada documento tem `syncedAt` (hora do servidor): é ele que diz o que é novo
// para cada aparelho, mesmo que o relógio do celular esteja errado.
// =============================================================================

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

/// Um documento baixado da nuvem.
class DocNuvem {
  final String id;
  final Map<String, dynamic> dados;

  /// Hora do servidor em microssegundos (cursor de "o que há de novo").
  final int sincronizadoEm;
  const DocNuvem(this.id, this.dados, this.sincronizadoEm);
}

abstract class NuvemDados {
  /// Grava (ou substitui) vários documentos de uma coleção.
  Future<void> enviaLote(
      String uid, String colecao, Map<String, Map<String, dynamic>> docs);

  /// Documentos cuja hora no servidor é maior que [depoisDe] (em ordem).
  Future<List<DocNuvem>> busca(String uid, String colecao, {int? depoisDe});

  /// Avisa (sem dados) toda vez que algo mudar na nuvem — tempo real.
  Stream<void> ouveMudancas(String uid);
}

class FirestoreNuvemDados implements NuvemDados {
  final FirebaseFirestore _fs;
  FirestoreNuvemDados([FirebaseFirestore? fs])
      : _fs = fs ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String uid, String colecao) =>
      _fs.collection('users').doc(uid).collection(colecao);

  @override
  Future<void> enviaLote(String uid, String colecao,
      Map<String, Map<String, dynamic>> docs) async {
    final entradas = docs.entries.toList();
    // o Firestore aceita no máximo 500 operações por lote
    for (var i = 0; i < entradas.length; i += 400) {
      final lote = _fs.batch();
      for (final e in entradas.skip(i).take(400)) {
        lote.set(_col(uid, colecao).doc(e.key), {
          ...e.value,
          'syncedAt': FieldValue.serverTimestamp(),
        });
      }
      await lote.commit();
    }
  }

  @override
  Future<List<DocNuvem>> busca(String uid, String colecao,
      {int? depoisDe}) async {
    Query<Map<String, dynamic>> q = _col(uid, colecao).orderBy('syncedAt');
    if (depoisDe != null) {
      q = q.where('syncedAt',
          isGreaterThan: Timestamp.fromMicrosecondsSinceEpoch(depoisDe));
    }
    final r = await q.get();
    final saida = <DocNuvem>[];
    for (final d in r.docs) {
      final t = d.data()['syncedAt'];
      if (t is! Timestamp) continue;
      final dados = Map<String, dynamic>.from(d.data())..remove('syncedAt');
      saida.add(DocNuvem(d.id, dados, t.microsecondsSinceEpoch));
    }
    return saida;
  }

  @override
  Stream<void> ouveMudancas(String uid) {
    late StreamController<void> c;
    final subs = <StreamSubscription>[];
    c = StreamController<void>(
      onListen: () {
        for (final col in ['decks', 'cards', 'reviews']) {
          subs.add(_col(uid, col)
              .snapshots(includeMetadataChanges: false)
              .listen((snap) {
            // ignora o eco das nossas próprias gravações
            if (!snap.metadata.hasPendingWrites && !c.isClosed) c.add(null);
          }, onError: (_) {}));
        }
      },
      onCancel: () async {
        for (final s in subs) {
          await s.cancel();
        }
      },
    );
    return c.stream;
  }
}

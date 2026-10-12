// =============================================================================
// sql_helper.dart — Banco de dados local (SQLite) do StudyCards
// -----------------------------------------------------------------------------
// Segue o mesmo padrão das aulas LDDM09 e LDDM10 (Prof. Ilo):
//   - caminho do banco com getDatabasesPath() + join()
//   - openDatabase(version, onCreate) criando as tabelas
//   - classe com métodos static: criaTabelas, db, adiciona..., pega...,
//     atualiza..., apaga...
//   - insert/update recebem um Map; consultas usam where "id = ?" + whereArgs
//
// Os NOMES DAS COLUNAS são os mesmos usados nos models que já estão no
// repositório (models/deck_model.dart, flashcard_model, user_model.dart,
// progress_model). Assim, cada Map retornado aqui pode ir direto para o
// fromMap() do model correspondente.
//
// Lembrete do SQLite: só existem TEXT, INTEGER e REAL.
//   - bool  -> INTEGER (0 = falso, 1 = verdadeiro)
//   - data  -> TEXT no formato ISO 8601 (DateTime.toIso8601String())
// =============================================================================

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart' as sql;

import 'repeticao_espacada.dart';

class SQLHelper {
  static const String _nomeBanco = 'studycards.db';
  static const int _versaoBanco = 1;

  // Guarda a conexão aberta para não abrir o banco a cada operação.
  static sql.Database? _banco;

  // ---------------------------------------------------------------------------
  // CRIAÇÃO DAS TABELAS
  // ---------------------------------------------------------------------------
  static Future<void> criaTabelas(sql.Database database) async {
    // Usuário do app (login local / Google)
    await database.execute("""CREATE TABLE users(
      id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
      name TEXT NOT NULL,
      email TEXT NOT NULL UNIQUE,
      occupation TEXT DEFAULT 'Estudante',
      google_id TEXT,
      photo_url TEXT,
      is_profile_visible INTEGER NOT NULL DEFAULT 1,
      notify_study_reminder INTEGER NOT NULL DEFAULT 1,
      createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
    )""");

    // Baralhos (decks)
    await database.execute("""CREATE TABLE decks(
      id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
      user_id INTEGER,
      title TEXT NOT NULL,
      description TEXT,
      createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    )""");

    // Flashcards — inclui os campos do algoritmo de repetição espaçada (SM-2)
    await database.execute("""CREATE TABLE flashcards(
      id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
      deck_id INTEGER NOT NULL,
      question TEXT NOT NULL,
      answer TEXT NOT NULL,
      is_mastered INTEGER NOT NULL DEFAULT 0,
      ease_factor REAL NOT NULL DEFAULT 2.5,
      interval_days INTEGER NOT NULL DEFAULT 0,
      repetitions INTEGER NOT NULL DEFAULT 0,
      next_review TEXT NOT NULL,
      last_review TEXT,
      createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (deck_id) REFERENCES decks(id) ON DELETE CASCADE
    )""");

    // Histórico de revisões — usado nas estatísticas (tela de progresso)
    await database.execute("""CREATE TABLE revisoes(
      id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
      flashcard_id INTEGER NOT NULL,
      quality INTEGER NOT NULL,
      reviewed_at TEXT NOT NULL,
      FOREIGN KEY (flashcard_id) REFERENCES flashcards(id) ON DELETE CASCADE
    )""");

    // Índices para deixar as buscas mais rápidas
    await database.execute(
        "CREATE INDEX idx_flashcards_deck ON flashcards(deck_id)");
    await database.execute(
        "CREATE INDEX idx_flashcards_next_review ON flashcards(next_review)");
  }

  // ---------------------------------------------------------------------------
  // ABRIR / RECUPERAR O BANCO
  // ---------------------------------------------------------------------------
  static Future<sql.Database> db() async {
    if (_banco != null) return _banco!;

    final caminhoBanco = await sql.getDatabasesPath();
    final localBanco = join(caminhoBanco, _nomeBanco);

    _banco = await sql.openDatabase(
      localBanco,
      version: _versaoBanco,
      // Liga as chaves estrangeiras (no SQLite vêm desligadas por padrão).
      // Com isso, apagar um deck apaga também os cards dele (ON DELETE CASCADE).
      onConfigure: (sql.Database database) async {
        await database.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (sql.Database database, int version) async {
        await criaTabelas(database);
      },
    );
    return _banco!;
  }

  /// Fecha o banco (útil em testes).
  static Future<void> fechaBanco() async {
    await _banco?.close();
    _banco = null;
  }

  /// Apaga o arquivo do banco inteiro (útil para recomeçar os testes do zero).
  static Future<void> apagaBancoInteiro() async {
    await fechaBanco();
    final caminhoBanco = await sql.getDatabasesPath();
    await sql.deleteDatabase(join(caminhoBanco, _nomeBanco));
  }

  static String _agora() => DateTime.now().toIso8601String();

  // ===========================================================================
  // USUÁRIOS
  // ===========================================================================
  static Future<int> adicionaUsuario(String nome, String email,
      {String ocupacao = 'Estudante', String? googleId, String? fotoUrl}) async {
    final db = await SQLHelper.db();
    final dados = {
      'name': nome,
      'email': email,
      'occupation': ocupacao,
      'google_id': googleId,
      'photo_url': fotoUrl,
    };
    return db.insert('users', dados,
        conflictAlgorithm: sql.ConflictAlgorithm.replace);
  }

  static Future<List<Map<String, dynamic>>> pegaUmUsuario(int id) async {
    final db = await SQLHelper.db();
    return db.query('users', where: "id = ?", whereArgs: [id], limit: 1);
  }

  static Future<List<Map<String, dynamic>>> pegaUsuarioPorEmail(
      String email) async {
    final db = await SQLHelper.db();
    return db.query('users', where: "email = ?", whereArgs: [email], limit: 1);
  }

  /// Usado no login com Google: se o e-mail já existe devolve o id dele,
  /// senão cria o usuário e devolve o id novo.
  static Future<int> pegaOuCriaUsuario(String nome, String email,
      {String? googleId, String? fotoUrl}) async {
    final existente = await pegaUsuarioPorEmail(email);
    if (existente.isNotEmpty) return existente.first['id'] as int;
    return adicionaUsuario(nome, email, googleId: googleId, fotoUrl: fotoUrl);
  }

  static Future<int> atualizaUsuario(int id, String nome, String ocupacao,
      bool perfilVisivel, bool lembreteEstudo) async {
    final db = await SQLHelper.db();
    final dados = {
      'name': nome,
      'occupation': ocupacao,
      'is_profile_visible': perfilVisivel ? 1 : 0,
      'notify_study_reminder': lembreteEstudo ? 1 : 0,
    };
    return db.update('users', dados, where: "id = ?", whereArgs: [id]);
  }

  static Future<void> apagaUsuario(int id) async {
    final db = await SQLHelper.db();
    try {
      await db.delete('users', where: "id = ?", whereArgs: [id]);
    } catch (err) {
      debugPrint("Erro ao apagar o usuário: $err");
    }
  }

  // ===========================================================================
  // DECKS (BARALHOS)
  // ===========================================================================
  static Future<int> adicionaDeck(String titulo,
      {String? descricao, int? usuarioId}) async {
    final db = await SQLHelper.db();
    final dados = {
      'title': titulo,
      'description': descricao,
      'user_id': usuarioId,
    };
    return db.insert('decks', dados,
        conflictAlgorithm: sql.ConflictAlgorithm.replace);
  }

  /// Lista os decks já com a quantidade de cards (cards_count) e quantos
  /// estão pendentes para revisão hoje (pending_count).
  /// O formato bate com DeckModel.fromMap().
  static Future<List<Map<String, dynamic>>> pegaDecks({int? usuarioId}) async {
    final db = await SQLHelper.db();
    final filtro = usuarioId == null ? '' : 'WHERE d.user_id = ?';
    return db.rawQuery("""
      SELECT d.*,
             COUNT(f.id) AS cards_count,
             COALESCE(SUM(CASE WHEN f.next_review <= ? THEN 1 ELSE 0 END), 0)
               AS pending_count
      FROM decks d
      LEFT JOIN flashcards f ON f.deck_id = d.id
      $filtro
      GROUP BY d.id
      ORDER BY d.id
    """, [_agora(), if (usuarioId != null) usuarioId]);
  }

  static Future<List<Map<String, dynamic>>> pegaUmDeck(int id) async {
    final db = await SQLHelper.db();
    return db.query('decks', where: "id = ?", whereArgs: [id], limit: 1);
  }

  static Future<int> atualizaDeck(int id, String titulo,
      {String? descricao}) async {
    final db = await SQLHelper.db();
    final dados = {'title': titulo, 'description': descricao};
    return db.update('decks', dados, where: "id = ?", whereArgs: [id]);
  }

  /// Apaga o deck e, por causa do ON DELETE CASCADE, todos os cards dele.
  static Future<void> apagaDeck(int id) async {
    final db = await SQLHelper.db();
    try {
      await db.delete('decks', where: "id = ?", whereArgs: [id]);
    } catch (err) {
      debugPrint("Erro ao apagar o deck: $err");
    }
  }

  // ===========================================================================
  // FLASHCARDS
  // ===========================================================================
  static Future<int> adicionaFlashcard(
      int deckId, String pergunta, String resposta) async {
    final db = await SQLHelper.db();
    final dados = {
      'deck_id': deckId,
      'question': pergunta,
      'answer': resposta,
      'next_review': _agora(), // card novo já fica disponível para estudo
    };
    return db.insert('flashcards', dados,
        conflictAlgorithm: sql.ConflictAlgorithm.replace);
  }

  /// Salva vários cards de uma vez (ex.: cards gerados pela IA a partir do OCR).
  /// Cada item da lista deve ter as chaves 'question' e 'answer'.
  static Future<void> adicionaFlashcardsEmLote(
      int deckId, List<Map<String, String>> cards) async {
    final db = await SQLHelper.db();
    final agora = _agora();
    await db.transaction((txn) async {
      final lote = txn.batch();
      for (final card in cards) {
        lote.insert('flashcards', {
          'deck_id': deckId,
          'question': card['question'] ?? '',
          'answer': card['answer'] ?? '',
          'next_review': agora,
        });
      }
      await lote.commit(noResult: true);
    });
  }

  static Future<List<Map<String, dynamic>>> pegaFlashcardsDoDeck(
      int deckId) async {
    final db = await SQLHelper.db();
    return db.query('flashcards',
        where: "deck_id = ?", whereArgs: [deckId], orderBy: "id");
  }

  static Future<List<Map<String, dynamic>>> pegaUmFlashcard(int id) async {
    final db = await SQLHelper.db();
    return db.query('flashcards', where: "id = ?", whereArgs: [id], limit: 1);
  }

  /// Cards que precisam ser revisados agora (next_review já passou).
  /// Se deckId for nulo, busca de todos os decks.
  static Future<List<Map<String, dynamic>>> pegaFlashcardsPendentes(
      {int? deckId}) async {
    final db = await SQLHelper.db();
    if (deckId == null) {
      return db.query('flashcards',
          where: "next_review <= ?",
          whereArgs: [_agora()],
          orderBy: "next_review");
    }
    return db.query('flashcards',
        where: "deck_id = ? AND next_review <= ?",
        whereArgs: [deckId, _agora()],
        orderBy: "next_review");
  }

  static Future<int> atualizaFlashcard(
      int id, String pergunta, String resposta) async {
    final db = await SQLHelper.db();
    final dados = {'question': pergunta, 'answer': resposta};
    return db.update('flashcards', dados, where: "id = ?", whereArgs: [id]);
  }

  static Future<void> apagaFlashcard(int id) async {
    final db = await SQLHelper.db();
    try {
      await db.delete('flashcards', where: "id = ?", whereArgs: [id]);
    } catch (err) {
      debugPrint("Erro ao apagar o flashcard: $err");
    }
  }

  // ===========================================================================
  // REVISÃO (REPETIÇÃO ESPAÇADA)
  // ===========================================================================
  /// Registra a resposta do usuário para um card e calcula a próxima revisão.
  /// [avaliacao] vem dos botões da tela: Errei / Difícil / Fácil / Muito fácil.
  /// Retorna o novo intervalo em dias.
  static Future<int> registraRevisao(int flashcardId, Avaliacao avaliacao) async {
    final db = await SQLHelper.db();
    final resultado = await pegaUmFlashcard(flashcardId);
    if (resultado.isEmpty) return 0;
    final card = resultado.first;

    final novo = RepeticaoEspacada.calcula(
      avaliacao: avaliacao,
      fatorFacilidade: (card['ease_factor'] as num).toDouble(),
      intervaloDias: card['interval_days'] as int,
      repeticoes: card['repetitions'] as int,
    );

    final agora = DateTime.now();
    await db.transaction((txn) async {
      await txn.update(
        'flashcards',
        {
          'ease_factor': novo.fatorFacilidade,
          'interval_days': novo.intervaloDias,
          'repetitions': novo.repeticoes,
          'next_review': novo.proximaRevisao(agora).toIso8601String(),
          'last_review': agora.toIso8601String(),
          'is_mastered': novo.dominado ? 1 : 0,
        },
        where: "id = ?",
        whereArgs: [flashcardId],
      );
      await txn.insert('revisoes', {
        'flashcard_id': flashcardId,
        'quality': avaliacao.qualidade,
        'reviewed_at': agora.toIso8601String(),
      });
    });
    return novo.intervaloDias;
  }

  // ===========================================================================
  // ESTATÍSTICAS (tela de progresso)
  // ===========================================================================
  /// Retorna um Map no formato do ProgressModel.fromMap():
  /// total_cards_reviewed, mastered_cards, pending_cards, mastery_percentage.
  static Future<Map<String, dynamic>> pegaEstatisticas({int? usuarioId}) async {
    final db = await SQLHelper.db();
    final filtroDeck = usuarioId == null
        ? ''
        : 'WHERE f.deck_id IN (SELECT id FROM decks WHERE user_id = ?)';
    final args = [if (usuarioId != null) usuarioId];

    final cards = await db.rawQuery("""
      SELECT COUNT(*) AS total,
             COALESCE(SUM(f.is_mastered), 0) AS dominados,
             COALESCE(SUM(CASE WHEN f.next_review <= ? THEN 1 ELSE 0 END), 0)
               AS pendentes
      FROM flashcards f
      $filtroDeck
    """, [_agora(), ...args]);

    final revisoes = await db.rawQuery("""
      SELECT COUNT(*) AS total
      FROM revisoes r
      JOIN flashcards f ON f.id = r.flashcard_id
      $filtroDeck
    """, args);

    final total = cards.first['total'] as int;
    final dominados = cards.first['dominados'] as int;
    return {
      'user_id': usuarioId ?? 0,
      'total_cards': total,
      'total_cards_reviewed': revisoes.first['total'] as int,
      'mastered_cards': dominados,
      'pending_cards': cards.first['pendentes'] as int,
      'mastery_percentage': total == 0 ? 0.0 : dominados * 100.0 / total,
    };
  }
}

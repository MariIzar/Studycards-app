import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart' as sql;

import 'repeticao_espacada.dart';

class SQLHelper {
  static const String _nomeBanco = 'studycards.db';
  static const int _versaoBanco = 2;

  static sql.Database? _banco;

  static Future<void> criaTabelas(sql.Database database) async {
    await database.execute("""
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        occupation TEXT DEFAULT 'Estudante',
        google_id TEXT,
        photo_url TEXT,
        is_profile_visible INTEGER NOT NULL DEFAULT 1,
        notify_study_reminder INTEGER NOT NULL DEFAULT 1,
        createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
    """);

    await database.execute("""
      CREATE TABLE decks(
        id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        user_id INTEGER,
        title TEXT NOT NULL,
        description TEXT,
        color INTEGER NOT NULL DEFAULT 4285287935,
        createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    """);

    await database.execute("""
      CREATE TABLE flashcards(
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
      )
    """);

    await database.execute("""
      CREATE TABLE revisoes(
        id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        flashcard_id INTEGER NOT NULL,
        quality INTEGER NOT NULL,
        reviewed_at TEXT NOT NULL,
        FOREIGN KEY (flashcard_id) REFERENCES flashcards(id)
          ON DELETE CASCADE
      )
    """);

    await database.execute(
      'CREATE INDEX idx_flashcards_deck ON flashcards(deck_id)',
    );

    await database.execute(
      'CREATE INDEX idx_flashcards_next_review '
      'ON flashcards(next_review)',
    );
  }

  static Future<sql.Database> db() async {
    if (_banco != null) {
      return _banco!;
    }

    final caminhoBanco = await sql.getDatabasesPath();
    final localBanco = join(caminhoBanco, _nomeBanco);

    _banco = await sql.openDatabase(
      localBanco,
      version: _versaoBanco,
      onConfigure: (database) async {
        await database.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (database, version) async {
        await criaTabelas(database);
      },
      onUpgrade: (database, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await database.execute(
            'ALTER TABLE decks ADD COLUMN color '
            'INTEGER NOT NULL DEFAULT 4285287935',
          );
        }
      },
    );

    return _banco!;
  }

  static Future<void> fechaBanco() async {
    await _banco?.close();
    _banco = null;
  }

  static Future<void> apagaBancoInteiro() async {
    await fechaBanco();

    final caminhoBanco = await sql.getDatabasesPath();

    await sql.deleteDatabase(join(caminhoBanco, _nomeBanco));
  }

  static String _agora() {
    return DateTime.now().toIso8601String();
  }

  // USUÁRIOS

  static Future<int> adicionaUsuario(
    String nome,
    String email, {
    String ocupacao = 'Estudante',
    String? googleId,
    String? fotoUrl,
  }) async {
    final database = await db();

    return database.insert('users', {
      'name': nome,
      'email': email,
      'occupation': ocupacao,
      'google_id': googleId,
      'photo_url': fotoUrl,
    }, conflictAlgorithm: sql.ConflictAlgorithm.replace);
  }

  static Future<List<Map<String, dynamic>>> pegaUmUsuario(int id) async {
    final database = await db();

    return database.query('users', where: 'id = ?', whereArgs: [id], limit: 1);
  }

  static Future<List<Map<String, dynamic>>> pegaUsuarioPorEmail(
    String email,
  ) async {
    final database = await db();

    return database.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
      limit: 1,
    );
  }

  static Future<int> pegaOuCriaUsuario(
    String nome,
    String email, {
    String? googleId,
    String? fotoUrl,
  }) async {
    final existente = await pegaUsuarioPorEmail(email);

    if (existente.isNotEmpty) {
      return (existente.first['id'] as num).toInt();
    }

    return adicionaUsuario(nome, email, googleId: googleId, fotoUrl: fotoUrl);
  }

  static Future<int> atualizaUsuario(
    int id,
    String nome,
    String ocupacao,
    bool perfilVisivel,
    bool lembreteEstudo,
  ) async {
    final database = await db();

    return database.update(
      'users',
      {
        'name': nome,
        'occupation': ocupacao,
        'is_profile_visible': perfilVisivel ? 1 : 0,
        'notify_study_reminder': lembreteEstudo ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> apagaUsuario(int id) async {
    final database = await db();

    try {
      await database.delete('users', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      debugPrint('Erro ao apagar usuário: $e');
    }
  }

  // DECKS

  static Future<int> adicionaDeck(
    String titulo, {
    String? descricao,
    int? usuarioId,
    int cor = 0xFF6C4DFF,
  }) async {
    final database = await db();

    return database.insert('decks', {
      'title': titulo,
      'description': descricao,
      'user_id': usuarioId,
      'color': cor,
    }, conflictAlgorithm: sql.ConflictAlgorithm.replace);
  }

  static Future<List<Map<String, dynamic>>> pegaDecks({int? usuarioId}) async {
    final database = await db();

    final filtro = usuarioId == null ? '' : 'WHERE d.user_id = ?';

    return database.rawQuery(
      """
      SELECT d.*,
             COUNT(f.id) AS cards_count,
             COALESCE(
               SUM(
                 CASE
                   WHEN f.next_review <= ? THEN 1
                   ELSE 0
                 END
               ),
               0
             ) AS pending_count
      FROM decks d
      LEFT JOIN flashcards f ON f.deck_id = d.id
      $filtro
      GROUP BY d.id
      ORDER BY d.id
    """,
      [_agora(), if (usuarioId != null) usuarioId],
    );
  }

  static Future<List<Map<String, dynamic>>> pegaUmDeck(int id) async {
    final database = await db();

    return database.query('decks', where: 'id = ?', whereArgs: [id], limit: 1);
  }

  static Future<int> atualizaDeck(
    int id,
    String titulo, {
    String? descricao,
    int? cor,
  }) async {
    final database = await db();

    final Map<String, dynamic> dados = {
      'title': titulo,
      'description': descricao,
    };

    if (cor != null) {
      dados['color'] = cor;
    }

    return database.update('decks', dados, where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> apagaDeck(int id) async {
    final database = await db();

    try {
      await database.delete('decks', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      debugPrint('Erro ao apagar deck: $e');
    }
  }

  // FLASHCARDS

  static Future<int> adicionaFlashcard(
    int deckId,
    String pergunta,
    String resposta,
  ) async {
    final database = await db();

    return database.insert('flashcards', {
      'deck_id': deckId,
      'question': pergunta,
      'answer': resposta,
      'next_review': _agora(),
    }, conflictAlgorithm: sql.ConflictAlgorithm.replace);
  }

  static Future<void> adicionaFlashcardsEmLote(
    int deckId,
    List<Map<String, String>> cards,
  ) async {
    final database = await db();
    final agora = _agora();

    await database.transaction((txn) async {
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
    int deckId,
  ) async {
    final database = await db();

    return database.query(
      'flashcards',
      where: 'deck_id = ?',
      whereArgs: [deckId],
      orderBy: 'id',
    );
  }

  static Future<List<Map<String, dynamic>>> pegaUmFlashcard(int id) async {
    final database = await db();

    return database.query(
      'flashcards',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
  }

  static Future<List<Map<String, dynamic>>> pegaFlashcardsPendentes({
    int? deckId,
  }) async {
    final database = await db();

    if (deckId == null) {
      return database.query(
        'flashcards',
        where: 'next_review <= ?',
        whereArgs: [_agora()],
        orderBy: 'next_review',
      );
    }

    return database.query(
      'flashcards',
      where: 'deck_id = ? AND next_review <= ?',
      whereArgs: [deckId, _agora()],
      orderBy: 'next_review',
    );
  }

  static Future<int> atualizaFlashcard(
    int id,
    String pergunta,
    String resposta,
  ) async {
    final database = await db();

    return database.update(
      'flashcards',
      {'question': pergunta, 'answer': resposta},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> apagaFlashcard(int id) async {
    final database = await db();

    try {
      await database.delete('flashcards', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      debugPrint('Erro ao apagar flashcard: $e');
    }
  }

  // REPETIÇÃO ESPAÇADA

  static Future<int> registraRevisao(
    int flashcardId,
    Avaliacao avaliacao,
  ) async {
    final database = await db();

    final resultado = await pegaUmFlashcard(flashcardId);

    if (resultado.isEmpty) {
      return 0;
    }

    final card = resultado.first;

    final novo = RepeticaoEspacada.calcula(
      avaliacao: avaliacao,
      fatorFacilidade: (card['ease_factor'] as num).toDouble(),
      intervaloDias: (card['interval_days'] as num).toInt(),
      repeticoes: (card['repetitions'] as num).toInt(),
    );

    final agora = DateTime.now();

    await database.transaction((txn) async {
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
        where: 'id = ?',
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

  // ESTATÍSTICAS

  static Future<Map<String, dynamic>> pegaEstatisticas({int? usuarioId}) async {
    final database = await db();

    final filtroDeck = usuarioId == null
        ? ''
        : 'WHERE f.deck_id IN '
              '(SELECT id FROM decks WHERE user_id = ?)';

    final args = [if (usuarioId != null) usuarioId];

    final cards = await database.rawQuery(
      """
      SELECT COUNT(*) AS total,
             COALESCE(SUM(f.is_mastered), 0) AS dominados,
             COALESCE(
               SUM(
                 CASE
                   WHEN f.next_review <= ? THEN 1
                   ELSE 0
                 END
               ),
               0
             ) AS pendentes
      FROM flashcards f
      $filtroDeck
    """,
      [_agora(), ...args],
    );

    final revisoes = await database.rawQuery("""
      SELECT COUNT(*) AS total
      FROM revisoes r
      JOIN flashcards f ON f.id = r.flashcard_id
      $filtroDeck
    """, args);

    final total = (cards.first['total'] as num).toInt();
    final dominados = (cards.first['dominados'] as num).toInt();

    return {
      'user_id': usuarioId ?? 0,
      'total_cards': total,
      'total_cards_reviewed': (revisoes.first['total'] as num).toInt(),
      'mastered_cards': dominados,
      'pending_cards': (cards.first['pendentes'] as num).toInt(),
      'mastery_percentage': total == 0 ? 0.0 : dominados * 100.0 / total,
    };
  }
}

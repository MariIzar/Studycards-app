import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart' as sql;

/// Banco separado para metadados dos materiais usados na geração de flashcards.
/// O banco principal `studycards.db` permanece independente e inalterado.
class AIStorageHelper {
  static const String _nomeBanco = 'studycards_ai.db';
  static const int _versaoBanco = 1;
  static sql.Database? _banco;

  static Future<sql.Database> db() async {
    if (_banco != null) return _banco!;
    final caminho = await sql.getDatabasesPath();
    _banco = await sql.openDatabase(
      join(caminho, _nomeBanco),
      version: _versaoBanco,
      onCreate: (database, version) async {
        await database.execute('''
          CREATE TABLE materials(
            id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
            user_id INTEGER,
            title TEXT NOT NULL,
            source_name TEXT,
            file_path TEXT,
            source_type TEXT NOT NULL DEFAULT 'text',
            summary TEXT,
            created_at TEXT NOT NULL
          )
        ''');
      },
    );
    return _banco!;
  }

  static String _agora() => DateTime.now().toIso8601String();

  static Future<void> fechaBanco() async {
    await _banco?.close();
    _banco = null;
  }

  static Future<int> salvaMaterial({
    required String titulo,
    String? nomeArquivo,
    String? caminhoArquivo,
    String tipo = 'text',
    String? resumo,
    int? usuarioId,
  }) async {
    final database = await db();
    return database.insert('materials', {
      'user_id': usuarioId,
      'title': titulo,
      'source_name': nomeArquivo,
      'file_path': caminhoArquivo,
      'source_type': tipo,
      'summary': resumo,
      'created_at': _agora(),
    });
  }
}

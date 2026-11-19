// Testes da sincronização com a nuvem: dois "aparelhos" (bancos limpos) falando
// com a mesma nuvem falsa. SQLite real via sqflite_common_ffi.
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:study_cards/banco_de_dados/auth_helper.dart';
import 'package:study_cards/banco_de_dados/repeticao_espacada.dart';
import 'package:study_cards/banco_de_dados/sql_helper.dart';
import 'package:study_cards/services/sync_service.dart';

import 'fake_nuvem.dart';
import 'fake_nuvem_dados.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeNuvemAuth auth;
  late FakeNuvemDados dados;

  setUp(() async {
    auth = FakeNuvemAuth();
    dados = FakeNuvemDados();
    AuthHelper.nuvem = auth;
    SharedPreferences.setMockInitialValues({});
    SyncService.nuvem = null;
    SyncService.atraso = const Duration(hours: 1);
    await AuthHelper.sair();
    await SQLHelper.apagaBancoInteiro();
  });

  tearDown(() async {
    await SyncService.parar();
    SyncService.nuvem = null;
  });

  Future<String> uidLogado() async =>
      (await SQLHelper.pegaUmUsuario(Sessao.usuarioId!)).first['firebase_uid']
          as String;

  /// Aparelho A: cria conta e liga a nuvem de dados.
  Future<String> aparelhoA() async {
    final r = await AuthHelper.cadastrar(
        nome: 'Ana',
        email: 'a@a.com',
        senha: 'Senha123',
        confirmacao: 'Senha123');
    expect(r.ok, true);
    SyncService.nuvem = dados;
    return uidLogado();
  }

  /// Aparelho B: banco vazio, entra com a mesma conta.
  Future<void> aparelhoB() async {
    await SyncService.parar();
    await AuthHelper.sair();
    await SQLHelper.apagaBancoInteiro();
    final r = await AuthHelper.entrar('a@a.com', 'Senha123');
    expect(r.ok, true);
    SyncService.nuvem = dados;
  }

  Future<List<Map<String, dynamic>>> cardsDoPrimeiroDeck() async {
    final decks = await SQLHelper.pegaDecks(usuarioId: Sessao.usuarioId);
    return SQLHelper.pegaFlashcardsDoDeck(decks.first['id'] as int);
  }

  test('envia deck, cards e revisão para a nuvem', () async {
    final uid = await aparelhoA();
    final deck = await SQLHelper.adicionaDeck('Biologia',
        descricao: 'Células', usuarioId: Sessao.usuarioId);
    await SQLHelper.adicionaFlashcard(deck, 'P1', 'R1');
    await SQLHelper.adicionaFlashcardsEmLote(deck, [
      {'question': 'P2', 'answer': 'R2'},
    ]);
    final cards = await SQLHelper.pegaFlashcardsDoDeck(deck);
    await SQLHelper.registraRevisao(cards.first['id'] as int, Avaliacao.facil);

    expect(await SyncService.sincronizar(), true);
    expect(dados.ids(uid, 'decks').length, 1);
    expect(dados.ids(uid, 'cards').length, 2);
    expect(dados.ids(uid, 'reviews').length, 1);

    // nada fica pendente
    final db = await SQLHelper.db();
    expect(await db.query('decks', where: 'sync_pendente = 1'), isEmpty);
    expect(await db.query('flashcards', where: 'sync_pendente = 1'), isEmpty);
    expect(await db.query('revisoes', where: 'sync_pendente = 1'), isEmpty);
  });

  test('outro aparelho baixa tudo, inclusive o progresso', () async {
    await aparelhoA();
    final deck = await SQLHelper.adicionaDeck('Biologia',
        usuarioId: Sessao.usuarioId, cor: 0xFF123456);
    await SQLHelper.adicionaFlashcard(deck, 'P1', 'R1');
    final c = (await SQLHelper.pegaFlashcardsDoDeck(deck)).first;
    await SQLHelper.registraRevisao(c['id'] as int, Avaliacao.facil);
    await SyncService.sincronizar();

    await aparelhoB();
    expect(await SyncService.sincronizar(), true);

    final decks = await SQLHelper.pegaDecks(usuarioId: Sessao.usuarioId);
    expect(decks.length, 1);
    expect(decks.first['title'], 'Biologia');
    expect(decks.first['color'], 0xFF123456);
    final cards = await cardsDoPrimeiroDeck();
    expect(cards.length, 1);
    expect(cards.first['repetitions'], greaterThan(0)); // progresso veio junto
    final db = await SQLHelper.db();
    expect((await db.query('revisoes')).length, 1);

    // sincronizar de novo não duplica nada
    await SyncService.sincronizar();
    expect((await SQLHelper.pegaDecks(usuarioId: Sessao.usuarioId)).length, 1);
    expect((await cardsDoPrimeiroDeck()).length, 1);
    expect((await db.query('revisoes')).length, 1);
  });

  test('edição mais nova na nuvem vence a local', () async {
    final uid = await aparelhoA();
    final deck = await SQLHelper.adicionaDeck('Antigo',
        usuarioId: Sessao.usuarioId);
    await SyncService.sincronizar();

    final id = dados.ids(uid, 'decks').first;
    dados.edita(uid, 'decks', id, {
      'title': 'Novo da nuvem',
      'updatedAt': DateTime.now().toUtc().add(const Duration(minutes: 5))
          .toIso8601String(),
    });
    await SyncService.sincronizar();
    expect((await SQLHelper.pegaUmDeck(deck)).first['title'], 'Novo da nuvem');
  });

  test('edição local mais nova vence a da nuvem', () async {
    final uid = await aparelhoA();
    final deck = await SQLHelper.adicionaDeck('Original',
        usuarioId: Sessao.usuarioId);
    await SyncService.sincronizar();
    final id = dados.ids(uid, 'decks').first;

    dados.edita(uid, 'decks', id, {
      'title': 'Velho da nuvem',
      'updatedAt': DateTime.now().toUtc().subtract(const Duration(hours: 1))
          .toIso8601String(),
    });
    await SQLHelper.atualizaDeck(deck, 'Editado aqui');
    await SyncService.sincronizar();

    expect((await SQLHelper.pegaUmDeck(deck)).first['title'], 'Editado aqui');
    expect(dados.doc(uid, 'decks', id)['title'], 'Editado aqui');
  });

  test('apagar deck e card se propaga para o outro aparelho', () async {
    final uid = await aparelhoA();
    final d1 = await SQLHelper.adicionaDeck('Fica', usuarioId: Sessao.usuarioId);
    final d2 = await SQLHelper.adicionaDeck('Sai', usuarioId: Sessao.usuarioId);
    await SQLHelper.adicionaFlashcard(d1, 'P', 'R');
    await SQLHelper.adicionaFlashcard(d1, 'P2', 'R2');
    await SQLHelper.adicionaFlashcard(d2, 'X', 'Y');
    await SyncService.sincronizar();
    await aparelhoB();
    await SyncService.sincronizar();
    expect((await SQLHelper.pegaDecks(usuarioId: Sessao.usuarioId)).length, 2);

    // volta ao A (mesmo banco do B serve como "A" depois de editar aqui)
    final decksB = await SQLHelper.pegaDecks(usuarioId: Sessao.usuarioId);
    final sai = decksB.firstWhere((d) => d['title'] == 'Sai');
    final fica = decksB.firstWhere((d) => d['title'] == 'Fica');
    await SQLHelper.apagaDeck(sai['id'] as int);
    final cardsFica = await SQLHelper.pegaFlashcardsDoDeck(fica['id'] as int);
    await SQLHelper.apagaFlashcard(cardsFica.first['id'] as int);
    expect(await SyncService.sincronizar(), true);

    final marcados = dados.ids(uid, 'decks')
        .where((i) => dados.doc(uid, 'decks', i)['deleted'] == true);
    expect(marcados.length, 1);

    // aparelho A novamente (banco limpo, baixa o estado final)
    await aparelhoB();
    await SyncService.sincronizar();
    final decks = await SQLHelper.pegaDecks(usuarioId: Sessao.usuarioId);
    expect(decks.map((d) => d['title']), ['Fica']);
    expect((await cardsDoPrimeiroDeck()).length, 1);
    expect(d1, isNonZero);
  });

  test('item apagado no aparelho não ressuscita ao baixar', () async {
    final uid = await aparelhoA();
    final d = await SQLHelper.adicionaDeck('X', usuarioId: Sessao.usuarioId);
    await SyncService.sincronizar();
    await SQLHelper.apagaDeck(d);
    // baixar antes de enviar não pode recriar o deck
    expect(await SyncService.sincronizar(), true);
    expect(await SQLHelper.pegaDecks(usuarioId: Sessao.usuarioId), isEmpty);
    final id = dados.ids(uid, 'decks').first;
    expect(dados.doc(uid, 'decks', id)['deleted'], true);
  });

  test('sem internet: nada se perde e envia quando voltar', () async {
    final uid = await aparelhoA();
    dados.semInternet = true;
    final d = await SQLHelper.adicionaDeck('Offline',
        usuarioId: Sessao.usuarioId);
    await SQLHelper.adicionaFlashcard(d, 'P', 'R');
    expect(await SyncService.sincronizar(), false);
    expect(SyncService.ultimoErro, isNotNull);
    expect(dados.ids(uid, 'decks'), isEmpty);
    expect((await SQLHelper.pegaDecks(usuarioId: Sessao.usuarioId)).length, 1);

    dados.semInternet = false;
    expect(await SyncService.sincronizar(), true);
    expect(SyncService.ultimoErro, isNull);
    expect(dados.ids(uid, 'decks').length, 1);
    expect(dados.ids(uid, 'cards').length, 1);
  });

  test('mudança em outro aparelho avisa as telas (mudancasRecebidas)', () async {
    final uid = await aparelhoA();
    await SQLHelper.adicionaDeck('A', usuarioId: Sessao.usuarioId);
    await SyncService.sincronizar();
    final antes = SyncService.mudancasRecebidas.value;
    dados.edita(uid, 'decks', dados.ids(uid, 'decks').first, {
      'title': 'B',
      'updatedAt': DateTime.now().toUtc().add(const Duration(minutes: 1))
          .toIso8601String(),
    });
    await SyncService.sincronizar();
    expect(SyncService.mudancasRecebidas.value, antes + 1);
  });

  test('sem nuvem configurada, sincronizar não faz nada', () async {
    await AuthHelper.cadastrar(
        nome: 'Ana',
        email: 'a@a.com',
        senha: 'Senha123',
        confirmacao: 'Senha123');
    SyncService.nuvem = null;
    expect(await SyncService.sincronizar(), false);
  });

  test('banco antigo (v4) é migrado: dados ganham id único e vão pendentes',
      () async {
    await SQLHelper.fechaBanco();
    final caminho = p.join(await getDatabasesPath(), 'studycards.db');
    await deleteDatabase(caminho);
    final velho = await openDatabase(caminho, version: 4,
        onCreate: (d, v) async {
      await d.execute('CREATE TABLE users(id INTEGER PRIMARY KEY AUTOINCREMENT, '
          'name TEXT NOT NULL, email TEXT NOT NULL UNIQUE, occupation TEXT, '
          'google_id TEXT, photo_url TEXT, is_profile_visible INTEGER DEFAULT 1, '
          'notify_study_reminder INTEGER DEFAULT 1, password_hash TEXT, '
          'password_salt TEXT, firebase_uid TEXT, createdAt TIMESTAMP '
          'DEFAULT CURRENT_TIMESTAMP)');
      await d.execute('CREATE TABLE decks(id INTEGER PRIMARY KEY AUTOINCREMENT, '
          'user_id INTEGER, title TEXT NOT NULL, description TEXT, '
          'color INTEGER NOT NULL DEFAULT 4285287935, createdAt TIMESTAMP '
          'DEFAULT CURRENT_TIMESTAMP)');
      await d.execute('CREATE TABLE flashcards(id INTEGER PRIMARY KEY '
          'AUTOINCREMENT, deck_id INTEGER NOT NULL, question TEXT NOT NULL, '
          'answer TEXT NOT NULL, is_mastered INTEGER NOT NULL DEFAULT 0, '
          'ease_factor REAL NOT NULL DEFAULT 2.5, interval_days INTEGER NOT '
          'NULL DEFAULT 0, repetitions INTEGER NOT NULL DEFAULT 0, next_review '
          'TEXT NOT NULL, last_review TEXT, createdAt TIMESTAMP DEFAULT '
          'CURRENT_TIMESTAMP)');
      await d.execute('CREATE TABLE revisoes(id INTEGER PRIMARY KEY '
          'AUTOINCREMENT, flashcard_id INTEGER NOT NULL, quality INTEGER NOT '
          'NULL, reviewed_at TEXT NOT NULL)');
      await d.insert('decks', {'title': 'Antigo'});
      await d.insert('decks', {'title': 'Antigo 2'});
      await d.insert('flashcards',
          {'deck_id': 1, 'question': 'q', 'answer': 'a', 'next_review': 'x'});
      await d.insert('revisoes',
          {'flashcard_id': 1, 'quality': 4, 'reviewed_at': 'x'});
    });
    await velho.close();

    final db = await SQLHelper.db();
    final decks = await db.query('decks');
    expect(decks.length, 2);
    expect(decks.every((d) => (d['uuid'] as String?)?.length == 36), true);
    expect(decks.map((d) => d['uuid']).toSet().length, 2);
    expect(decks.every((d) => d['sync_pendente'] == 1), true);
    expect((await db.query('flashcards')).first['uuid'], isNotNull);
    expect((await db.query('revisoes')).first['uuid'], isNotNull);
  });
}

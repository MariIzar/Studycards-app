// Testes do login local: cadastro, login, sessão, logout, senha e isolamento
// de decks entre contas. SQLite real via sqflite_common_ffi.
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:study_cards/banco_de_dados/auth_helper.dart';
import 'package:study_cards/banco_de_dados/preferencias_helper.dart';
import 'package:study_cards/banco_de_dados/repeticao_espacada.dart';
import 'package:study_cards/banco_de_dados/sql_helper.dart';

import 'fake_nuvem.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeNuvemAuth nuvem;

  setUp(() async {
    nuvem = FakeNuvemAuth();
    AuthHelper.nuvem = nuvem;
    SharedPreferences.setMockInitialValues({});
    await SQLHelper.apagaBancoInteiro();
    await AuthHelper.sair();
  });

  Future<AuthResultado> cria(String nome, String email,
          {String senha = 'Senha123'}) =>
      AuthHelper.cadastrar(
          nome: nome, email: email, senha: senha, confirmacao: senha);

  test('cadastro valida campos', () async {
    expect((await cria('', 'a@a.com')).ok, false);
    expect((await cria('Ana', 'invalido')).erro, 'E-mail inválido.');
    expect((await cria('Ana', 'a@a.com', senha: 'abc')).ok, false);
    expect((await cria('Ana', 'a@a.com', senha: 'semnumeroAA')).ok, false);
    final r = await AuthHelper.cadastrar(
        nome: 'Ana', email: 'a@a.com', senha: 'Senha123', confirmacao: 'Outra123');
    expect(r.erro, 'As senhas não conferem.');
  });

  test('cadastro, senha com hash+sal, sessão e logout', () async {
    expect((await cria('Ana Silva', 'Ana@Mail.com')).ok, true);
    expect(Sessao.logado, true);
    expect(Sessao.primeiroNome, 'Ana');
    expect(await PreferenciasHelper.recuperaUsuarioLogado(), Sessao.usuarioId);

    final u = (await SQLHelper.pegaUsuarioPorEmail('ana@mail.com')).first;
    expect(u['password_hash'], isNot('Senha123'));
    expect((u['password_salt'] as String).isNotEmpty, true);

    // e-mail duplicado (qualquer caixa)
    expect((await cria('Outra', 'ANA@mail.com')).erro,
        'Já existe uma conta com este e-mail.');

    // "reabrir o app": sessão volta do SharedPreferences
    Sessao.usuarioId = null;
    await Sessao.carrega();
    expect(Sessao.nome, 'Ana Silva');

    await AuthHelper.sair();
    expect(Sessao.logado, false);
    expect(await PreferenciasHelper.recuperaUsuarioLogado(), isNull);
  });

  test('login: erros e sucesso; mesmo senha gera hashes diferentes (sal)', () async {
    await cria('Ana', 'ana@mail.com');
    await cria('Bia', 'bia@mail.com');
    final a = (await SQLHelper.pegaUsuarioPorEmail('ana@mail.com')).first;
    final b = (await SQLHelper.pegaUsuarioPorEmail('bia@mail.com')).first;
    expect(a['password_hash'], isNot(b['password_hash']));
    await AuthHelper.sair();

    expect((await AuthHelper.entrar('ana@mail.com', 'errada')).erro,
        'E-mail ou senha incorretos.');
    expect((await AuthHelper.entrar('x@mail.com', 'Senha123')).ok, false);
    expect((await AuthHelper.entrar('', '')).ok, false);
    expect((await AuthHelper.entrar(' ANA@mail.com ', 'Senha123')).ok, true);
    expect(Sessao.nome, 'Ana');
  });

  test('cada conta vê só os seus decks e cards pendentes', () async {
    await cria('Ana', 'ana@mail.com');
    final idAna = Sessao.usuarioId!;
    final dAna = await SQLHelper.adicionaDeck('Deck da Ana', usuarioId: idAna);
    await SQLHelper.adicionaFlashcard(dAna, 'P?', 'R');
    await AuthHelper.sair();

    await cria('Bia', 'bia@mail.com');
    final idBia = Sessao.usuarioId!;
    await SQLHelper.adicionaDeck('Deck da Bia', usuarioId: idBia);

    final decksBia = await SQLHelper.pegaDecks(usuarioId: idBia);
    expect(decksBia.map((d) => d['title']), ['Deck da Bia']);
    expect(await SQLHelper.pegaFlashcardsPendentes(usuarioId: idBia), isEmpty);
    expect(await SQLHelper.pegaFlashcardsPendentes(usuarioId: idAna),
        hasLength(1));
    final est = await SQLHelper.pegaEstatisticas(usuarioId: idBia);
    expect(est['total_flashcards'] ?? est['totalFlashcards'] ?? 0, 0);
  });

  test('primeiro usuário adota decks antigos sem dono', () async {
    await SQLHelper.adicionaDeck('Antigo');
    await cria('Ana', 'ana@mail.com');
    final decks = await SQLHelper.pegaDecks(usuarioId: Sessao.usuarioId);
    expect(decks.map((d) => d['title']), ['Antigo']);
  });

  test('alterar senha e redefinir (esqueci a senha)', () async {
    await cria('Ana', 'ana@mail.com');
    expect(
        (await AuthHelper.alterarSenha(
                atual: 'errada', nova: 'Nova12345', confirmacao: 'Nova12345'))
            .erro,
        'Senha atual incorreta.');
    expect(
        (await AuthHelper.alterarSenha(
                atual: 'Senha123', nova: 'fraca', confirmacao: 'fraca'))
            .ok,
        false);
    expect(
        (await AuthHelper.alterarSenha(
                atual: 'Senha123', nova: 'Nova12345', confirmacao: 'Nova12345'))
            .ok,
        true);
    await AuthHelper.sair();
    expect((await AuthHelper.entrar('ana@mail.com', 'Senha123')).ok, false);
    expect((await AuthHelper.entrar('ana@mail.com', 'Nova12345')).ok, true);
    await AuthHelper.sair();

    // a troca também valeu na nuvem (vale em outros aparelhos)
    expect(nuvem.contas['ana@mail.com']!.senha, 'Nova12345');

    // "esqueci a senha": envia e-mail pela nuvem; e-mail inválido é recusado
    expect((await AuthHelper.enviarRedefinicaoSenha('invalido')).ok, false);
    expect((await AuthHelper.enviarRedefinicaoSenha('ANA@mail.com')).ok, true);
    expect(nuvem.redefinicoesEnviadas, ['ana@mail.com']);
  });

  test('cadastro cria conta na nuvem e guarda o uid', () async {
    expect((await cria('Ana', 'ana@mail.com')).ok, true);
    final u = (await SQLHelper.pegaUsuarioPorEmail('ana@mail.com')).first;
    expect(u['firebase_uid'], nuvem.contas['ana@mail.com']!.uid);
    // e-mail já usado na nuvem (outro aparelho) é recusado
    nuvem.preCadastra('bia@mail.com', 'Senha123');
    expect((await cria('Bia', 'bia@mail.com')).erro,
        'Já existe uma conta com este e-mail.');
  });

  test('conta antiga (só no aparelho) sobe para a nuvem no primeiro login',
      () async {
    final sal = AuthHelper.geraSal();
    await SQLHelper.inserePerfilLocal(
        nome: 'Antiga',
        email: 'antiga@mail.com',
        hash: AuthHelper.geraHash('Senha123', sal),
        sal: sal);
    expect(nuvem.contas.containsKey('antiga@mail.com'), false);

    expect((await AuthHelper.entrar('antiga@mail.com', 'errada')).ok, false);
    expect((await AuthHelper.entrar('antiga@mail.com', 'Senha123')).ok, true);
    expect(Sessao.nome, 'Antiga');
    expect(nuvem.contas['antiga@mail.com']!.senha, 'Senha123');
    final u = (await SQLHelper.pegaUsuarioPorEmail('antiga@mail.com')).first;
    expect(u['firebase_uid'], nuvem.contas['antiga@mail.com']!.uid);
  });

  test('entrar em aparelho novo cria o perfil local a partir da nuvem',
      () async {
    nuvem.preCadastra('maria@mail.com', 'Senha123', nome: 'Maria Souza');
    expect((await SQLHelper.pegaUsuarioPorEmail('maria@mail.com')), isEmpty);
    expect((await AuthHelper.entrar('maria@mail.com', 'Senha123')).ok, true);
    expect(Sessao.nome, 'Maria Souza');
    expect(Sessao.email, 'maria@mail.com');
  });

  test('sem internet: entra com conta já existente no aparelho', () async {
    await cria('Ana', 'ana@mail.com');
    await AuthHelper.sair();
    nuvem.semInternet = true;
    expect((await AuthHelper.entrar('ana@mail.com', 'errada')).ok, false);
    expect((await AuthHelper.entrar('ana@mail.com', 'Senha123')).ok, true);
    // conta desconhecida sem internet: avisa da conexão
    await AuthHelper.sair();
    expect((await AuthHelper.entrar('x@mail.com', 'Senha123')).erro,
        'Sem conexão com a internet. Tente novamente.');
  });

  test('login com Google guarda o uid do Firebase', () async {
    final r = await AuthHelper.entrarComGoogle(
        nome: 'Gabi',
        email: 'gabi@gmail.com',
        googleId: 'g123',
        firebaseUid: 'fb-uid-1');
    expect(r.ok, true);
    final u = (await SQLHelper.pegaUsuarioPorEmail('gabi@gmail.com')).first;
    expect(u['firebase_uid'], 'fb-uid-1');
    expect(u['google_id'], 'g123');
    expect(u['password_hash'], isNull);
    // quem entra pelo Google não tem senha para trocar
    expect(
        (await AuthHelper.alterarSenha(
                atual: 'x', nova: 'Nova12345', confirmacao: 'Nova12345'))
            .ok,
        false);
  });

  test('editar perfil e preferências', () async {
    await cria('Ana', 'ana@mail.com');
    await cria2();
    await AuthHelper.entrar('ana@mail.com', 'Senha123');
    expect(
        (await AuthHelper.atualizarPerfil(
                nome: 'Ana', email: 'bia@mail.com', ocupacao: 'x'))
            .erro,
        'Este e-mail já está em uso.');
    expect(
        (await AuthHelper.atualizarPerfil(
                nome: 'Ana Maria', email: 'ana2@mail.com', ocupacao: 'Eng'))
            .ok,
        true);
    expect(Sessao.nome, 'Ana Maria');
    expect(Sessao.ocupacao, 'Eng');
    await SQLHelper.atualizaPreferenciasUsuario(Sessao.usuarioId!,
        perfilVisivel: false, lembreteEstudo: false);
    final u = (await SQLHelper.pegaUmUsuario(Sessao.usuarioId!)).first;
    expect(u['is_profile_visible'], 0);
    expect(u['notify_study_reminder'], 0);
  });
  progressoTests();
}

Future<void> cria2() => AuthHelper.cadastrar(
    nome: 'Bia', email: 'bia@mail.com', senha: 'Senha123', confirmacao: 'Senha123');

void progressoTests() {
  test('1 acerto domina o card e o agendamento SM-2 continua', () async {
    SharedPreferences.setMockInitialValues({});
    await SQLHelper.apagaBancoInteiro();
    await AuthHelper.cadastrar(
        nome: 'Ana', email: 'p@mail.com', senha: 'Senha123', confirmacao: 'Senha123');
    final uid = Sessao.usuarioId!;
    final d = await SQLHelper.adicionaDeck('D', usuarioId: uid);
    await SQLHelper.adicionaFlashcard(d, 'P1', 'R1');
    await SQLHelper.adicionaFlashcard(d, 'P2', 'R2');
    final id1 =
        ((await SQLHelper.pegaFlashcardsDoDeck(d)).first['id'] as num).toInt();

    var e = await SQLHelper.pegaEstatisticas(usuarioId: uid);
    expect(e['mastery_percentage'], 0.0);

    await SQLHelper.registraRevisao(id1, Avaliacao.facil);
    e = await SQLHelper.pegaEstatisticas(usuarioId: uid);
    expect(e['mastered_cards'], 1);
    expect(e['mastery_percentage'], 50.0);
    expect(e['total_cards_reviewed'], 1);

    // continua agendado: não está mais pendente e volta depois do intervalo
    final c = (await SQLHelper.pegaUmFlashcard(id1)).first;
    expect(c['interval_days'], 1);
    expect(DateTime.parse(c['next_review'] as String).isAfter(DateTime.now()),
        true);
    expect(e['pending_cards'], 1); // só o card ainda não revisado

    await SQLHelper.registraRevisao(id1, Avaliacao.facil);
    expect((await SQLHelper.pegaUmFlashcard(id1)).first['interval_days'], 6);

    await SQLHelper.registraRevisao(id1, Avaliacao.errei);
    e = await SQLHelper.pegaEstatisticas(usuarioId: uid);
    expect(e['mastered_cards'], 0);
  });
}

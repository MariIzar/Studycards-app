// =============================================================================
// auth_helper.dart — Login 100% local (sem servidor)
// -----------------------------------------------------------------------------
// - Cadastro/login/logout usando a tabela `users` do SQLite.
// - A senha NUNCA é guardada em texto: guardamos HASH + SAL.
//     hash = SHA-256 aplicado 10.000 vezes sobre (sal + senha)
// - A sessão (quem está logado) fica no SharedPreferences (PreferenciasHelper).
// - "Esqueci a senha" é uma redefinição local: como não há servidor para enviar
//   e-mail, quem tem o aparelho em mãos pode redefinir pelo e-mail cadastrado.
// =============================================================================

import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import 'preferencias_helper.dart';
import 'sql_helper.dart';

/// Resultado de uma operação de autenticação.
class AuthResultado {
  final bool ok;
  final String? erro;
  const AuthResultado.sucesso()
      : ok = true,
        erro = null;
  const AuthResultado.falha(this.erro) : ok = false;
}

/// Guarda em memória quem está logado (carregado no início do app).
class Sessao {
  static int? usuarioId;
  static String nome = '';
  static String email = '';
  static String ocupacao = 'Estudante';

  static bool get logado => usuarioId != null;

  /// Primeiro nome, para saudações ("Olá, Maria!").
  static String get primeiroNome {
    final partes = nome.trim().split(RegExp(r'\s+'));
    return partes.first.isEmpty ? 'estudante' : partes.first;
  }

  static String get inicial =>
      nome.trim().isEmpty ? '?' : nome.trim()[0].toUpperCase();

  /// Lê a sessão salva e carrega os dados do usuário. Chamar no main().
  static Future<void> carrega() async {
    final id = await PreferenciasHelper.recuperaUsuarioLogado();
    if (id == null) {
      _limpa();
      return;
    }
    final dados = await SQLHelper.pegaUmUsuario(id);
    if (dados.isEmpty) {
      // usuário foi apagado: sessão inválida
      await PreferenciasHelper.removeUsuarioLogado();
      _limpa();
      return;
    }
    _preenche(dados.first);
  }

  static void _preenche(Map<String, dynamic> u) {
    usuarioId = (u['id'] as num).toInt();
    nome = u['name'] as String;
    email = u['email'] as String;
    ocupacao = (u['occupation'] as String?) ?? 'Estudante';
  }

  static void _limpa() {
    usuarioId = null;
    nome = '';
    email = '';
    ocupacao = 'Estudante';
  }
}

class AuthHelper {
  static const int _iteracoes = 10000;

  // ---------------------------------------------------------------------------
  // VALIDAÇÕES
  // ---------------------------------------------------------------------------
  static String normalizaEmail(String email) => email.trim().toLowerCase();

  static bool emailValido(String email) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.trim());

  static bool temOito(String s) => s.length >= 8;
  static bool temMaiuscula(String s) => RegExp(r'[A-Z]').hasMatch(s);
  static bool temMinuscula(String s) => RegExp(r'[a-z]').hasMatch(s);
  static bool temNumero(String s) => RegExp(r'[0-9]').hasMatch(s);

  /// Regras da tela "Alterar senha": 8+ caracteres, maiúscula, minúscula, número.
  static String? validaSenha(String senha) {
    if (!temOito(senha) ||
        !temMaiuscula(senha) ||
        !temMinuscula(senha) ||
        !temNumero(senha)) {
      return 'A senha precisa ter 8+ caracteres, maiúscula, minúscula e número.';
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // HASH + SAL
  // ---------------------------------------------------------------------------
  static String geraSal() {
    final r = Random.secure();
    return base64UrlEncode(List<int>.generate(16, (_) => r.nextInt(256)));
  }

  static String geraHash(String senha, String sal) {
    List<int> bytes = utf8.encode('$sal$senha');
    for (var i = 0; i < _iteracoes; i++) {
      bytes = sha256.convert([...bytes, ...utf8.encode(sal)]).bytes;
    }
    return base64UrlEncode(bytes);
  }

  static bool _confere(String senha, String? hash, String? sal) {
    if (hash == null || sal == null) return false;
    final calc = geraHash(senha, sal);
    // comparação sem atalho (evita vazar onde diferiu)
    if (calc.length != hash.length) return false;
    var dif = 0;
    for (var i = 0; i < calc.length; i++) {
      dif |= calc.codeUnitAt(i) ^ hash.codeUnitAt(i);
    }
    return dif == 0;
  }

  // ---------------------------------------------------------------------------
  // CADASTRO / LOGIN / LOGOUT
  // ---------------------------------------------------------------------------
  static Future<AuthResultado> cadastrar({
    required String nome,
    required String email,
    required String senha,
    required String confirmacao,
  }) async {
    final nomeLimpo = nome.trim();
    final emailNorm = normalizaEmail(email);
    if (nomeLimpo.isEmpty) return const AuthResultado.falha('Informe seu nome.');
    if (!emailValido(emailNorm)) {
      return const AuthResultado.falha('E-mail inválido.');
    }
    final erroSenha = validaSenha(senha);
    if (erroSenha != null) return AuthResultado.falha(erroSenha);
    if (senha != confirmacao) {
      return const AuthResultado.falha('As senhas não conferem.');
    }
    if ((await SQLHelper.pegaUsuarioPorEmail(emailNorm)).isNotEmpty) {
      return const AuthResultado.falha('Já existe uma conta com este e-mail.');
    }

    final sal = geraSal();
    final id = await SQLHelper.inserePerfilLocal(
      nome: nomeLimpo,
      email: emailNorm,
      hash: geraHash(senha, sal),
      sal: sal,
    );
    // Se já havia decks antes do login existir, o primeiro usuário fica com eles
    final total = (await (await SQLHelper.db()).rawQuery(
            'SELECT COUNT(*) AS c FROM users'))
        .first['c'] as int;
    if (total == 1) await SQLHelper.adotaDecksSemDono(id);

    await _abreSessao(id);
    return const AuthResultado.sucesso();
  }

  static Future<AuthResultado> entrar(String email, String senha) async {
    final emailNorm = normalizaEmail(email);
    if (emailNorm.isEmpty || senha.isEmpty) {
      return const AuthResultado.falha('Preencha e-mail e senha.');
    }
    final dados = await SQLHelper.pegaUsuarioPorEmail(emailNorm);
    if (dados.isEmpty) {
      return const AuthResultado.falha('E-mail ou senha incorretos.');
    }
    final u = dados.first;
    if (u['password_hash'] == null) {
      return const AuthResultado.falha(
          'Esta conta ainda não tem senha. Use "Esqueceu sua senha?" para criar uma.');
    }
    if (!_confere(senha, u['password_hash'] as String?,
        u['password_salt'] as String?)) {
      return const AuthResultado.falha('E-mail ou senha incorretos.');
    }
    await _abreSessao((u['id'] as num).toInt());
    return const AuthResultado.sucesso();
  }

  static Future<void> sair() async {
    await PreferenciasHelper.removeUsuarioLogado();
    Sessao._limpa();
  }

  static Future<void> _abreSessao(int id) async {
    await PreferenciasHelper.salvaUsuarioLogado(id);
    await Sessao.carrega();
  }

  // ---------------------------------------------------------------------------
  // SENHA
  // ---------------------------------------------------------------------------
  static Future<AuthResultado> alterarSenha({
    required String atual,
    required String nova,
    required String confirmacao,
  }) async {
    final id = Sessao.usuarioId;
    if (id == null) return const AuthResultado.falha('Você não está logado.');
    final u = (await SQLHelper.pegaUmUsuario(id)).first;
    if (!_confere(atual, u['password_hash'] as String?,
        u['password_salt'] as String?)) {
      return const AuthResultado.falha('Senha atual incorreta.');
    }
    final erro = validaSenha(nova);
    if (erro != null) return AuthResultado.falha(erro);
    if (nova != confirmacao) {
      return const AuthResultado.falha('As senhas não conferem.');
    }
    final sal = geraSal();
    await SQLHelper.atualizaSenhaUsuario(id, geraHash(nova, sal), sal);
    return const AuthResultado.sucesso();
  }

  /// "Esqueci a senha" local: redefine pelo e-mail cadastrado, neste aparelho.
  static Future<AuthResultado> redefinirSenha({
    required String email,
    required String nova,
    required String confirmacao,
  }) async {
    final dados = await SQLHelper.pegaUsuarioPorEmail(normalizaEmail(email));
    if (dados.isEmpty) {
      return const AuthResultado.falha('Nenhuma conta com este e-mail.');
    }
    final erro = validaSenha(nova);
    if (erro != null) return AuthResultado.falha(erro);
    if (nova != confirmacao) {
      return const AuthResultado.falha('As senhas não conferem.');
    }
    final sal = geraSal();
    await SQLHelper.atualizaSenhaUsuario(
        (dados.first['id'] as num).toInt(), geraHash(nova, sal), sal);
    return const AuthResultado.sucesso();
  }

  // ---------------------------------------------------------------------------
  // PERFIL
  // ---------------------------------------------------------------------------
  static Future<AuthResultado> atualizarPerfil({
    required String nome,
    required String email,
    required String ocupacao,
  }) async {
    final id = Sessao.usuarioId;
    if (id == null) return const AuthResultado.falha('Você não está logado.');
    final emailNorm = normalizaEmail(email);
    if (nome.trim().isEmpty) {
      return const AuthResultado.falha('Informe seu nome.');
    }
    if (!emailValido(emailNorm)) {
      return const AuthResultado.falha('E-mail inválido.');
    }
    final outro = await SQLHelper.pegaUsuarioPorEmail(emailNorm);
    if (outro.isNotEmpty && (outro.first['id'] as num).toInt() != id) {
      return const AuthResultado.falha('Este e-mail já está em uso.');
    }
    await SQLHelper.atualizaDadosPerfil(
        id, nome.trim(), emailNorm, ocupacao.trim().isEmpty ? 'Estudante' : ocupacao.trim());
    await Sessao.carrega();
    return const AuthResultado.sucesso();
  }
}

// Conta "na nuvem" falsa, só em memória, para os testes não dependerem do
// Firebase nem da internet.
import 'package:study_cards/services/nuvem_auth.dart';

class _Conta {
  String senha;
  final String uid;
  final String? nome;
  _Conta(this.senha, this.uid, this.nome);
}

class FakeNuvemAuth implements NuvemAuth {
  final Map<String, _Conta> contas = {};
  final List<String> redefinicoesEnviadas = [];
  bool semInternet = false;
  String? _email;
  int _n = 0;

  void _checaRede() {
    if (semInternet) throw const NuvemErro(NuvemFalha.semConexao);
  }

  /// Cria uma conta direto na "nuvem" (como se tivesse sido feita em outro aparelho).
  void preCadastra(String email, String senha, {String? nome}) {
    contas[email] = _Conta(senha, 'uid${++_n}', nome);
  }

  @override
  Future<NuvemUsuario> criaConta(String email, String senha,
      {String? nome}) async {
    _checaRede();
    if (contas.containsKey(email)) {
      throw const NuvemErro(NuvemFalha.emailEmUso);
    }
    final c = _Conta(senha, 'uid${++_n}', nome);
    contas[email] = c;
    _email = email;
    return NuvemUsuario(uid: c.uid, email: email, nome: nome);
  }

  @override
  Future<NuvemUsuario> entra(String email, String senha) async {
    _checaRede();
    final c = contas[email];
    if (c == null || c.senha != senha) {
      throw const NuvemErro(NuvemFalha.credencialInvalida);
    }
    _email = email;
    return NuvemUsuario(uid: c.uid, email: email, nome: c.nome);
  }

  @override
  Future<void> alteraSenha(String atual, String nova) async {
    _checaRede();
    final c = _email == null ? null : contas[_email];
    if (c == null || c.senha != atual) {
      throw const NuvemErro(NuvemFalha.credencialInvalida);
    }
    c.senha = nova;
  }

  @override
  Future<void> enviaRedefinicao(String email) async {
    _checaRede();
    redefinicoesEnviadas.add(email);
  }

  @override
  Future<void> sai() async => _email = null;

  @override
  String? get uidAtual => _email == null ? null : contas[_email]?.uid;
}

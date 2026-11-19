import 'package:firebase_auth/firebase_auth.dart';

/// Tipos de falha que o app sabe tratar (independem do Firebase).
enum NuvemFalha {
  emailEmUso,
  credencialInvalida,
  semConexao,
  senhaFraca,
  muitasTentativas,
  outro,
}

class NuvemErro implements Exception {
  final NuvemFalha falha;
  final String detalhe;
  const NuvemErro(this.falha, [this.detalhe = '']);

  @override
  String toString() => 'NuvemErro($falha $detalhe)';
}

class NuvemUsuario {
  final String uid;
  final String? email;
  final String? nome;
  const NuvemUsuario({required this.uid, this.email, this.nome});
}

/// Contrato da conta na nuvem. O app só conversa com esta interface, o que
/// permite trocar o Firebase por um "falso" nos testes.
abstract class NuvemAuth {
  Future<NuvemUsuario> criaConta(String email, String senha, {String? nome});
  Future<NuvemUsuario> entra(String email, String senha);
  Future<void> alteraSenha(String atual, String nova);
  Future<void> enviaRedefinicao(String email);
  Future<void> sai();
  String? get uidAtual;
}

/// Implementação real, com o Firebase Authentication.
class FirebaseNuvemAuth implements NuvemAuth {
  FirebaseAuth get _auth => FirebaseAuth.instance;

  NuvemErro _traduz(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return NuvemErro(NuvemFalha.emailEmUso, e.code);
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
      case 'invalid-email':
      case 'user-disabled':
        return NuvemErro(NuvemFalha.credencialInvalida, e.code);
      case 'network-request-failed':
        return NuvemErro(NuvemFalha.semConexao, e.code);
      case 'weak-password':
        return NuvemErro(NuvemFalha.senhaFraca, e.code);
      case 'too-many-requests':
        return NuvemErro(NuvemFalha.muitasTentativas, e.code);
      default:
        return NuvemErro(NuvemFalha.outro, e.code);
    }
  }

  NuvemUsuario _usuario(User? u) {
    if (u == null) throw const NuvemErro(NuvemFalha.outro, 'sem-usuario');
    return NuvemUsuario(uid: u.uid, email: u.email, nome: u.displayName);
  }

  @override
  Future<NuvemUsuario> criaConta(String email, String senha,
      {String? nome}) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
          email: email, password: senha);
      if (nome != null && nome.trim().isNotEmpty) {
        await cred.user?.updateDisplayName(nome.trim());
      }
      return NuvemUsuario(
          uid: cred.user!.uid, email: cred.user!.email, nome: nome);
    } on FirebaseAuthException catch (e) {
      throw _traduz(e);
    }
  }

  @override
  Future<NuvemUsuario> entra(String email, String senha) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
          email: email, password: senha);
      return _usuario(cred.user);
    } on FirebaseAuthException catch (e) {
      throw _traduz(e);
    }
  }

  @override
  Future<void> alteraSenha(String atual, String nova) async {
    final u = _auth.currentUser;
    final email = u?.email;
    if (u == null || email == null) {
      throw const NuvemErro(NuvemFalha.credencialInvalida, 'sem-sessao');
    }
    try {
      await u.reauthenticateWithCredential(
          EmailAuthProvider.credential(email: email, password: atual));
      await u.updatePassword(nova);
    } on FirebaseAuthException catch (e) {
      throw _traduz(e);
    }
  }

  @override
  Future<void> enviaRedefinicao(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _traduz(e);
    }
  }

  @override
  Future<void> sai() async {
    try {
      await _auth.signOut();
    } catch (_) {}
  }

  @override
  String? get uidAtual => _auth.currentUser?.uid;
}

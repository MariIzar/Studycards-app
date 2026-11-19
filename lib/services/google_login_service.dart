import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Dados devolvidos pelo Google (via Firebase) depois do login.
class GoogleLoginResultado {
  final bool ok;
  final bool cancelado;
  final String? erro;
  final String nome;
  final String email;
  final String googleId;
  final String? fotoUrl;
  final String? firebaseUid;

  const GoogleLoginResultado.sucesso({
    required this.nome,
    required this.email,
    required this.googleId,
    this.fotoUrl,
    this.firebaseUid,
  })  : ok = true,
        cancelado = false,
        erro = null;

  const GoogleLoginResultado.cancelado()
      : ok = false,
        cancelado = true,
        erro = null,
        nome = '',
        email = '',
        googleId = '',
        fotoUrl = null,
        firebaseUid = null;

  const GoogleLoginResultado.falha(this.erro)
      : ok = false,
        cancelado = false,
        nome = '',
        email = '',
        googleId = '',
        fotoUrl = null,
        firebaseUid = null;
}

/// O Firebase é usado SÓ para o login com Google. Os dados do app continuam
/// no SQLite local; a sessão do app é controlada pelo AuthHelper/Sessao.
class GoogleLoginService {
  // ID do cliente "Web" do projeto Firebase (vem do google-services.json).
  // Não é segredo: é o identificador público que o Google pede no Android.
  static const String _serverClientId =
      '990664408850-ea20ftlravasehepqvod3mo7290v5vpj.apps.googleusercontent.com';

  static bool _iniciado = false;

  static Future<GoogleLoginResultado> entrar() async {
    try {
      if (!_iniciado) {
        await GoogleSignIn.instance.initialize(serverClientId: _serverClientId);
        _iniciado = true;
      }

      // Abre a escolha de conta do próprio Android (sem navegador)
      final conta = await GoogleSignIn.instance.authenticate();
      final idToken = conta.authentication.idToken;
      if (idToken == null) {
        return const GoogleLoginResultado.falha(
            'O Google não devolveu a credencial de login.');
      }

      // Confirma a credencial no Firebase
      final cred = await FirebaseAuth.instance.signInWithCredential(
        GoogleAuthProvider.credential(idToken: idToken),
      );

      final resultado = GoogleLoginResultado.sucesso(
        nome: conta.displayName ?? '',
        email: conta.email,
        googleId: conta.id,
        fotoUrl: conta.photoUrl,
        firebaseUid: cred.user?.uid,
      );
      // A sessão do Firebase fica aberta: é ela que identifica a pessoa na
      // nuvem (backup/sincronização dos decks).
      return resultado;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted) {
        return const GoogleLoginResultado.cancelado();
      }
      return GoogleLoginResultado.falha(
          'Não foi possível entrar com o Google (${e.code.name}).');
    } on FirebaseAuthException catch (e) {
      return GoogleLoginResultado.falha(
          'Não foi possível entrar com o Google (${e.code}).');
    } catch (_) {
      return const GoogleLoginResultado.falha(
          'Não foi possível entrar com o Google. Tente novamente.');
    }
  }
}

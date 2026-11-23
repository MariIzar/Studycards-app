import 'package:flutter/material.dart';

import 'banco_de_dados/auth_helper.dart';
import 'requer_login.dart';
import 'language_controller.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback? onLogado;

  const LoginScreen({super.key, this.onLogado});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const purple = Color(0xFF7138F5);

  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();

  bool _carregando = false;
  bool _mostrarSenha = false;
  String? _erro;

  String _tr(String pt, String en, String es) {
    switch (LanguageController.locale.value.languageCode) {
      case 'en':
        return en;
      case 'es':
        return es;
      default:
        return pt;
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    super.dispose();
  }

  String _traduzirErro(String? mensagem) {
    if (mensagem == null || mensagem.trim().isEmpty) {
      return _tr(
        'Não foi possível entrar.',
        'Could not log in.',
        'No se pudo iniciar sesión.',
      );
    }

    final erro = mensagem.toLowerCase();

    if (erro.contains('invalid-email') ||
        erro.contains('e-mail inválido') ||
        erro.contains('email inválido')) {
      return _tr(
        'Informe um e-mail válido.',
        'Enter a valid email address.',
        'Introduce un correo electrónico válido.',
      );
    }

    if (erro.contains('wrong-password') ||
        erro.contains('invalid-credential') ||
        erro.contains('invalid-login-credentials') ||
        erro.contains('senha incorreta') ||
        erro.contains('credenciais inválidas')) {
      return _tr(
        'E-mail ou senha incorretos.',
        'Incorrect email or password.',
        'Correo o contraseña incorrectos.',
      );
    }

    if (erro.contains('user-not-found') ||
        erro.contains('usuário não encontrado')) {
      return _tr(
        'E-mail ou senha incorretos.',
        'Incorrect email or password.',
        'Correo o contraseña incorrectos.',
      );
    }

    if (erro.contains('too-many-requests') ||
        erro.contains('muitas tentativas')) {
      return _tr(
        'Muitas tentativas de acesso. Aguarde um pouco e tente novamente.',
        'Too many login attempts. Please wait and try again.',
        'Demasiados intentos de acceso. Espera e inténtalo de nuevo.',
      );
    }

    if (erro.contains('network-request-failed') ||
        erro.contains('sem conexão') ||
        erro.contains('erro de conexão')) {
      return _tr(
        'Erro de conexão. Verifique sua internet.',
        'Connection error. Check your internet connection.',
        'Error de conexión. Comprueba tu conexión a internet.',
      );
    }

    if (erro.contains('user-disabled') || erro.contains('conta desativada')) {
      return _tr(
        'Esta conta foi desativada.',
        'This account has been disabled.',
        'Esta cuenta ha sido desactivada.',
      );
    }

    // Preserva mensagens específicas do AuthHelper
    // quando não há tradução conhecida.
    return mensagem;
  }

  Future<void> _entrar() async {
    if (_carregando) return;

    final email = _emailCtrl.text.trim();
    final senha = _senhaCtrl.text;

    if (email.isEmpty || senha.isEmpty) {
      setState(() {
        _erro = _tr(
          'Preencha o e-mail e a senha.',
          'Enter your email and password.',
          'Introduce tu correo y contraseña.',
        );
      });
      return;
    }

    final emailValido = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);

    if (!emailValido) {
      setState(() {
        _erro = _tr(
          'Informe um e-mail válido.',
          'Enter a valid email address.',
          'Introduce un correo electrónico válido.',
        );
      });
      return;
    }

    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final resultado = await AuthHelper.entrar(email, senha);

      if (!mounted) return;

      if (resultado.ok) {
        if (widget.onLogado != null) {
          widget.onLogado!();
        } else {
          voltaDoLogin(context);
        }
      } else {
        setState(() {
          _carregando = false;
          _erro = _traduzirErro(resultado.erro);
        });
      }
    } catch (e) {
      debugPrint('Erro no login: $e');

      if (!mounted) return;

      setState(() {
        _carregando = false;
        _erro = _tr(
          'Não foi possível entrar. Tente novamente.',
          'Could not log in. Please try again.',
          'No se pudo iniciar sesión. Inténtalo de nuevo.',
        );
      });
    }
  }

  void _voltar() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LanguageController.locale,
      builder: (context, locale, child) {
        final dark = Theme.of(context).brightness == Brightness.dark;

        final bg = dark ? const Color(0xFF141320) : const Color(0xFFF8F7FF);

        final surface = dark ? const Color(0xFF242333) : Colors.white;

        final text = dark ? Colors.white : const Color(0xFF191B31);

        final muted = dark ? Colors.white60 : const Color(0xFF73798B);

        final border = dark ? const Color(0xFF454357) : const Color(0xFFE7E5F2);

        Widget campo(
          String titulo,
          TextEditingController controller, {
          bool senha = false,
        }) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: TextStyle(
                  color: muted,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 7),
              TextField(
                controller: controller,
                enabled: !_carregando,
                obscureText: senha && !_mostrarSenha,
                enableSuggestions: !senha,
                autocorrect: !senha,
                keyboardType: senha
                    ? TextInputType.visiblePassword
                    : TextInputType.emailAddress,
                textCapitalization: TextCapitalization.none,
                textInputAction: senha
                    ? TextInputAction.done
                    : TextInputAction.next,
                autofillHints: senha
                    ? const [AutofillHints.password]
                    : const [AutofillHints.email],
                onSubmitted: senha ? (_) => _entrar() : null,
                onChanged: (_) {
                  if (_erro != null) {
                    setState(() {
                      _erro = null;
                    });
                  }
                },
                decoration: InputDecoration(
                  filled: true,
                  fillColor: surface,
                  hintText: senha
                      ? _tr(
                          'Digite sua senha',
                          'Enter your password',
                          'Introduce tu contraseña',
                        )
                      : _tr(
                          'Digite seu e-mail',
                          'Enter your email',
                          'Introduce tu correo',
                        ),
                  hintStyle: TextStyle(color: muted, fontSize: 14),
                  suffixIcon: senha
                      ? IconButton(
                          tooltip: _mostrarSenha
                              ? _tr(
                                  'Ocultar senha',
                                  'Hide password',
                                  'Ocultar contraseña',
                                )
                              : _tr(
                                  'Mostrar senha',
                                  'Show password',
                                  'Mostrar contraseña',
                                ),
                          icon: Icon(
                            _mostrarSenha
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: muted,
                          ),
                          onPressed: () {
                            setState(() {
                              _mostrarSenha = !_mostrarSenha;
                            });
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: purple, width: 1.5),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: border),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                style: TextStyle(color: text),
              ),
            ],
          );
        }

        return Scaffold(
          backgroundColor: bg,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(21, 0, 21, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 98),

                  // LOGO
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Image.asset(
                        'assets/images/studycards_logo.png',
                        width: 92,
                        height: 92,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // NOME DO APLICATIVO
                  Text(
                    'Study Cards',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: text,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // SLOGAN
                  Text(
                    LanguageController.traduzir('app_slogan'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: text,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 37),

                  // E-MAIL
                  campo('E-mail', _emailCtrl),

                  const SizedBox(height: 17),

                  // SENHA
                  campo(
                    _tr('Senha', 'Password', 'Contraseña'),
                    _senhaCtrl,
                    senha: true,
                  ),

                  const SizedBox(height: 8),

                  // RECUPERAR SENHA
                  Align(
                    alignment: Alignment.center,
                    child: TextButton(
                      onPressed: _carregando
                          ? null
                          : () {
                              Navigator.pushNamed(context, '/forgot-password');
                            },
                      child: Text(
                        _tr(
                          'Esqueceu sua senha?',
                          'Forgot your password?',
                          '¿Olvidaste tu contraseña?',
                        ),
                        style: const TextStyle(
                          color: purple,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  // MENSAGEM DE ERRO
                  if (_erro != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _erro!,
                      textAlign: TextAlign.left,
                      style: const TextStyle(
                        color: Color(0xFFE53935),
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],

                  const SizedBox(height: 6),

                  // BOTÃO ENTRAR
                  SizedBox(
                    height: 57,
                    child: ElevatedButton(
                      onPressed: _carregando ? null : _entrar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: purple,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: purple.withValues(alpha: 0.6),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _carregando
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _tr('Entrar', 'Log in', 'Iniciar sesión'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 13),

                  // CRIAR CONTA
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        _tr(
                          'Ainda não possui conta?',
                          "Don't have an account yet?",
                          '¿Todavía no tienes una cuenta?',
                        ),
                        style: TextStyle(color: text, fontSize: 15),
                      ),
                      TextButton(
                        onPressed: _carregando
                            ? null
                            : () {
                                Navigator.pushNamed(context, '/register');
                              },
                        child: Text(
                          _tr('Criar conta', 'Create account', 'Crear cuenta'),
                          style: const TextStyle(
                            color: purple,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // VOLTAR
                  TextButton(
                    onPressed: _carregando ? null : _voltar,
                    child: Text(
                      _tr('Voltar', 'Back', 'Volver'),
                      style: const TextStyle(
                        color: purple,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

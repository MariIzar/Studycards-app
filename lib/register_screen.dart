import 'package:flutter/material.dart';

import 'banco_de_dados/auth_helper.dart';
import 'services/google_login_service.dart';
import 'requer_login.dart';
import 'language_controller.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const Color purple = Color(0xFF7138F5);

  final _nomeCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  final _confirmaCtrl = TextEditingController();

  bool _carregando = false;
  bool _mostrarSenha = false;
  bool _mostrarConfirmacao = false;

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
  void initState() {
    super.initState();
    _senhaCtrl.addListener(_atualizar);
  }

  void _atualizar() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _senhaCtrl.removeListener(_atualizar);

    _nomeCtrl.dispose();
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    _confirmaCtrl.dispose();

    super.dispose();
  }

  void _limparErro() {
    if (_erro != null && mounted) {
      setState(() {
        _erro = null;
      });
    }
  }

  String _traduzirErro(String? mensagem) {
    if (mensagem == null || mensagem.trim().isEmpty) {
      return _tr(
        'Não foi possível criar a conta.',
        'Could not create the account.',
        'No se pudo crear la cuenta.',
      );
    }

    final erro = mensagem.toLowerCase();

    if (erro.contains('email-already-in-use') ||
        erro.contains('e-mail já cadastrado') ||
        erro.contains('email já cadastrado') ||
        erro.contains('e-mail já existe')) {
      return _tr(
        'Este e-mail já está cadastrado.',
        'This email is already registered.',
        'Este correo electrónico ya está registrado.',
      );
    }

    if (erro.contains('invalid-email') || erro.contains('e-mail inválido')) {
      return _tr(
        'Informe um e-mail válido.',
        'Enter a valid email address.',
        'Introduce un correo electrónico válido.',
      );
    }

    if (erro.contains('weak-password') || erro.contains('senha fraca')) {
      return _tr(
        'A senha não atende aos requisitos de segurança.',
        'The password does not meet the security requirements.',
        'La contraseña no cumple los requisitos de seguridad.',
      );
    }

    if (erro.contains('network') || erro.contains('sem conexão')) {
      return _tr(
        'Erro de conexão. Verifique sua internet.',
        'Connection error. Check your internet connection.',
        'Error de conexión. Comprueba tu conexión a internet.',
      );
    }

    if (erro.contains('too-many-requests')) {
      return _tr(
        'Muitas tentativas. Aguarde um pouco e tente novamente.',
        'Too many attempts. Please wait and try again.',
        'Demasiados intentos. Espera e inténtalo de nuevo.',
      );
    }

    return mensagem;
  }

  bool _validarFormulario() {
    final nome = _nomeCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final senha = _senhaCtrl.text;
    final confirmacao = _confirmaCtrl.text;

    if (nome.isEmpty || email.isEmpty || senha.isEmpty || confirmacao.isEmpty) {
      setState(() {
        _erro = _tr(
          'Preencha todos os campos.',
          'Fill in all fields.',
          'Completa todos los campos.',
        );
      });
      return false;
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
      return false;
    }

    final senhaValida =
        AuthHelper.temOito(senha) &&
        AuthHelper.temMaiuscula(senha) &&
        AuthHelper.temMinuscula(senha) &&
        AuthHelper.temNumero(senha);

    if (!senhaValida) {
      setState(() {
        _erro = _tr(
          'Sua senha precisa atender a todos os requisitos.',
          'Your password must meet all requirements.',
          'Tu contraseña debe cumplir todos los requisitos.',
        );
      });
      return false;
    }

    if (senha != confirmacao) {
      setState(() {
        _erro = _tr(
          'As senhas não coincidem.',
          'Passwords do not match.',
          'Las contraseñas no coinciden.',
        );
      });
      return false;
    }

    return true;
  }

  Future<void> _cadastrar() async {
    if (_carregando) return;

    if (!_validarFormulario()) return;

    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final resultado = await AuthHelper.cadastrar(
        nome: _nomeCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        senha: _senhaCtrl.text,
        confirmacao: _confirmaCtrl.text,
      );

      if (!mounted) return;

      if (resultado.ok) {
        Navigator.pushReplacementNamed(context, '/account-created');
      } else {
        setState(() {
          _carregando = false;
          _erro = _traduzirErro(resultado.erro);
        });
      }
    } catch (e) {
      debugPrint('Erro ao cadastrar: $e');

      if (!mounted) return;

      setState(() {
        _carregando = false;
        _erro = _tr(
          'Não foi possível criar a conta. Tente novamente.',
          'Could not create the account. Please try again.',
          'No se pudo crear la cuenta. Inténtalo de nuevo.',
        );
      });
    }
  }

  Future<void> _entrarComGoogle() async {
    if (_carregando) return;

    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final google = await GoogleLoginService.entrar();

      if (!mounted) return;

      if (google.cancelado) {
        setState(() {
          _carregando = false;
        });
        return;
      }

      if (!google.ok) {
        setState(() {
          _carregando = false;
          _erro = _traduzirErro(google.erro);
        });
        return;
      }

      final resultado = await AuthHelper.entrarComGoogle(
        nome: google.nome,
        email: google.email,
        googleId: google.googleId,
        fotoUrl: google.fotoUrl,
        firebaseUid: google.firebaseUid,
      );

      if (!mounted) return;

      if (resultado.ok) {
        voltaDoLogin(context);
      } else {
        setState(() {
          _carregando = false;
          _erro = _traduzirErro(resultado.erro);
        });
      }
    } catch (e) {
      debugPrint('Erro no login com Google: $e');

      if (!mounted) return;

      setState(() {
        _carregando = false;
        _erro = _tr(
          'Não foi possível entrar com Google.',
          'Could not sign in with Google.',
          'No se pudo iniciar sesión con Google.',
        );
      });
    }
  }

  void _abrirLogin() {
    if (_carregando) return;

    final rota = ModalRoute.of(context)?.settings.name;

    if (rota == '/register') {
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      Navigator.pushNamed(context, '/login');
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
          bool confirmacao = false,
          TextInputType tipo = TextInputType.text,
          TextInputAction acao = TextInputAction.next,
        }) {
          final mostrar = confirmacao ? _mostrarConfirmacao : _mostrarSenha;

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
                obscureText: senha && !mostrar,
                keyboardType: senha ? TextInputType.visiblePassword : tipo,
                textInputAction: acao,
                textCapitalization: senha || tipo == TextInputType.emailAddress
                    ? TextCapitalization.none
                    : TextCapitalization.words,
                autocorrect: !senha && tipo != TextInputType.emailAddress,
                enableSuggestions: !senha,
                autofillHints: confirmacao
                    ? const [AutofillHints.newPassword]
                    : senha
                    ? const [AutofillHints.newPassword]
                    : tipo == TextInputType.emailAddress
                    ? const [AutofillHints.email]
                    : const [AutofillHints.name],
                onSubmitted: acao == TextInputAction.done
                    ? (_) => _cadastrar()
                    : null,
                onChanged: (_) => _limparErro(),
                style: TextStyle(color: text),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  suffixIcon: senha
                      ? IconButton(
                          tooltip: mostrar
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
                            mostrar
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: muted,
                          ),
                          onPressed: () {
                            setState(() {
                              if (confirmacao) {
                                _mostrarConfirmacao = !_mostrarConfirmacao;
                              } else {
                                _mostrarSenha = !_mostrarSenha;
                              }
                            });
                          },
                        )
                      : null,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: purple, width: 1.5),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          );
        }

        Widget requisito(String titulo, bool valido) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Icon(
                  valido ? Icons.check_circle_outline : Icons.circle_outlined,
                  size: 15,
                  color: valido ? Colors.green : muted,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    titulo,
                    style: TextStyle(
                      color: valido
                          ? (dark ? Colors.greenAccent : Colors.green)
                          : muted,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          backgroundColor: bg,
          appBar: AppBar(
            backgroundColor: bg,
            foregroundColor: text,
            elevation: 0,
            centerTitle: true,
            title: Text(
              _tr('Crie sua conta', 'Create your account', 'Crea tu cuenta'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(21, 12, 21, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _tr(
                      'Comece sua jornada de estudos inteligentes.',
                      'Start your smart learning journey.',
                      'Comienza tu camino de aprendizaje inteligente.',
                    ),
                    style: TextStyle(color: muted, fontSize: 16),
                  ),

                  const SizedBox(height: 18),

                  campo(
                    _tr('Nome completo', 'Full name', 'Nombre completo'),
                    _nomeCtrl,
                  ),

                  const SizedBox(height: 18),

                  campo('E-mail', _emailCtrl, tipo: TextInputType.emailAddress),

                  const SizedBox(height: 18),

                  campo(
                    _tr('Senha', 'Password', 'Contraseña'),
                    _senhaCtrl,
                    senha: true,
                  ),

                  const SizedBox(height: 18),

                  campo(
                    _tr(
                      'Confirmar senha',
                      'Confirm password',
                      'Confirmar contraseña',
                    ),
                    _confirmaCtrl,
                    senha: true,
                    confirmacao: true,
                    acao: TextInputAction.done,
                  ),

                  const SizedBox(height: 15),

                  // REQUISITOS DA SENHA
                  requisito(
                    _tr(
                      'Pelo menos 8 caracteres',
                      'At least 8 characters',
                      'Al menos 8 caracteres',
                    ),
                    AuthHelper.temOito(_senhaCtrl.text),
                  ),

                  requisito(
                    _tr(
                      'Uma letra maiúscula',
                      'One uppercase letter',
                      'Una letra mayúscula',
                    ),
                    AuthHelper.temMaiuscula(_senhaCtrl.text),
                  ),

                  requisito(
                    _tr(
                      'Uma letra minúscula',
                      'One lowercase letter',
                      'Una letra minúscula',
                    ),
                    AuthHelper.temMinuscula(_senhaCtrl.text),
                  ),

                  requisito(
                    _tr('Um número', 'One number', 'Un número'),
                    AuthHelper.temNumero(_senhaCtrl.text),
                  ),

                  // MENSAGEM DE ERRO
                  if (_erro != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      _erro!,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 14,
                      ),
                    ),
                  ],

                  const SizedBox(height: 42),

                  // CADASTRO POR E-MAIL
                  SizedBox(
                    height: 57,
                    child: ElevatedButton(
                      onPressed: _carregando ? null : _cadastrar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: purple,
                        foregroundColor: Colors.white,
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
                              _tr(
                                'Criar minha conta',
                                'Create my account',
                                'Crear mi cuenta',
                              ),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 19),

                  // DIVISÓRIA
                  Row(
                    children: [
                      Expanded(child: Divider(color: border)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          _tr(
                            'ou cadastre-se com',
                            'or sign up with',
                            'o regístrate con',
                          ),
                          style: TextStyle(color: muted),
                        ),
                      ),
                      Expanded(child: Divider(color: border)),
                    ],
                  ),

                  const SizedBox(height: 15),

                  // CADASTRO COM GOOGLE
                  SizedBox(
                    height: 56,
                    child: OutlinedButton(
                      onPressed: _carregando ? null : _entrarComGoogle,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: surface,
                        foregroundColor: text,
                        side: BorderSide(color: border, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Google',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // IR PARA LOGIN
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        _tr(
                          'Já possui uma conta?',
                          'Already have an account?',
                          '¿Ya tienes una cuenta?',
                        ),
                        style: TextStyle(color: text, fontSize: 15),
                      ),
                      TextButton(
                        onPressed: _carregando ? null : _abrirLogin,
                        child: Text(
                          _tr('Entrar', 'Log in', 'Iniciar sesión'),
                          style: const TextStyle(
                            color: purple,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
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

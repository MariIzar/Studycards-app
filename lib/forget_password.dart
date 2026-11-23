import 'package:flutter/material.dart';

import 'banco_de_dados/auth_helper.dart';
import 'language_controller.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  static const purple = Color(0xFF7138F5);

  final _emailCtrl = TextEditingController();
  bool _carregando = false;
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
    super.dispose();
  }

  Future<void> _continuar() async {
    if (_carregando) return;

    FocusScope.of(context).unfocus();
    final email = _emailCtrl.text.trim();

    if (!AuthHelper.emailValido(email)) {
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
      final resultado = await AuthHelper.enviarRedefinicaoSenha(email);
      if (!mounted) return;

      if (resultado.ok) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LinkEnviadoScreen()),
        );
      } else {
        setState(() {
          _erro =
              resultado.erro ??
              _tr(
                'Não foi possível enviar o link.',
                'Could not send the link.',
                'No se pudo enviar el enlace.',
              );
        });
      }
    } catch (e) {
      debugPrint('Erro ao recuperar senha: $e');
      if (!mounted) return;
      setState(() {
        _erro = _tr(
          'Não foi possível enviar o link. Tente novamente.',
          'Could not send the link. Please try again.',
          'No se pudo enviar el enlace. Inténtalo de nuevo.',
        );
      });
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LanguageController.locale,
      builder: (context, idioma, child) {
        final tema = Theme.of(context);
        final cores = tema.colorScheme;

        return Scaffold(
          backgroundColor: tema.scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            foregroundColor: cores.onSurface,
            elevation: 0,
            centerTitle: true,
            title: Text(
              _tr(
                'Recuperar senha',
                'Recover password',
                'Recuperar contraseña',
              ),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(21, 22, 21, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: purple.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.mark_email_read_outlined,
                      size: 34,
                      color: purple,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    _tr(
                      'Recupere sua senha por e-mail',
                      'Recover your password by email',
                      'Recupera tu contraseña por correo',
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: cores.onSurface,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _tr(
                      'Informe o e-mail da sua conta para receber um link de redefinição de senha.',
                      'Enter your account email to receive a password reset link.',
                      'Introduce el correo de tu cuenta para recibir un enlace para restablecer tu contraseña.',
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: cores.onSurfaceVariant,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    _tr(
                      'E-mail da sua conta',
                      'Account email',
                      'Correo de tu cuenta',
                    ),
                    style: TextStyle(
                      color: cores.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _emailCtrl,
                    enabled: !_carregando,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.email],
                    onSubmitted: (_) => _continuar(),
                    onChanged: (_) {
                      if (_erro != null) setState(() => _erro = null);
                    },
                    style: TextStyle(color: cores.onSurface),
                    decoration: InputDecoration(
                      hintText: _tr(
                        'Digite seu e-mail',
                        'Enter your email',
                        'Introduce tu correo',
                      ),
                      hintStyle: TextStyle(color: cores.onSurfaceVariant),
                      prefixIcon: const Icon(Icons.email_outlined),
                      filled: true,
                      fillColor: cores.surface,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 17,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: cores.outlineVariant),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: purple, width: 1.5),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Colors.redAccent),
                      ),
                    ),
                  ),
                  if (_erro != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _erro!,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 14,
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  SizedBox(
                    height: 57,
                    child: ElevatedButton(
                      onPressed: _carregando ? null : _continuar,
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
                              _tr('Enviar link', 'Send link', 'Enviar enlace'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _carregando
                        ? null
                        : () => Navigator.pop(context),
                    child: Text(
                      _tr(
                        'Voltar para o login',
                        'Back to login',
                        'Volver al inicio de sesión',
                      ),
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

class LinkEnviadoScreen extends StatelessWidget {
  const LinkEnviadoScreen({super.key});

  static const purple = Color(0xFF7138F5);

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
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LanguageController.locale,
      builder: (context, idioma, child) {
        final tema = Theme.of(context);
        final cores = tema.colorScheme;

        return Scaffold(
          backgroundColor: tema.scaffoldBackgroundColor,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Container(
                      width: 85,
                      height: 85,
                      decoration: BoxDecoration(
                        color: purple.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.mail_outline_rounded,
                        color: purple,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _tr('Link enviado!', 'Link sent!', '¡Enlace enviado!'),
                      style: TextStyle(
                        color: cores.onSurface,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _tr(
                        'Se houver uma conta vinculada a esse e-mail, você receberá um link para redefinir sua senha. Confira também a pasta de spam.',
                        'If an account is associated with this email, you will receive a password reset link. Check your spam folder too.',
                        'Si existe una cuenta asociada a este correo, recibirás un enlace para restablecer tu contraseña. Revisa también la carpeta de spam.',
                      ),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: cores.onSurfaceVariant,
                        fontSize: 16,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 57,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/login',
                            (route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: purple,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          _tr(
                            'Voltar para o login',
                            'Back to login',
                            'Volver al inicio de sesión',
                          ),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';

import 'banco_de_dados/auth_helper.dart';
import 'language_controller.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _atualCtrl = TextEditingController();
  final _novaCtrl = TextEditingController();
  final _confirmaCtrl = TextEditingController();

  bool _carregando = false;
  bool _mostrarAtual = false;
  bool _mostrarNova = false;
  bool _mostrarConfirmacao = false;

  String? _erro;

  String _traduzir(String pt, String en, String es) {
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

    _novaCtrl.addListener(_atualizarRequisitos);
  }

  void _atualizarRequisitos() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _novaCtrl.removeListener(_atualizarRequisitos);

    _atualCtrl.dispose();
    _novaCtrl.dispose();
    _confirmaCtrl.dispose();

    super.dispose();
  }

  Future<void> _salvar() async {
    if (_carregando) return;

    FocusScope.of(context).unfocus();

    if (_atualCtrl.text.isEmpty ||
        _novaCtrl.text.isEmpty ||
        _confirmaCtrl.text.isEmpty) {
      setState(() {
        _erro = _traduzir(
          'Preencha todos os campos.',
          'Please fill in all fields.',
          'Completa todos los campos.',
        );
      });
      return;
    }

    if (_novaCtrl.text != _confirmaCtrl.text) {
      setState(() {
        _erro = _traduzir(
          'A confirmação não corresponde à nova senha.',
          'Password confirmation does not match.',
          'La confirmación no coincide con la nueva contraseña.',
        );
      });
      return;
    }

    final nova = _novaCtrl.text;

    if (!AuthHelper.temOito(nova) ||
        !AuthHelper.temMaiuscula(nova) ||
        !AuthHelper.temMinuscula(nova) ||
        !AuthHelper.temNumero(nova)) {
      setState(() {
        _erro = _traduzir(
          'A nova senha não atende aos requisitos.',
          'The new password does not meet the requirements.',
          'La nueva contraseña no cumple los requisitos.',
        );
      });
      return;
    }

    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final resultado = await AuthHelper.alterarSenha(
        atual: _atualCtrl.text,
        nova: _novaCtrl.text,
        confirmacao: _confirmaCtrl.text,
      );

      if (!mounted) return;

      if (resultado.ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _traduzir(
                'Senha alterada com sucesso!',
                'Password changed successfully!',
                '¡Contraseña cambiada correctamente!',
              ),
            ),
          ),
        );

        Navigator.pop(context);
      } else {
        setState(() {
          _erro =
              resultado.erro ??
              _traduzir(
                'Não foi possível alterar a senha.',
                'Could not change your password.',
                'No se pudo cambiar la contraseña.',
              );
        });
      }
    } catch (erro) {
      if (!mounted) return;

      debugPrint('Erro ao alterar senha: $erro');

      setState(() {
        _erro = _traduzir(
          'Ocorreu um erro ao alterar a senha. Tente novamente.',
          'An error occurred while changing your password. Please try again.',
          'Ocurrió un error al cambiar la contraseña. Inténtalo de nuevo.',
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _carregando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryPurple = Color(0xFF6C4DFF);

    return ValueListenableBuilder<Locale>(
      valueListenable: LanguageController.locale,
      builder: (context, idioma, child) {
        final tema = Theme.of(context);
        final cores = tema.colorScheme;
        final nova = _novaCtrl.text;

        return Scaffold(
          backgroundColor: tema.scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            foregroundColor: cores.onSurface,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              _traduzir(
                'Alterar senha',
                'Change Password',
                'Cambiar contraseña',
              ),
              style: TextStyle(
                color: cores.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel(
                    context,
                    _traduzir(
                      'Senha atual',
                      'Current password',
                      'Contraseña actual',
                    ),
                  ),

                  const SizedBox(height: 8),

                  _buildPasswordField(
                    context: context,
                    hint: _traduzir(
                      'Digite sua senha atual',
                      'Enter your current password',
                      'Introduce tu contraseña actual',
                    ),
                    controller: _atualCtrl,
                    visivel: _mostrarAtual,
                    aoAlternarVisibilidade: () {
                      setState(() {
                        _mostrarAtual = !_mostrarAtual;
                      });
                    },
                  ),

                  const SizedBox(height: 20),

                  _buildLabel(
                    context,
                    _traduzir('Nova senha', 'New password', 'Nueva contraseña'),
                  ),

                  const SizedBox(height: 8),

                  _buildPasswordField(
                    context: context,
                    hint: _traduzir(
                      'Digite sua nova senha',
                      'Enter your new password',
                      'Introduce tu nueva contraseña',
                    ),
                    controller: _novaCtrl,
                    visivel: _mostrarNova,
                    aoAlternarVisibilidade: () {
                      setState(() {
                        _mostrarNova = !_mostrarNova;
                      });
                    },
                  ),

                  const SizedBox(height: 20),

                  _buildLabel(
                    context,
                    _traduzir(
                      'Confirmar nova senha',
                      'Confirm new password',
                      'Confirmar nueva contraseña',
                    ),
                  ),

                  const SizedBox(height: 8),

                  _buildPasswordField(
                    context: context,
                    hint: _traduzir(
                      'Confirme sua nova senha',
                      'Confirm your new password',
                      'Confirma tu nueva contraseña',
                    ),
                    controller: _confirmaCtrl,
                    visivel: _mostrarConfirmacao,
                    aoAlternarVisibilidade: () {
                      setState(() {
                        _mostrarConfirmacao = !_mostrarConfirmacao;
                      });
                    },
                  ),

                  const SizedBox(height: 24),

                  // Requisitos da senha
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: primaryPurple.withValues(
                        alpha: tema.brightness == Brightness.dark ? 0.16 : 0.08,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _traduzir(
                            'A senha deve conter:',
                            'Password requirements:',
                            'La contraseña debe contener:',
                          ),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF9C87FF),
                          ),
                        ),

                        const SizedBox(height: 8),

                        _buildRequirementRow(
                          context,
                          _traduzir(
                            'Pelo menos 8 caracteres',
                            'At least 8 characters',
                            'Al menos 8 caracteres',
                          ),
                          AuthHelper.temOito(nova),
                        ),

                        _buildRequirementRow(
                          context,
                          _traduzir(
                            'Uma letra maiúscula',
                            'One uppercase letter',
                            'Una letra mayúscula',
                          ),
                          AuthHelper.temMaiuscula(nova),
                        ),

                        _buildRequirementRow(
                          context,
                          _traduzir(
                            'Uma letra minúscula',
                            'One lowercase letter',
                            'Una letra minúscula',
                          ),
                          AuthHelper.temMinuscula(nova),
                        ),

                        _buildRequirementRow(
                          context,
                          _traduzir('Um número', 'One number', 'Un número'),
                          AuthHelper.temNumero(nova),
                        ),
                      ],
                    ),
                  ),

                  if (_erro != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _erro!,
                      style: const TextStyle(
                        color: Color(0xFFE53935),
                        fontSize: 13,
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryPurple,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: primaryPurple.withValues(
                        alpha: 0.45,
                      ),
                      minimumSize: const Size.fromHeight(52),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _carregando ? null : _salvar,
                    child: _carregando
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _traduzir(
                              'Salvar nova senha',
                              'Save new password',
                              'Guardar nueva contraseña',
                            ),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
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

  Widget _buildLabel(BuildContext context, String texto) {
    return Text(
      texto,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildPasswordField({
    required BuildContext context,
    required String hint,
    required TextEditingController controller,
    required bool visivel,
    required VoidCallback aoAlternarVisibilidade,
  }) {
    final cores = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cores.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cores.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: cores.shadow.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: !visivel,
        autocorrect: false,
        enableSuggestions: false,
        textCapitalization: TextCapitalization.none,
        style: TextStyle(color: cores.onSurface),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: cores.onSurfaceVariant, fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          suffixIcon: IconButton(
            tooltip: visivel
                ? _traduzir(
                    'Ocultar senha',
                    'Hide password',
                    'Ocultar contraseña',
                  )
                : _traduzir(
                    'Mostrar senha',
                    'Show password',
                    'Mostrar contraseña',
                  ),
            icon: Icon(
              visivel
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: cores.onSurfaceVariant,
            ),
            onPressed: aoAlternarVisibilidade,
          ),
        ),
      ),
    );
  }

  Widget _buildRequirementRow(
    BuildContext context,
    String texto,
    bool atendido,
  ) {
    final cores = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(
            atendido ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 17,
            color: atendido ? const Color(0xFF8C7CFF) : cores.onSurfaceVariant,
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Text(
              texto,
              style: TextStyle(
                fontSize: 13,
                color: atendido ? cores.onSurface : cores.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import 'banco_de_dados/auth_helper.dart';
import 'language_controller.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  static const Color primaryPurple = Color(0xFF6C4DFF);

  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nomeCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _ocupacaoCtrl;

  bool _carregando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();

    _nomeCtrl = TextEditingController(text: Sessao.nome);
    _emailCtrl = TextEditingController(text: Sessao.email);
    _ocupacaoCtrl = TextEditingController(text: Sessao.ocupacao);
  }

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
  void dispose() {
    _nomeCtrl.dispose();
    _emailCtrl.dispose();
    _ocupacaoCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (_carregando) return;

    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final resultado = await AuthHelper.atualizarPerfil(
        nome: _nomeCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        ocupacao: _ocupacaoCtrl.text.trim(),
      );

      if (!mounted) return;

      if (resultado.ok) {
        Navigator.pop(context, true);
      } else {
        setState(() {
          _erro =
              resultado.erro ??
              _traduzir(
                'Não foi possível atualizar o perfil.',
                'Could not update your profile.',
                'No se pudo actualizar el perfil.',
              );
        });
      }
    } catch (e) {
      debugPrint('Erro ao atualizar perfil: $e');

      if (!mounted) return;

      setState(() {
        _erro = _traduzir(
          'Ocorreu um erro ao salvar as alterações. Tente novamente.',
          'An error occurred while saving. Please try again.',
          'Se produjo un error al guardar. Inténtalo de nuevo.',
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization capitalization = TextCapitalization.none,
    String? Function(String?)? validator,
  }) {
    final cores = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: cores.onSurfaceVariant,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: cores.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: cores.outlineVariant.withValues(alpha: 0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            enabled: !_carregando,
            keyboardType: keyboardType,
            textCapitalization: capitalization,
            validator: validator,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            style: TextStyle(color: cores.onSurface, fontSize: 16),
            decoration: InputDecoration(
              border: InputBorder.none,
              errorMaxLines: 2,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              hintText: label,
              hintStyle: TextStyle(
                color: cores.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ),
        ),
      ],
    );
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
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _carregando ? null : () => Navigator.pop(context),
            ),
            title: Text(
              _traduzir('Editar perfil', 'Edit profile', 'Editar perfil'),
              style: TextStyle(
                color: cores.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: CircleAvatar(
                        radius: 44,
                        backgroundColor: primaryPurple,
                        child: Text(
                          Sessao.inicial,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Center(
                      child: Text(
                        _traduzir(
                          'Informações pessoais',
                          'Personal information',
                          'Información personal',
                        ),
                        style: TextStyle(
                          color: cores.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Nome
                    _buildTextField(
                      controller: _nomeCtrl,
                      label: _traduzir('Nome', 'Name', 'Nombre'),
                      capitalization: TextCapitalization.words,
                      validator: (valor) {
                        if (valor == null || valor.trim().isEmpty) {
                          return _traduzir(
                            'Digite seu nome.',
                            'Enter your name.',
                            'Introduce tu nombre.',
                          );
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // E-mail
                    _buildTextField(
                      controller: _emailCtrl,
                      label: _traduzir('E-mail', 'Email', 'Correo electrónico'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (valor) {
                        final email = valor?.trim() ?? '';

                        if (email.isEmpty) {
                          return _traduzir(
                            'Digite seu e-mail.',
                            'Enter your email.',
                            'Introduce tu correo electrónico.',
                          );
                        }

                        final emailValido = RegExp(
                          r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                        ).hasMatch(email);

                        if (!emailValido) {
                          return _traduzir(
                            'Digite um e-mail válido.',
                            'Enter a valid email address.',
                            'Introduce un correo electrónico válido.',
                          );
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Curso ou ocupação
                    _buildTextField(
                      controller: _ocupacaoCtrl,
                      label: _traduzir(
                        'Curso / Ocupação',
                        'Course / Occupation',
                        'Carrera / Ocupación',
                      ),
                      capitalization: TextCapitalization.sentences,
                    ),

                    if (_erro != null) ...[
                      const SizedBox(height: 20),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Color(0xFFE53935),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _erro!,
                              style: const TextStyle(
                                color: Color(0xFFE53935),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 40),

                    // Salvar alterações
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _carregando ? null : _salvar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryPurple,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: primaryPurple.withValues(
                            alpha: 0.5,
                          ),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _carregando
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _traduzir(
                                  'Salvar alterações',
                                  'Save changes',
                                  'Guardar cambios',
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
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

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'banco_de_dados/auth_helper.dart';
import 'banco_de_dados/sql_helper.dart';
import 'language_controller.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  static const Color primaryPurple = Color(0xFF6C4DFF);

  bool profileVisible = true;
  bool showProgress = true;
  bool usageData = false;

  bool _carregando = true;
  bool _salvando = false;

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

  String _chavePreferencia(String nome) {
    final id = Sessao.usuarioId;
    return 'studycards_privacy_${id ?? 'guest'}_$nome';
  }

  @override
  void initState() {
    super.initState();
    _carrega();
  }

  Future<void> _carrega() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      bool perfil = prefs.getBool(_chavePreferencia('profile_visible')) ?? true;

      final progresso =
          prefs.getBool(_chavePreferencia('show_progress')) ?? true;

      final dados = prefs.getBool(_chavePreferencia('usage_data')) ?? false;

      final id = Sessao.usuarioId;

      if (id != null) {
        final usuarios = await SQLHelper.pegaUmUsuario(id);

        if (usuarios.isNotEmpty) {
          final valor = usuarios.first['is_profile_visible'];

          if (valor != null) {
            perfil = valor == 1 || valor == true;
          }
        }
      }

      if (!mounted) return;

      setState(() {
        profileVisible = perfil;
        showProgress = progresso;
        usageData = dados;
        _carregando = false;
      });
    } catch (e) {
      debugPrint('Erro ao carregar privacidade: $e');

      if (!mounted) return;

      setState(() {
        _carregando = false;
      });

      _mostrarMensagem(
        _tr(
          'Não foi possível carregar todas as preferências.',
          'Could not load all privacy preferences.',
          'No se pudieron cargar todas las preferencias de privacidad.',
        ),
      );
    }
  }

  Future<void> _salvar() async {
    if (_salvando || _carregando) return;

    setState(() {
      _salvando = true;
    });

    try {
      final id = Sessao.usuarioId;

      // Preserva a configuração original no SQLite.
      if (id != null) {
        await SQLHelper.atualizaPreferenciasUsuario(
          id,
          perfilVisivel: profileVisible,
        );
      }

      // Guarda as preferências locais separadamente
      // para cada usuário.
      final prefs = await SharedPreferences.getInstance();

      final resultados = await Future.wait([
        prefs.setBool(_chavePreferencia('profile_visible'), profileVisible),
        prefs.setBool(_chavePreferencia('show_progress'), showProgress),
        prefs.setBool(_chavePreferencia('usage_data'), usageData),
      ]);

      if (resultados.any((salvou) => !salvou)) {
        throw StateError('Falha ao salvar preferências de privacidade.');
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _tr(
              'Preferências de privacidade salvas!',
              'Privacy preferences saved!',
              '¡Preferencias de privacidad guardadas!',
            ),
          ),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      debugPrint('Erro ao salvar privacidade: $e');

      if (!mounted) return;

      _mostrarMensagem(
        _tr(
          'Não foi possível salvar as alterações. Tente novamente.',
          'Could not save changes. Please try again.',
          'No se pudieron guardar los cambios. Inténtalo de nuevo.',
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _salvando = false;
        });
      }
    }
  }

  void _mostrarMensagem(String mensagem) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensagem)));
  }

  Widget _buildSwitch({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color textColor,
    required Color subtitleColor,
  }) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      title: Text(
        title,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          subtitle,
          style: TextStyle(color: subtitleColor, fontSize: 12),
        ),
      ),
      value: value,
      activeThumbColor: primaryPurple,
      activeTrackColor: primaryPurple.withValues(alpha: 0.35),
      onChanged: _carregando || _salvando ? null : onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LanguageController.locale,
      builder: (context, locale, child) {
        final theme = Theme.of(context);
        final colors = theme.colorScheme;

        final dark = theme.brightness == Brightness.dark;

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            foregroundColor: colors.onSurface,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            title: Text(
              _tr('Privacidade', 'Privacy', 'Privacidad'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Expanded(
                    child: _carregando
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: primaryPurple,
                            ),
                          )
                        : ListView(
                            children: [
                              // CONFIGURAÇÕES DE PRIVACIDADE
                              Container(
                                decoration: BoxDecoration(
                                  color: colors.surface,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: colors.outlineVariant,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.04,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    _buildSwitch(
                                      title: _tr(
                                        'Perfil visível',
                                        'Visible profile',
                                        'Perfil visible',
                                      ),
                                      subtitle: _tr(
                                        'Permite que outros usuários vejam seu perfil.',
                                        'Allow other users to view your profile.',
                                        'Permite que otros usuarios vean tu perfil.',
                                      ),
                                      value: profileVisible,
                                      textColor: colors.onSurface,
                                      subtitleColor: colors.onSurfaceVariant,
                                      onChanged: (value) {
                                        setState(() {
                                          profileVisible = value;
                                        });
                                      },
                                    ),

                                    const Divider(height: 1),

                                    _buildSwitch(
                                      title: _tr(
                                        'Mostrar progresso',
                                        'Show progress',
                                        'Mostrar progreso',
                                      ),
                                      subtitle: _tr(
                                        'Permite que outros usuários vejam seu progresso.',
                                        'Allow other users to view your progress.',
                                        'Permite que otros usuarios vean tu progreso.',
                                      ),
                                      value: showProgress,
                                      textColor: colors.onSurface,
                                      subtitleColor: colors.onSurfaceVariant,
                                      onChanged: (value) {
                                        setState(() {
                                          showProgress = value;
                                        });
                                      },
                                    ),

                                    const Divider(height: 1),

                                    _buildSwitch(
                                      title: _tr(
                                        'Dados de uso',
                                        'Usage data',
                                        'Datos de uso',
                                      ),
                                      subtitle: _tr(
                                        'Autorizar o uso de dados de utilização para melhorar o aplicativo.',
                                        'Allow usage data to help improve the app.',
                                        'Permitir el uso de datos de uso para mejorar la aplicación.',
                                      ),
                                      value: usageData,
                                      textColor: colors.onSurface,
                                      subtitleColor: colors.onSurfaceVariant,
                                      onChanged: (value) {
                                        setState(() {
                                          usageData = value;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 24),

                              // INFORMAÇÕES DE PRIVACIDADE
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: dark
                                      ? const Color(0xFF302747)
                                      : const Color(0xFFF3F0FF),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.shield_outlined,
                                      color: primaryPurple,
                                      size: 28,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _tr(
                                              'Controle seus dados',
                                              'Control your data',
                                              'Controla tus datos',
                                            ),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: primaryPurple,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _tr(
                                              'Escolha suas preferências de privacidade. Algumas opções dependem das funcionalidades de compartilhamento do aplicativo.',
                                              'Choose your privacy preferences. Some options depend on the app’s sharing features.',
                                              'Elige tus preferencias de privacidad. Algunas opciones dependen de las funciones para compartir de la aplicación.',
                                            ),
                                            style: TextStyle(
                                              fontSize: 12,
                                              height: 1.4,
                                              color: colors.onSurface,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                  ),

                  const SizedBox(height: 16),

                  // SALVAR
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _carregando || _salvando ? null : _salvar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryPurple,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: primaryPurple.withValues(
                          alpha: 0.5,
                        ),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _salvando
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
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'banco_de_dados/auth_helper.dart';
import 'banco_de_dados/sql_helper.dart';
import 'language_controller.dart';

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() =>
      _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState
    extends State<NotificationsSettingsScreen> {
  static const Color primaryPurple = Color(0xFF6C4DFF);

  bool studyReminder = true;
  bool newDecks = true;
  bool reviewCompleted = true;
  bool dailyTips = false;

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
    return 'studycards_notifications_${id ?? 'guest'}_$nome';
  }

  @override
  void initState() {
    super.initState();
    _carrega();
  }

  Future<void> _carrega() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      bool lembrete =
          prefs.getBool(_chavePreferencia('study_reminder')) ?? true;

      final novosDecks = prefs.getBool(_chavePreferencia('new_decks')) ?? true;

      final revisaoConcluida =
          prefs.getBool(_chavePreferencia('review_completed')) ?? true;

      final dicasDiarias =
          prefs.getBool(_chavePreferencia('daily_tips')) ?? false;

      final id = Sessao.usuarioId;

      if (id != null) {
        final usuarios = await SQLHelper.pegaUmUsuario(id);

        if (usuarios.isNotEmpty) {
          final valor = usuarios.first['notify_study_reminder'];

          if (valor != null) {
            lembrete = valor == 1 || valor == true;
          }
        }
      }

      if (!mounted) return;

      setState(() {
        studyReminder = lembrete;
        newDecks = novosDecks;
        reviewCompleted = revisaoConcluida;
        dailyTips = dicasDiarias;
        _carregando = false;
      });
    } catch (e) {
      debugPrint('Erro ao carregar notificações: $e');

      if (!mounted) return;

      setState(() {
        _carregando = false;
      });

      _mostrarMensagem(
        _tr(
          'Não foi possível carregar todas as preferências.',
          'Could not load all preferences.',
          'No se pudieron cargar todas las preferencias.',
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

      // Mantém a preferência original no SQLite.
      if (id != null) {
        await SQLHelper.atualizaPreferenciasUsuario(
          id,
          lembreteEstudo: studyReminder,
        );
      }

      // Persiste as demais preferências sem alterar
      // a estrutura existente do banco de dados.
      final prefs = await SharedPreferences.getInstance();

      final resultados = await Future.wait([
        prefs.setBool(_chavePreferencia('study_reminder'), studyReminder),
        prefs.setBool(_chavePreferencia('new_decks'), newDecks),
        prefs.setBool(_chavePreferencia('review_completed'), reviewCompleted),
        prefs.setBool(_chavePreferencia('daily_tips'), dailyTips),
      ]);

      if (resultados.any((salvou) => !salvou)) {
        throw StateError('Falha ao salvar preferências locais.');
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _tr(
              'Preferências salvas com sucesso!',
              'Preferences saved successfully!',
              '¡Preferencias guardadas correctamente!',
            ),
          ),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      debugPrint('Erro ao salvar notificações: $e');

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

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            foregroundColor: colors.onSurface,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            title: Text(
              _tr('Notificações', 'Notifications', 'Notificaciones'),
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
                        : SingleChildScrollView(
                            child: Container(
                              decoration: BoxDecoration(
                                color: colors.surface,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: colors.outlineVariant,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildSwitch(
                                    title: _tr(
                                      'Lembrete de estudo',
                                      'Study reminder',
                                      'Recordatorio de estudio',
                                    ),
                                    subtitle: _tr(
                                      'Receba lembretes para revisar seus decks.',
                                      'Receive reminders to review your decks.',
                                      'Recibe recordatorios para repasar tus mazos.',
                                    ),
                                    value: studyReminder,
                                    textColor: colors.onSurface,
                                    subtitleColor: colors.onSurfaceVariant,
                                    onChanged: (value) {
                                      setState(() {
                                        studyReminder = value;
                                      });
                                    },
                                  ),

                                  const Divider(height: 1),

                                  _buildSwitch(
                                    title: _tr(
                                      'Novos decks',
                                      'New decks',
                                      'Nuevos mazos',
                                    ),
                                    subtitle: _tr(
                                      'Seus decks foram atualizados.',
                                      'Your decks have been updated.',
                                      'Tus mazos se han actualizado.',
                                    ),
                                    value: newDecks,
                                    textColor: colors.onSurface,
                                    subtitleColor: colors.onSurfaceVariant,
                                    onChanged: (value) {
                                      setState(() {
                                        newDecks = value;
                                      });
                                    },
                                  ),

                                  const Divider(height: 1),

                                  _buildSwitch(
                                    title: _tr(
                                      'Revisão concluída',
                                      'Review completed',
                                      'Repaso completado',
                                    ),
                                    subtitle: _tr(
                                      'Receba um resumo do seu desempenho.',
                                      'Receive a summary of your performance.',
                                      'Recibe un resumen de tu rendimiento.',
                                    ),
                                    value: reviewCompleted,
                                    textColor: colors.onSurface,
                                    subtitleColor: colors.onSurfaceVariant,
                                    onChanged: (value) {
                                      setState(() {
                                        reviewCompleted = value;
                                      });
                                    },
                                  ),

                                  const Divider(height: 1),

                                  _buildSwitch(
                                    title: _tr(
                                      'Dicas do dia',
                                      'Daily tips',
                                      'Consejos del día',
                                    ),
                                    subtitle: _tr(
                                      'Dicas e conteúdos para melhorar seus estudos.',
                                      'Tips and content to improve your studies.',
                                      'Consejos y contenido para mejorar tus estudios.',
                                    ),
                                    value: dailyTips,
                                    textColor: colors.onSurface,
                                    subtitleColor: colors.onSurfaceVariant,
                                    onChanged: (value) {
                                      setState(() {
                                        dailyTips = value;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ),

                  const SizedBox(height: 16),

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

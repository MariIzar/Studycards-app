import 'package:flutter/material.dart';

import 'language_controller.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const lightPurple = Color(0xFF8C7CFF);

    final tema = Theme.of(context);
    final cores = tema.colorScheme;

    final corTexto = cores.onSurface;
    final corSecundaria = cores.onSurfaceVariant;

    return ValueListenableBuilder<Locale>(
      valueListenable: LanguageController.locale,
      builder: (context, idiomaAtual, child) {
        String traduzir(String pt, String en, String es) {
          switch (idiomaAtual.languageCode) {
            case 'en':
              return en;
            case 'es':
              return es;
            default:
              return pt;
          }
        }

        return Scaffold(
          backgroundColor: tema.scaffoldBackgroundColor,
          body: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 12),

                // Cabeçalho
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(Icons.arrow_back, color: corTexto, size: 24),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text(
                          traduzir(
                            'Sobre o StudyCards',
                            'About StudyCards',
                            'Acerca de StudyCards',
                          ),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: corTexto,
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                    ],
                  ),
                ),

                // Conteúdo
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 40),

                        // Nome do aplicativo
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              color: corTexto,
                            ),
                            children: const [
                              TextSpan(text: 'Study '),
                              TextSpan(
                                text: 'Cards',
                                style: TextStyle(color: lightPurple),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Descrição
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            traduzir(
                              'O StudyCards transforma seus materiais de estudo em flashcards inteligentes utilizando inteligência artificial e repetição espaçada.',
                              'StudyCards transforms your study materials into smart flashcards using artificial intelligence and spaced repetition.',
                              'StudyCards transforma tus materiales de estudio en tarjetas inteligentes mediante inteligencia artificial y repetición espaciada.',
                            ),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: corSecundaria,
                              height: 1.4,
                            ),
                          ),
                        ),

                        const SizedBox(height: 36),

                        _buildCard(
                          context: context,
                          icon: Icons.psychology_outlined,
                          title: traduzir(
                            'Inteligência Artificial',
                            'Artificial Intelligence',
                            'Inteligencia Artificial',
                          ),
                          description: traduzir(
                            'Geração automática de flashcards a partir de seu material.',
                            'Automatically generate flashcards from your study materials.',
                            'Generación automática de tarjetas a partir de tus materiales.',
                          ),
                        ),

                        const SizedBox(height: 16),

                        _buildCard(
                          context: context,
                          icon: Icons.access_time_rounded,
                          title: traduzir(
                            'Revisão Inteligente',
                            'Smart Review',
                            'Repaso Inteligente',
                          ),
                          description: traduzir(
                            'Repetição espaçada para maximizar sua retenção de conteúdo.',
                            'Spaced repetition to maximize knowledge retention.',
                            'Repetición espaciada para maximizar la retención de conocimientos.',
                          ),
                        ),

                        const SizedBox(height: 16),

                        _buildCard(
                          context: context,
                          icon: Icons.bar_chart_rounded,
                          title: traduzir(
                            'Seu progresso',
                            'Your Progress',
                            'Tu progreso',
                          ),
                          description: traduzir(
                            'Acompanhe estatísticas e evolua todos os dias.',
                            'Track your statistics and improve every day.',
                            'Consulta tus estadísticas y mejora cada día.',
                          ),
                        ),

                        const SizedBox(height: 36),

                        Text(
                          traduzir(
                            'Versão 1.0.0',
                            'Version 1.0.0',
                            'Versión 1.0.0',
                          ),
                          style: TextStyle(fontSize: 13, color: corSecundaria),
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
  }) {
    final cores = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: cores.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cores.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: cores.shadow.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8, right: 14),
            child: Icon(icon, size: 26, color: cores.primary),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: cores.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: cores.onSurfaceVariant,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

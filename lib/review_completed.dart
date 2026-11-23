import 'package:flutter/material.dart';

import 'language_controller.dart';

class ReviewCompletedScreen extends StatelessWidget {
  const ReviewCompletedScreen({super.key});

  static const Color primaryPurple = Color(0xFF6C4DFF);

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

  int _getInt(Map<String, dynamic> data, String key) {
    final value = data[key];

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _formatDuration(int totalSeconds) {
    final duration = Duration(seconds: totalSeconds < 0 ? 0 : totalSeconds);

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}min';
    }

    if (minutes > 0) {
      return '${minutes}min ${seconds}s';
    }

    return '${seconds}s';
  }

  Widget _buildStatCard({
    required String value,
    required String label,
    required Color color,
    required IconData icon,
    required Color surface,
    required Color secondary,
    required Color border,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 26),

          const SizedBox(height: 8),

          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: secondary),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, int value, Color color, Color text) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: Text(label, style: TextStyle(fontSize: 14, color: text)),
        ),

        Text(
          '$value',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: text,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LanguageController.locale,
      builder: (context, locale, child) {
        final dark = Theme.of(context).brightness == Brightness.dark;

        final background = dark
            ? const Color(0xFF141320)
            : const Color(0xFFF8F7FF);

        final surface = dark ? const Color(0xFF242333) : Colors.white;

        final text = dark ? Colors.white : const Color(0xFF191B31);

        final secondary = dark ? Colors.white60 : const Color(0xFF73798B);

        final border = dark ? const Color(0xFF454357) : const Color(0xFFE7E5F2);

        final highlight = dark
            ? const Color(0xFF302747)
            : const Color(0xFFF0ECFF);

        // Dados enviados pela StudyScreen.
        final arguments = ModalRoute.of(context)?.settings.arguments;

        final Map<String, dynamic> data = {};

        if (arguments is Map) {
          for (final entry in arguments.entries) {
            if (entry.key is String) {
              data[entry.key as String] = entry.value;
            }
          }
        }

        final totalCards = _getInt(data, 'totalCards');

        final correctAnswers = _getInt(data, 'correctAnswers');

        final difficultAnswers = _getInt(data, 'difficultAnswers');

        final wrongAnswers = _getInt(data, 'wrongAnswers');

        final easyAnswers = _getInt(data, 'easyAnswers');

        final veryEasyAnswers = _getInt(data, 'veryEasyAnswers');

        final durationSeconds = _getInt(data, 'durationSeconds');

        // Total de avaliações realmente registradas.
        final totalReviewed =
            wrongAnswers + difficultAnswers + easyAnswers + veryEasyAnswers;

        // Avaliações positivas = fácil + muito fácil.
        final positiveAnswers = easyAnswers + veryEasyAnswers;

        final successPercentage = totalReviewed == 0
            ? 0
            : ((positiveAnswers / totalReviewed) * 100).round().clamp(0, 100);

        return Scaffold(
          backgroundColor: background,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 30),

                  // ÍCONE DE CONCLUSÃO
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: highlight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: primaryPurple,
                      size: 52,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // TÍTULO
                  Text(
                    _tr(
                      'Revisão concluída!',
                      'Review completed!',
                      '¡Repaso completado!',
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: text,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // QUANTIDADE DE CARDS
                  Text(
                    _tr(
                      '$totalReviewed ${totalReviewed == 1 ? 'card revisado' : 'cards revisados'}',
                      '$totalReviewed ${totalReviewed == 1 ? 'card reviewed' : 'cards reviewed'}',
                      '$totalReviewed ${totalReviewed == 1 ? 'tarjeta repasada' : 'tarjetas repasadas'}',
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: primaryPurple,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // PORCENTAGEM DE RESPOSTAS POSITIVAS
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: highlight,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$successPercentage%',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: primaryPurple,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          _tr(
                            'Respostas fáceis ou muito fáceis',
                            'Easy or very easy answers',
                            'Respuestas fáciles o muy fáciles',
                          ),
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: secondary),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ESTATÍSTICAS
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          value: '$correctAnswers',
                          label: _tr('Fáceis', 'Easy', 'Fáciles'),
                          color: Colors.green,
                          icon: Icons.check_circle_outline,
                          surface: surface,
                          secondary: secondary,
                          border: border,
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: _buildStatCard(
                          value: '$difficultAnswers',
                          label: _tr('Difíceis', 'Hard', 'Difíciles'),
                          color: Colors.orange,
                          icon: Icons.psychology_outlined,
                          surface: surface,
                          secondary: secondary,
                          border: border,
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: _buildStatCard(
                          value: '$wrongAnswers',
                          label: _tr('Erros', 'Incorrect', 'Errores'),
                          color: Colors.redAccent,
                          icon: Icons.cancel_outlined,
                          surface: surface,
                          secondary: secondary,
                          border: border,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // RESUMO DAS AVALIAÇÕES
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: border),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _tr(
                            'Resumo das avaliações',
                            'Review summary',
                            'Resumen de evaluaciones',
                          ),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: text,
                          ),
                        ),

                        const SizedBox(height: 16),

                        _buildSummaryRow(
                          _tr('Errei', 'Again', 'Fallé'),
                          wrongAnswers,
                          Colors.redAccent,
                          text,
                        ),

                        const SizedBox(height: 10),

                        _buildSummaryRow(
                          _tr('Difícil', 'Hard', 'Difícil'),
                          difficultAnswers,
                          Colors.orange,
                          text,
                        ),

                        const SizedBox(height: 10),

                        _buildSummaryRow(
                          _tr('Fácil', 'Easy', 'Fácil'),
                          easyAnswers,
                          primaryPurple,
                          text,
                        ),

                        const SizedBox(height: 10),

                        _buildSummaryRow(
                          _tr('Muito fácil', 'Very easy', 'Muy fácil'),
                          veryEasyAnswers,
                          Colors.green,
                          text,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // TEMPO DE ESTUDO
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        color: secondary,
                        size: 20,
                      ),

                      const SizedBox(width: 8),

                      Text(
                        _formatDuration(durationSeconds),
                        style: TextStyle(
                          fontSize: 15,
                          color: secondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // VOLTAR PARA HOME
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryPurple,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(52),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/home',
                        (route) => false,
                      );
                    },
                    child: Text(
                      _tr(
                        'Voltar para Home',
                        'Back to Home',
                        'Volver al inicio',
                      ),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

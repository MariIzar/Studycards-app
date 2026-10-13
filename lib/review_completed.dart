import 'package:flutter/material.dart';

class ReviewCompletedScreen extends StatelessWidget {
  const ReviewCompletedScreen({super.key});

  static const Color primaryPurple = Color(0xFF6C4DFF);
  static const Color backgroundColor = Color(0xFFF8F9FE);

  // CARD DE ESTATÍSTICA
  Widget _buildStatCard({
    required String value,
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // LINHA DO RESUMO
  Widget _buildSummaryRow(String label, int value, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ),
        Text(
          '$value',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  // FORMATAR O TEMPO DE ESTUDO
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

  @override
  Widget build(BuildContext context) {
    // RECEBE OS DADOS DA TELA DE REVISÃO
    final arguments = ModalRoute.of(context)?.settings.arguments;

    final Map<String, dynamic> data = arguments is Map
        ? Map<String, dynamic>.from(arguments)
        : <String, dynamic>{};

    // CONVERTE OS VALORES PARA INTEIRO
    int getInt(String key) {
      final value = data[key];

      if (value is num) {
        return value.toInt();
      }

      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    // ESTATÍSTICAS REAIS
    final totalCards = getInt('totalCards');
    final correctAnswers = getInt('correctAnswers');
    final difficultAnswers = getInt('difficultAnswers');
    final wrongAnswers = getInt('wrongAnswers');
    final easyAnswers = getInt('easyAnswers');
    final veryEasyAnswers = getInt('veryEasyAnswers');
    final durationSeconds = getInt('durationSeconds');

    // PORCENTAGEM DE RESPOSTAS FÁCEIS
    final successPercentage = totalCards == 0
        ? 0
        : ((correctAnswers / totalCards) * 100).round();

    return Scaffold(
      backgroundColor: backgroundColor,

      // SINGLECHILDSCROLLVIEW EVITA OVERFLOW
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
                decoration: const BoxDecoration(
                  color: Color(0xFFECE7FF),
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
              const Text(
                'Revisão concluída!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 8),

              // QUANTIDADE DE CARDS
              Text(
                '$totalCards ${totalCards == 1 ? 'card revisado' : 'cards revisados'}',
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
                  color: const Color(0xFFF0ECFF),
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
                    const Text(
                      'Respostas fáceis ou muito fáceis',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Colors.black54),
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
                      label: 'Fáceis',
                      color: Colors.green,
                      icon: Icons.check_circle_outline,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: _buildStatCard(
                      value: '$difficultAnswers',
                      label: 'Difíceis',
                      color: Colors.orange,
                      icon: Icons.psychology_outlined,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: _buildStatCard(
                      value: '$wrongAnswers',
                      label: 'Erros',
                      color: Colors.redAccent,
                      icon: Icons.cancel_outlined,
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Resumo das avaliações',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 16),

                    _buildSummaryRow('Errei', wrongAnswers, Colors.redAccent),

                    const SizedBox(height: 10),

                    _buildSummaryRow(
                      'Difícil',
                      difficultAnswers,
                      Colors.orange,
                    ),

                    const SizedBox(height: 10),

                    _buildSummaryRow('Fácil', easyAnswers, primaryPurple),

                    const SizedBox(height: 10),

                    _buildSummaryRow(
                      'Muito fácil',
                      veryEasyAnswers,
                      Colors.green,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // TEMPO DE ESTUDO
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.access_time_rounded,
                    color: Colors.grey,
                    size: 20,
                  ),

                  const SizedBox(width: 8),

                  Text(
                    _formatDuration(durationSeconds),
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // BOTÃO VOLTAR PARA HOME
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
                child: const Text(
                  'Voltar para Home',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

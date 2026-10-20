import 'package:flutter/material.dart';

import 'banco_de_dados/auth_helper.dart';
import 'banco_de_dados/sql_helper.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  static const Color primaryPurple = Color(0xFF6C4DFF);
  static const Color backgroundColor = Color(0xFFF8F9FE);

  bool isLoading = true;
  String? errorMessage;

  int totalCards = 0;
  int reviewedCards = 0;
  int masteredCards = 0;
  int pendingCards = 0;
  double masteryPercentage = 0;

  List<Map<String, dynamic>> deckProgress = [];

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  int _toInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  // CARREGA DADOS REAIS DO SQLITE
  Future<void> _loadProgress() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

    try {
      final stats = await SQLHelper.pegaEstatisticas(
        usuarioId: Sessao.usuarioId,
      );
      final database = await SQLHelper.db();

      // DESEMPENHO POR DECK / MATÉRIA
      final decks = await database.rawQuery('''
        SELECT
          d.id,
          d.title,
          COUNT(f.id) AS total_cards,
          COALESCE(SUM(
            CASE
              WHEN f.is_mastered = 1 THEN 1
              ELSE 0
            END
          ), 0) AS mastered_cards
        FROM decks d
        LEFT JOIN flashcards f ON f.deck_id = d.id
        WHERE d.user_id = ?
        GROUP BY d.id, d.title
        ORDER BY d.title COLLATE NOCASE
      ''', [Sessao.usuarioId]);

      final progressList = decks.map((deck) {
        final total = _toInt(deck['total_cards']);
        final mastered = _toInt(deck['mastered_cards']);

        return <String, dynamic>{
          'title': deck['title']?.toString() ?? 'Sem nome',
          'total': total,
          'mastered': mastered,
          'percentage': total == 0 ? 0.0 : mastered / total,
        };
      }).toList();

      if (!mounted) return;

      setState(() {
        totalCards = _toInt(stats['total_cards']);
        reviewedCards = _toInt(stats['total_cards_reviewed']);
        masteredCards = _toInt(stats['mastered_cards']);
        pendingCards = _toInt(stats['pending_cards']);

        masteryPercentage =
            (stats['mastery_percentage'] as num?)?.toDouble() ?? 0;

        deckProgress = progressList;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = 'Não foi possível carregar o progresso: $e';
      });
    }
  }

  // CARDS LATERAIS
  Widget _buildMetricCard({required String title, required String value}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // GRÁFICO CIRCULAR DE DOMÍNIO
  Widget _buildCircularProgress() {
    final percentage = masteryPercentage.clamp(0.0, 100.0).toDouble();

    return SizedBox(
      width: 130,
      height: 130,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 130,
            height: 130,
            child: CircularProgressIndicator(
              value: percentage / 100,
              strokeWidth: 15,
              strokeCap: StrokeCap.round,
              backgroundColor: const Color(0xFFEBEBF5),
              valueColor: const AlwaysStoppedAnimation<Color>(primaryPurple),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${percentage.round()}%',
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Text(
                'Dominados',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // BARRA DE PROGRESSO POR MATÉRIA
  Widget _buildSubjectProgress(Map<String, dynamic> deck) {
    final title = deck['title'] as String;
    final total = deck['total'] as int;
    final mastered = deck['mastered'] as int;
    final percentage = deck['percentage'] as double;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${(percentage * 100).round()}%',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: percentage.clamp(0.0, 1.0).toDouble(),
            minHeight: 10,
            backgroundColor: const Color(0xFFEBEBF5),
            valueColor: const AlwaysStoppedAnimation<Color>(primaryPurple),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$mastered de $total cards dominados',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  // NAVEGAÇÃO INFERIOR
  Widget _buildNavItem(IconData icon, String label, {bool active = false}) {
    final color = active ? primaryPurple : Colors.grey;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.pushReplacementNamed(context, '/home');
            },
            child: _buildNavItem(Icons.home_outlined, 'Início'),
          ),
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/decks');
            },
            child: _buildNavItem(Icons.style_outlined, 'Decks'),
          ),
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/create-flashcards');
            },
            child: Container(
              width: 54,
              height: 54,
              decoration: const BoxDecoration(
                color: primaryPurple,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            ),
          ),
          _buildNavItem(Icons.bar_chart_rounded, 'Progresso', active: true),
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/profile');
            },
            child: _buildNavItem(Icons.person_outline, 'Perfil'),
          ),
        ],
      ),
    );
  }

  // CONTEÚDO PRINCIPAL
  Widget _buildContent() {
    return RefreshIndicator(
      color: primaryPurple,
      onRefresh: _loadProgress,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        children: [
          const SizedBox(height: 10),

          Row(
            children: [
              const Expanded(
                child: Text(
                  'Seu progresso',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Atualizar progresso',
                onPressed: _loadProgress,
                icon: const Icon(Icons.refresh_rounded, color: primaryPurple),
              ),
            ],
          ),

          const SizedBox(height: 8),

          const Text(
            'Acompanhe sua evolução nos estudos.',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),

          const SizedBox(height: 28),

          // GRÁFICO CIRCULAR + MÉTRICAS
          Row(
            children: [
              _buildCircularProgress(),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    _buildMetricCard(
                      title: 'Revisões realizadas',
                      value: '$reviewedCards',
                    ),
                    const SizedBox(height: 12),
                    _buildMetricCard(
                      title: 'Cards criados',
                      value: '$totalCards',
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // MAIS ESTATÍSTICAS
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'Cards dominados',
                  value: '$masteredCards',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  title: 'Pendentes',
                  value: '$pendingCards',
                ),
              ),
            ],
          ),

          const SizedBox(height: 36),

          const Text(
            'Desempenho por matéria',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Porcentagem de flashcards dominados em cada deck.',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),

          const SizedBox(height: 16),

          // BARRAS DINÂMICAS DOS DECKS
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: deckProgress.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      children: [
                        Icon(
                          Icons.auto_stories_outlined,
                          color: Colors.grey,
                          size: 38,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Nenhuma matéria cadastrada.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Crie um deck para acompanhar seu progresso.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      for (int i = 0; i < deckProgress.length; i++) ...[
                        _buildSubjectProgress(deckProgress[i]),
                        if (i < deckProgress.length - 1)
                          const SizedBox(height: 22),
                      ],
                    ],
                  ),
          ),

          const SizedBox(height: 24),

          const Text(
            'O progresso é calculado com base nas avaliações '
            'registradas e no algoritmo de repetição espaçada.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: primaryPurple),
                    )
                  : errorMessage != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(errorMessage!, textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadProgress,
                              child: const Text('Tentar novamente'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _buildContent(),
            ),

            // BARRA INFERIOR FIXA
            _buildBottomNavigation(),
          ],
        ),
      ),
    );
  }
}

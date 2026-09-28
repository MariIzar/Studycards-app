import 'package:flutter/material.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryPurple = Color(0xFF6C4DFF);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 20.0,
                ),
                children: [
                  const SizedBox(height: 10),
                  const Text(
                    'Seu progresso',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Seção do Gráfico Circular + Cards Informativos
                  Row(
                    children: [
                      // Gráfico circular com valor percentual no centro
                      SizedBox(
                        width: 130,
                        height: 130,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 130,
                              height: 130,
                              child: CircularProgressIndicator(
                                value: 0.78,
                                strokeWidth: 16,
                                backgroundColor: const Color(0xFFEBEBF5),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  primaryPurple,
                                ),
                              ),
                            ),
                            const Text(
                              '78%',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),

                      // Blocos laterais (Tempo de estudo & Cards revisados)
                      Expanded(
                        child: Column(
                          children: [
                            _buildMetricCard(
                              title: 'Tempo de estudo',
                              value: '4h 32min',
                            ),
                            const SizedBox(height: 12),
                            _buildMetricCard(
                              title: 'Cards revisados',
                              value: '126',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 36),

                  // Título Desempenho por matéria
                  const Text(
                    'Desempenho por matéria',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Container com as barras de progresso
                  Container(
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
                    child: Column(
                      children: [
                        _buildSubjectProgress('Cálculo', 0.74, '74%'),
                        const SizedBox(height: 16),
                        _buildSubjectProgress('Biologia', 0.92, '92%'),
                        const SizedBox(height: 16),
                        _buildSubjectProgress('Programação', 0.86, '86%'),
                        const SizedBox(height: 16),
                        _buildSubjectProgress('História', 0.50, '50%'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Navigation Bar Inferior Fixa
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
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

                  // Botão Central (+)
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
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),

                  // Item Progresso Ativo
                  _buildNavItem(
                    Icons.bar_chart_rounded,
                    'Progresso',
                    active: true,
                  ),

                  // Redireciona para /profile
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/profile');
                    },
                    child: _buildNavItem(Icons.person_outline, 'Perfil'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Card para métricas laterais
  Widget _buildMetricCard({required String title, required String value}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
          Text(title, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  // Progresso individual por matéria
  Widget _buildSubjectProgress(
    String subject,
    double percentage,
    String label,
  ) {
    const primaryPurple = Color(0xFF6C4DFF);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              subject,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              label,
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
            value: percentage,
            minHeight: 10,
            backgroundColor: const Color(0xFFEBEBF5),
            valueColor: const AlwaysStoppedAnimation<Color>(primaryPurple),
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem(IconData icon, String label, {bool active = false}) {
    final color = active ? const Color(0xFF6C4DFF) : Colors.grey;
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
}

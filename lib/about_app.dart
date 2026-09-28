import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const lightPurple = Color(0xFF8C7CFF);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),

            // Topo: Seta de voltar e Título centralizado
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.black,
                      size: 24,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'Sobre o StudyCards',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 24,
                  ), // Equilibra o alinhamento com a seta
                ],
              ),
            ),

            // Conteúdo principal
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 40),

                    // Logo: Study Cards
                    RichText(
                      textAlign: TextAlign.center,
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                        children: [
                          TextSpan(text: 'Study '),
                          TextSpan(
                            text: 'Cards',
                            style: TextStyle(color: lightPurple),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Texto descritivo centralizado
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12.0),
                      child: Text(
                        'O StudyCards transforma seus materiais de estudo em flashcards inteligentes utilizando inteligência artificial e repetição espaçada.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Card 1: IA (com ícone de chip/cerebro)
                    _buildCard(
                      icon: Icons.psychology_outlined,
                      title: 'IA',
                      description: 'Geração automática de flashcards a partir de seu material.',
                    ),
                    const SizedBox(height: 16),

                    // Card 2: Revisão Inteligente (com ícone de relógio)
                    _buildCard(
                      icon: Icons.access_time_rounded,
                      title: 'Revisão Inteligente',
                      description: 'Repetição espaçada para maximizar sua retenção de conteúdo.',
                    ),
                    const SizedBox(height: 16),

                    // Card 3: Seu progresso (com ícone de gráfico)
                    _buildCard(
                      icon: Icons.bar_chart_rounded,
                      title: 'Seu progresso',
                      description:
                          'Acompanhe estatísticas e evolua todos os dias',
                    ),
                    const SizedBox(height: 36),

                    // Versão no rodapé
                    const Text(
                      'Versão 1.0.0',
                      style: TextStyle(fontSize: 13, color: Colors.black45),
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
  }

  // Widget padronizado para os cards com ícone à esquerda
  Widget _buildCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
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
            child: Icon(icon, size: 26, color: Colors.black87),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
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

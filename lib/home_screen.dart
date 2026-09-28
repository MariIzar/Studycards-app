import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Variável para controlar qual deck da Home está selecionado com efeito roxo
  String? selectedDeckTitle;

  @override
  Widget build(BuildContext context) {
    const primaryPurple = Color(0xFF6C5CE7);
    const lightPurple = Color(0xFFDCD6FE);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: SafeArea(
        child: Column(
          children: [
            // Área de conteúdo principal rolável com ListView fluida
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(24.0),
                children: [
                  // Topo: Saudação e Ícone de Ajuda
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Olá, Barbara!',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Pronta para aprender hoje?',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.help_outline_rounded, size: 28),
                        onPressed: () {
                          Navigator.pushNamed(context, '/about');
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Card Roxo: Revisão de hoje
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: primaryPurple,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: primaryPurple.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Revisão de hoje',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '24',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'cards pendentes',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: primaryPurple,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                          ),
                          onPressed: () {
                            Navigator.pushNamed(context, '/study');
                          },
                          icon: const Text(
                            'Começar revisão',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          label: const Icon(Icons.arrow_forward, size: 18),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Seção: Seus decks
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Seus decks',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/decks');
                        },
                        child: const Text(
                          'Ver todos',
                          style: TextStyle(color: primaryPurple),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Lista de Decks interativos
                  _buildInteractiveDeckCard(
                    title: 'Cálculo',
                    cardsCount: '24 cards',
                    onTap: () {
                      Navigator.pushNamed(context, '/deck-details');
                    },
                  ),
                  _buildInteractiveDeckCard(
                    title: 'Biologia',
                    cardsCount: '17 cards',
                  ),
                  _buildInteractiveDeckCard(
                    title: 'Programação',
                    cardsCount: '38 cards',
                  ),
                  const SizedBox(height: 20),

                  // Card de Progresso
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/progress');
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: lightPurple,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Seu progresso',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '78%',
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'dos seus cards dominados',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
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
                  _buildNavItem(Icons.home, 'Início', active: true),

                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/decks');
                    },
                    child: _buildNavItem(Icons.style_outlined, 'Decks'),
                  ),

                  // Botão central (+)
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

                  // Botão Progresso
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/progress');
                    },
                    child: _buildNavItem(Icons.bar_chart_outlined, 'Progresso'),
                  ),

                  // Botão Perfil
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

  Widget _buildInteractiveDeckCard({
    required String title,
    required String cardsCount,
    VoidCallback? onTap,
  }) {
    final bool isSelected = selectedDeckTitle == title;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedDeckTitle = isSelected ? null : title;
        });
        if (onTap != null) {
          onTap();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF3F0FF) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF6C5CE7) : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFF6C5CE7).withOpacity(0.15)
                  : Colors.black.withOpacity(0.03),
              blurRadius: isSelected ? 12 : 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? const Color(0xFF6C5CE7) : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  cardsCount,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
            Icon(
              Icons.chevron_right,
              color: isSelected ? const Color(0xFF6C5CE7) : Colors.black54,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, {bool active = false}) {
    final color = active ? const Color(0xFF6C5CE7) : Colors.grey;
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

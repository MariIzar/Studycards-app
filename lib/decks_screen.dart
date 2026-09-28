import 'package:flutter/material.dart';

class DecksScreen extends StatefulWidget {
  const DecksScreen({super.key});

  @override
  State<DecksScreen> createState() => _DecksScreenState();
}

class _DecksScreenState extends State<DecksScreen> {
  // Variável para guardar qual deck foi selecionado por último
  String? selectedCardTitle;

  @override
  Widget build(BuildContext context) {
    const primaryPurple = Color(0xFF6C5CE7);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
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
                      const SizedBox(width: 16),
                      const Text(
                        'Meus decks',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(
                      Icons.search,
                      color: Colors.black,
                      size: 26,
                    ),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 12.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Seus materiais de estudo',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Organize seus flashcards por matérias.',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 20),

                    // Lista de Decks com navegação para os detalhes do deck
                    _buildDeckItem(
                      title: 'Cálculo',
                      cardsCount: '24 cards',
                      onTap: () {
                        Navigator.pushNamed(context, '/deck-details');
                      },
                    ),
                    _buildDeckItem(
                      title: 'Biologia',
                      cardsCount: '38 cards',
                      onTap: () {
                        Navigator.pushNamed(context, '/deck-details');
                      },
                    ),
                    _buildDeckItem(
                      title: 'Programação',
                      cardsCount: '17 cards',
                      onTap: () {
                        Navigator.pushNamed(context, '/deck-details');
                      },
                    ),
                    _buildDeckItem(
                      title: 'Inglês',
                      cardsCount: '22 cards',
                      onTap: () {
                        Navigator.pushNamed(context, '/deck-details');
                      },
                    ),
                    _buildDeckItem(
                      title: 'Física',
                      cardsCount: '31 cards',
                      onTap: () {
                        Navigator.pushNamed(context, '/deck-details');
                      },
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryPurple,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pushNamed(context, '/create-deck');
                        },
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Criar novo deck',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Barra inferior
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
                  InkWell(
                    onTap: () =>
                        Navigator.pushReplacementNamed(context, '/home'),
                    child: _buildNavItem(Icons.home_outlined, 'Início'),
                  ),
                  _buildNavItem(Icons.style, 'Decks', active: true),
                  GestureDetector(
                    onTap: () =>
                        Navigator.pushNamed(context, '/create-flashcards'),
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
                  InkWell(
                    onTap: () =>
                        Navigator.pushReplacementNamed(context, '/progress'),
                    child: _buildNavItem(Icons.bar_chart_outlined, 'Progresso'),
                  ),
                  InkWell(
                    onTap: () =>
                        Navigator.pushReplacementNamed(context, '/profile'),
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

  // Deck item com efeito visual de seleção e ação de clique
  Widget _buildDeckItem({
    required String title,
    required String cardsCount,
    VoidCallback? onTap,
  }) {
    final bool isSelected = selectedCardTitle == title;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCardTitle = isSelected ? null : title;
        });
        if (onTap != null) {
          onTap();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                  : Colors.black.withOpacity(0.02),
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
              size: 22,
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

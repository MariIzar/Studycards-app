import 'package:flutter/material.dart';

import 'banco_de_dados/auth_helper.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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
                padding: const EdgeInsets.all(24.0),
                children: [
                  const SizedBox(height: 10),

                  // Cabeçalho de Usuário (Avatar "B" + Nome/Cargo)
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: primaryPurple,
                        child: Text(
                          Sessao.inicial,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                       child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            Sessao.nome,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            Sessao.ocupacao,
                            style: const TextStyle(
                                fontSize: 15, color: Colors.grey),
                          ),
                        ],
                       ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Lista de opções em cards separados
                  // Ajustado para abrir a tela geral de Configurações (/settings)
                  _buildMenuCard(
                    icon: Icons.settings_outlined,
                    title: 'Configurações',
                    onTap: () => Navigator.pushNamed(context, '/settings'),
                  ),
                  const SizedBox(height: 12),
                  _buildMenuCard(
                    icon: Icons.notifications_none_rounded,
                    title: 'Notificações',
                    onTap: () =>
                        Navigator.pushNamed(context, '/notifications-settings'),
                  ),
                  const SizedBox(height: 12),
                  _buildMenuCard(
                    icon: Icons.menu_book_outlined,
                    title: 'Meus decks',
                    onTap: () => Navigator.pushNamed(context, '/decks'),
                  ),
                  const SizedBox(height: 12),
                  _buildMenuCard(
                    icon: Icons.bar_chart_rounded,
                    title: 'Meu progresso',
                    onTap: () => Navigator.pushNamed(context, '/progress'),
                  ),
                  const SizedBox(height: 12),
                  _buildMenuCard(
                    icon: Icons.info_outline_rounded,
                    title: 'Sobre o StudyCards',
                    onTap: () => Navigator.pushNamed(context, '/about'),
                  ),
                  const SizedBox(height: 24),

                  // Botão Sair da conta estilizado
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                      side: const BorderSide(color: primaryPurple, width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () async {
                      await AuthHelper.sair();
                      if (!context.mounted) return;
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/visitor-profile',
                        (route) => false,
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          'Sair da conta',
                          style: TextStyle(
                            color: Color(
                              0xFFE53935,
                            ), // Tom avermelhado elegante
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.chevron_right,
                          color: Color(0xFFE53935),
                          size: 20,
                        ),
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
                    onTap: () =>
                        Navigator.pushReplacementNamed(context, '/home'),
                    child: _buildNavItem(Icons.home_outlined, 'Início'),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/decks'),
                    child: _buildNavItem(Icons.style_outlined, 'Decks'),
                  ),

                  // Botão Central (+)
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

                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/progress'),
                    child: _buildNavItem(Icons.bar_chart_outlined, 'Progresso'),
                  ),

                  // Item Perfil Ativo
                  _buildNavItem(Icons.person_outline, 'Perfil', active: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget para os cards de menu individuais com sombra leve
  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Icon(icon, size: 22, color: Colors.black87),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: Colors.black45,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, {bool active = false}) {
    const primaryPurple = Color(0xFF6C4DFF);
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
}

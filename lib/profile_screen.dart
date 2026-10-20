import 'package:flutter/material.dart';

import 'banco_de_dados/auth_helper.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Abre o login e atualiza o perfil quando a pessoa voltar logada.
  Future<void> _fazerLogin() async {
    await Navigator.pushNamed(context, '/login');
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final logado = Sessao.logado;
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

                  // Cabeçalho (usuário logado ou visitante)
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: primaryPurple,
                        child: logado
                            ? Text(
                                Sessao.inicial,
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.person_outline,
                                size: 36,
                                color: Colors.white,
                              ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              logado ? Sessao.nome : 'Visitante',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              logado
                                  ? Sessao.ocupacao
                                  : 'Entre para salvar seu progresso',
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Visitante: botão de login em destaque
                  if (!logado) ...[
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryPurple,
                        minimumSize: const Size.fromHeight(54),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _fazerLogin,
                      child: const Text(
                        'Fazer login',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Opções liberadas para todos
                  _buildMenuCard(
                    icon: Icons.settings_outlined,
                    title: 'Configurações',
                    onTap: () => Navigator.pushNamed(context, '/settings'),
                  ),
                  const SizedBox(height: 12),
                  _buildMenuCard(
                    icon: Icons.help_outline_rounded,
                    title: 'Ajuda e suporte',
                    onTap: () => Navigator.pushNamed(context, '/help-support'),
                  ),
                  const SizedBox(height: 12),
                  _buildMenuCard(
                    icon: Icons.info_outline_rounded,
                    title: 'Sobre o StudyCards',
                    onTap: () => Navigator.pushNamed(context, '/about'),
                  ),

                  // Opções só para quem está logado
                  if (logado) ...[
                    const SizedBox(height: 12),
                    _buildMenuCard(
                      icon: Icons.notifications_none_rounded,
                      title: 'Notificações',
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/notifications-settings',
                      ),
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
                    const SizedBox(height: 24),

                    // Botão Sair da conta
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(54),
                        side: const BorderSide(
                          color: primaryPurple,
                          width: 1.2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () async {
                        await AuthHelper.sair();
                        if (!context.mounted) return;
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/home',
                          (route) => false,
                        );
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Sair da conta',
                            style: TextStyle(
                              color: Color(0xFFE53935),
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

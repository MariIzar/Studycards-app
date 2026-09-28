import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryPurple = Color(0xFF6C4DFF);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Configurações',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          // Seção: Conta
          const Text(
            'Conta',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Container(
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
                _buildSettingItem(
                  icon: Icons.person_outline,
                  title: 'Editar perfil',
                  onTap: () => Navigator.pushNamed(context, '/edit-profile'),
                ),
                const Divider(height: 1),
                _buildSettingItem(
                  icon: Icons.lock_outline,
                  title: 'Alterar senha',
                  onTap: () => Navigator.pushNamed(context, '/change-password'),
                ),
                const Divider(height: 1),
                _buildSettingItem(
                  icon: Icons.shield_outlined,
                  title: 'Privacidade',
                  onTap: () =>
                      Navigator.pushNamed(context, '/privacy-settings'),
                ),
                const Divider(height: 1),
                _buildSettingItem(
                  icon: Icons.star_outline,
                  title: 'Assinatura',
                  onTap: () {
                    // Caso tenha tela de assinatura, pode mapear aqui
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Seção: App
          const Text(
            'App',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Container(
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
                _buildSettingItem(
                  icon: Icons.notifications_none_rounded,
                  title: 'Notificações',
                  onTap: () =>
                      Navigator.pushNamed(context, '/notifications-settings'),
                ),
                const Divider(height: 1),
                _buildSettingItem(
                  icon: Icons.wb_sunny_outlined,
                  title: 'Aparência',
                  trailingText: 'Claro',
                  onTap: () => Navigator.pushNamed(context, '/appearance'),
                ),
                const Divider(height: 1),
                _buildSettingItem(
                  icon: Icons.language_rounded,
                  title: 'Idioma',
                  trailingText: 'Português',
                  onTap: () => Navigator.pushNamed(context, '/language'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Seção: Sobre
          const Text(
            'Sobre',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Container(
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
                _buildSettingItem(
                  icon: Icons.info_outline_rounded,
                  title: 'Sobre o StudyCards',
                  onTap: () => Navigator.pushNamed(context, '/about'),
                ),
                const Divider(height: 1),
                _buildSettingItem(
                  icon: Icons.help_outline_rounded,
                  title: 'Ajuda e suporte',
                  onTap: () => Navigator.pushNamed(context, '/help-support'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    String? trailingText,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.black87, size: 22),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText != null)
            Text(
              trailingText,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, color: Colors.black45, size: 20),
        ],
      ),
      onTap: onTap,
    );
  }
}

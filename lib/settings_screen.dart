import 'package:flutter/material.dart';

import 'language_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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

  String _nomeIdioma() {
    switch (LanguageController.locale.value.languageCode) {
      case 'en':
        return 'English';
      case 'es':
        return 'Español';
      default:
        return 'Português';
    }
  }

  void _abrirRota(BuildContext context, String rota) {
    Navigator.pushNamed(context, rota);
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required Color textColor,
    required Color secondaryColor,
    required VoidCallback onTap,
    String? trailingText,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      leading: Icon(icon, color: primaryPurple, size: 23),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText != null) ...[
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 110),
              child: Text(
                trailingText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14, color: secondaryColor),
              ),
            ),
            const SizedBox(width: 4),
          ],
          Icon(Icons.chevron_right, color: secondaryColor, size: 20),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> items,
    required Color surface,
    required Color textColor,
    required Color secondaryColor,
    required Color borderColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: secondaryColor,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                items[i],
                if (i < items.length - 1)
                  Divider(
                    height: 1,
                    thickness: 0.7,
                    indent: 56,
                    endIndent: 16,
                    color: borderColor,
                  ),
              ],
            ],
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

        final textColor = dark ? Colors.white : const Color(0xFF191B31);

        final secondaryColor = dark ? Colors.white60 : const Color(0xFF73798B);

        final borderColor = dark
            ? const Color(0xFF454357)
            : const Color(0xFFE7E5F2);

        final appearance = dark
            ? _tr('Escuro', 'Dark', 'Oscuro')
            : _tr('Claro', 'Light', 'Claro');

        return Scaffold(
          backgroundColor: background,
          appBar: AppBar(
            backgroundColor: background,
            foregroundColor: textColor,
            elevation: 0,
            centerTitle: true,
            title: Text(
              _tr('Configurações', 'Settings', 'Configuración'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // CONTA
                _buildSection(
                  title: _tr('Conta', 'Account', 'Cuenta'),
                  surface: surface,
                  textColor: textColor,
                  secondaryColor: secondaryColor,
                  borderColor: borderColor,
                  items: [
                    _buildSettingItem(
                      icon: Icons.person_outline,
                      title: _tr(
                        'Editar perfil',
                        'Edit profile',
                        'Editar perfil',
                      ),
                      textColor: textColor,
                      secondaryColor: secondaryColor,
                      onTap: () => _abrirRota(context, '/edit-profile'),
                    ),
                    _buildSettingItem(
                      icon: Icons.lock_outline,
                      title: _tr(
                        'Alterar senha',
                        'Change password',
                        'Cambiar contraseña',
                      ),
                      textColor: textColor,
                      secondaryColor: secondaryColor,
                      onTap: () => _abrirRota(context, '/change-password'),
                    ),
                    _buildSettingItem(
                      icon: Icons.shield_outlined,
                      title: _tr('Privacidade', 'Privacy', 'Privacidad'),
                      textColor: textColor,
                      secondaryColor: secondaryColor,
                      onTap: () => _abrirRota(context, '/privacy-settings'),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // APP
                _buildSection(
                  title: 'App',
                  surface: surface,
                  textColor: textColor,
                  secondaryColor: secondaryColor,
                  borderColor: borderColor,
                  items: [
                    _buildSettingItem(
                      icon: Icons.notifications_none_rounded,
                      title: _tr(
                        'Notificações',
                        'Notifications',
                        'Notificaciones',
                      ),
                      textColor: textColor,
                      secondaryColor: secondaryColor,
                      onTap: () =>
                          _abrirRota(context, '/notifications-settings'),
                    ),
                    _buildSettingItem(
                      icon: Icons.wb_sunny_outlined,
                      title: _tr('Aparência', 'Appearance', 'Apariencia'),
                      trailingText: appearance,
                      textColor: textColor,
                      secondaryColor: secondaryColor,
                      onTap: () => _abrirRota(context, '/appearance'),
                    ),
                    _buildSettingItem(
                      icon: Icons.language_rounded,
                      title: _tr('Idioma', 'Language', 'Idioma'),
                      trailingText: _nomeIdioma(),
                      textColor: textColor,
                      secondaryColor: secondaryColor,
                      onTap: () => _abrirRota(context, '/language'),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // SOBRE
                _buildSection(
                  title: _tr('Sobre', 'About', 'Acerca de'),
                  surface: surface,
                  textColor: textColor,
                  secondaryColor: secondaryColor,
                  borderColor: borderColor,
                  items: [
                    _buildSettingItem(
                      icon: Icons.info_outline_rounded,
                      title: _tr(
                        'Sobre o StudyCards',
                        'About StudyCards',
                        'Acerca de StudyCards',
                      ),
                      textColor: textColor,
                      secondaryColor: secondaryColor,
                      onTap: () => _abrirRota(context, '/about'),
                    ),
                    _buildSettingItem(
                      icon: Icons.help_outline_rounded,
                      title: _tr(
                        'Ajuda e suporte',
                        'Help and support',
                        'Ayuda y soporte',
                      ),
                      textColor: textColor,
                      secondaryColor: secondaryColor,
                      onTap: () => _abrirRota(context, '/help-support'),
                    ),
                  ],
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }
}

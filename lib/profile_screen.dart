import 'package:flutter/material.dart';

import 'banco_de_dados/auth_helper.dart';
import 'language_controller.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color purple = Color(0xFF7138F5);

  bool _saindo = false;

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

  Future<void> _abrir(String rota) async {
    if (_saindo) return;

    await Navigator.pushNamed(context, rota);

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _sair() async {
    if (_saindo) return;

    setState(() {
      _saindo = true;
    });

    try {
      await AuthHelper.sair();

      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } catch (e) {
      debugPrint('Erro ao sair da conta: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _tr(
              'Não foi possível sair da conta. Tente novamente.',
              'Could not log out. Please try again.',
              'No se pudo cerrar sesión. Inténtalo de nuevo.',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saindo = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LanguageController.locale,
      builder: (context, locale, child) {
        final theme = Theme.of(context);
        final dark = theme.brightness == Brightness.dark;

        final logged = Sessao.logado;

        final bg = dark ? const Color(0xFF141320) : const Color(0xFFF8F7FF);

        final surface = dark ? const Color(0xFF242333) : Colors.white;

        final text = dark ? Colors.white : const Color(0xFF191B31);

        final muted = dark ? Colors.white60 : const Color(0xFF73798B);

        final border = dark ? Colors.white12 : const Color(0xFFE7E5F2);

        Widget menu(IconData icon, String title, String route) {
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            leading: Icon(icon, color: text, size: 21),
            title: Text(title, style: TextStyle(color: text, fontSize: 16)),
            trailing: Icon(Icons.chevron_right, color: muted),
            onTap: _saindo ? null : () => _abrir(route),
          );
        }

        Widget nav(
          IconData icon,
          String label,
          String route, {
          bool selected = false,
        }) {
          return Expanded(
            child: InkWell(
              onTap: selected || _saindo
                  ? null
                  : () {
                      if (route == '/home') {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/home',
                          (r) => false,
                        );
                      } else {
                        _abrir(route);
                      }
                    },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: selected ? purple : muted, size: 23),
                    const SizedBox(height: 3),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: selected ? purple : muted,
                        fontWeight: selected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: bg,
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(21, 0, 21, 24),
                    children: [
                      const SizedBox(height: 95),

                      // LOGO
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: Image.asset(
                            'assets/images/studycards_logo.png',
                            width: 92,
                            height: 92,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // NOME DO USUÁRIO
                      Text(
                        logged
                            ? Sessao.nome
                            : _tr(
                                'Entre no StudyCards',
                                'Log in to StudyCards',
                                'Inicia sesión en StudyCards',
                              ),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: text,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      const SizedBox(height: 6),

                      // OCUPAÇÃO OU DESCRIÇÃO
                      Text(
                        logged
                            ? Sessao.ocupacao
                            : _tr(
                                'Crie uma conta neste aparelho para\nidentificar seus estudos.',
                                'Create an account on this device to\nkeep track of your studies.',
                                'Crea una cuenta en este dispositivo para\nidentificar tus estudios.',
                              ),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: muted,
                          fontSize: 16,
                          height: 1.4,
                        ),
                      ),

                      const SizedBox(height: 34),

                      // USUÁRIO NÃO LOGADO
                      if (!logged) ...[
                        SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _saindo ? null : () => _abrir('/login'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: purple,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              _tr(
                                'Entrar na conta',
                                'Log in to account',
                                'Iniciar sesión',
                              ),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 11),

                        SizedBox(
                          height: 56,
                          child: OutlinedButton(
                            onPressed: _saindo
                                ? null
                                : () => _abrir('/register'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: dark
                                  ? const Color(0xFFB59AFF)
                                  : purple,
                              side: const BorderSide(color: purple, width: 2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              _tr(
                                'Criar minha conta',
                                'Create my account',
                                'Crear mi cuenta',
                              ),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),
                      ],

                      // CONFIGURAÇÕES E SOBRE
                      Container(
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: border),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: dark ? 0 : 0.05,
                              ),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            menu(
                              Icons.settings_outlined,
                              _tr('Configurações', 'Settings', 'Configuración'),
                              '/settings',
                            ),
                            Divider(height: 1, color: border),
                            menu(
                              Icons.info_outline,
                              _tr(
                                'Sobre o StudyCards',
                                'About StudyCards',
                                'Acerca de StudyCards',
                              ),
                              '/about',
                            ),
                          ],
                        ),
                      ),

                      // OPÇÕES DE USUÁRIO LOGADO
                      if (logged) ...[
                        const SizedBox(height: 16),

                        Container(
                          decoration: BoxDecoration(
                            color: surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: border),
                          ),
                          child: Column(
                            children: [
                              menu(
                                Icons.notifications_none,
                                _tr(
                                  'Notificações',
                                  'Notifications',
                                  'Notificaciones',
                                ),
                                '/notifications-settings',
                              ),
                              Divider(height: 1, color: border),
                              menu(
                                Icons.style_outlined,
                                _tr('Meus decks', 'My decks', 'Mis mazos'),
                                '/decks',
                              ),
                              Divider(height: 1, color: border),
                              menu(
                                Icons.bar_chart_outlined,
                                _tr(
                                  'Meu progresso',
                                  'My progress',
                                  'Mi progreso',
                                ),
                                '/progress',
                              ),
                              Divider(height: 1, color: border),
                              menu(
                                Icons.help_outline,
                                _tr(
                                  'Ajuda e suporte',
                                  'Help and support',
                                  'Ayuda y soporte',
                                ),
                                '/help-support',
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // SAIR DA CONTA
                        OutlinedButton(
                          onPressed: _saindo ? null : _sair,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                            side: const BorderSide(color: Colors.redAccent),
                          ),
                          child: _saindo
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.redAccent,
                                  ),
                                )
                              : Text(
                                  _tr(
                                    'Sair da conta',
                                    'Log out',
                                    'Cerrar sesión',
                                  ),
                                  style: const TextStyle(
                                    color: Colors.redAccent,
                                  ),
                                ),
                        ),
                      ],
                    ],
                  ),
                ),

                // NAVEGAÇÃO INFERIOR
                Container(
                  decoration: BoxDecoration(
                    color: surface,
                    border: Border(top: BorderSide(color: border)),
                  ),
                  child: Row(
                    children: [
                      nav(
                        Icons.home_outlined,
                        _tr('Início', 'Home', 'Inicio'),
                        '/home',
                      ),
                      nav(
                        Icons.style_outlined,
                        _tr('Decks', 'Decks', 'Mazos'),
                        '/decks',
                      ),
                      Expanded(
                        child: Center(
                          child: InkWell(
                            onTap: _saindo
                                ? null
                                : () => _abrir('/create-flashcards'),
                            customBorder: const CircleBorder(),
                            child: Container(
                              width: 59,
                              height: 59,
                              decoration: const BoxDecoration(
                                color: purple,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                          ),
                        ),
                      ),
                      nav(
                        Icons.bar_chart_outlined,
                        _tr('Progresso', 'Progress', 'Progreso'),
                        '/progress',
                      ),
                      nav(
                        Icons.person_outline,
                        _tr('Perfil', 'Profile', 'Perfil'),
                        '/profile',
                        selected: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

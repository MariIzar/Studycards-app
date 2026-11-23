import 'package:flutter/material.dart';

import 'theme_controller.dart';
import 'language_controller.dart';

class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF6C4DFF);

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.themeMode,
      builder: (context, temaAtual, child) {
        return ValueListenableBuilder<Locale>(
          valueListenable: LanguageController.locale,
          builder: (context, idiomaAtual, child) {
            final cores = Theme.of(context).colorScheme;

            return Scaffold(
              appBar: AppBar(
                title: Text(
                  LanguageController.traduzir('appearance'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              body: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: cores.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: cores.outlineVariant),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RadioListTile<ThemeMode>(
                          secondary: const Icon(Icons.wb_sunny_outlined),
                          title: Text(
                            LanguageController.traduzir('light'),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            LanguageController.traduzir('light_description'),
                          ),
                          value: ThemeMode.light,
                          groupValue: temaAtual,
                          activeColor: purple,
                          onChanged: (valor) {
                            if (valor != null) {
                              ThemeController.alterarTema(valor);
                            }
                          },
                        ),
                        const Divider(height: 1),
                        RadioListTile<ThemeMode>(
                          secondary: const Icon(Icons.nightlight_outlined),
                          title: Text(
                            LanguageController.traduzir('dark'),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            LanguageController.traduzir('dark_description'),
                          ),
                          value: ThemeMode.dark,
                          groupValue: temaAtual,
                          activeColor: purple,
                          onChanged: (valor) {
                            if (valor != null) {
                              ThemeController.alterarTema(valor);
                            }
                          },
                        ),
                        const Divider(height: 1),
                        RadioListTile<ThemeMode>(
                          secondary: const Icon(Icons.phone_iphone),
                          title: Text(
                            LanguageController.traduzir('automatic'),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            LanguageController.traduzir(
                              'automatic_description',
                            ),
                          ),
                          value: ThemeMode.system,
                          groupValue: temaAtual,
                          activeColor: purple,
                          onChanged: (valor) {
                            if (valor != null) {
                              ThemeController.alterarTema(valor);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

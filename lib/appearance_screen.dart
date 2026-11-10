import 'package:flutter/material.dart';

import 'theme_controller.dart';

class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryPurple = Color(0xFF6C4DFF);

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.themeMode,
      builder: (context, temaAtual, child) {
        final cores = Theme.of(context).colorScheme;

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Aparência',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            elevation: 0,
          ),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              decoration: BoxDecoration(
                color: cores.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: cores.shadow.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<ThemeMode>(
                    secondary: const Icon(Icons.wb_sunny_outlined),
                    title: const Text(
                      'Claro',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text(
                      'Tema claro para o aplicativo.',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: ThemeMode.light,
                    groupValue: temaAtual,
                    activeColor: primaryPurple,
                    onChanged: (valor) {
                      if (valor != null) {
                        ThemeController.alterarTema(valor);
                      }
                    },
                  ),

                  const Divider(height: 1),

                  RadioListTile<ThemeMode>(
                    secondary: const Icon(Icons.nightlight_outlined),
                    title: const Text(
                      'Escuro',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text(
                      'Tema escuro para o aplicativo.',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: ThemeMode.dark,
                    groupValue: temaAtual,
                    activeColor: primaryPurple,
                    onChanged: (valor) {
                      if (valor != null) {
                        ThemeController.alterarTema(valor);
                      }
                    },
                  ),

                  const Divider(height: 1),

                  RadioListTile<ThemeMode>(
                    secondary: const Icon(Icons.phone_iphone),
                    title: const Text(
                      'Automático',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text(
                      'Seguir a aparência do iPhone.',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: ThemeMode.system,
                    groupValue: temaAtual,
                    activeColor: primaryPurple,
                    onChanged: (valor) {
                      if (valor != null) {
                        ThemeController.alterarTema(valor);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

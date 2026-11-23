import 'package:flutter/material.dart';

import 'language_controller.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF6C4DFF);

    return ValueListenableBuilder<Locale>(
      valueListenable: LanguageController.locale,
      builder: (context, idiomaAtual, child) {
        final tema = Theme.of(context);
        final cores = tema.colorScheme;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              LanguageController.traduzir('language'),
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
                    RadioListTile<String>(
                      title: const Text(
                        'Português (Brasil)',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      value: 'pt',
                      groupValue: idiomaAtual.languageCode,
                      activeColor: purple,
                      onChanged: (valor) {
                        if (valor != null) {
                          LanguageController.alterarIdioma(valor);
                        }
                      },
                    ),
                    const Divider(height: 1),
                    RadioListTile<String>(
                      title: const Text(
                        'English (US)',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      value: 'en',
                      groupValue: idiomaAtual.languageCode,
                      activeColor: purple,
                      onChanged: (valor) {
                        if (valor != null) {
                          LanguageController.alterarIdioma(valor);
                        }
                      },
                    ),
                    const Divider(height: 1),
                    RadioListTile<String>(
                      title: const Text(
                        'Español',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      value: 'es',
                      groupValue: idiomaAtual.languageCode,
                      activeColor: purple,
                      onChanged: (valor) {
                        if (valor != null) {
                          LanguageController.alterarIdioma(valor);
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
  }
}

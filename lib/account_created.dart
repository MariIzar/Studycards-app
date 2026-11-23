import 'package:flutter/material.dart';

import 'requer_login.dart';
import 'language_controller.dart';

class AccountCreatedScreen extends StatelessWidget {
  const AccountCreatedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryPurple = Color(0xFF6C4DFF);

    return ValueListenableBuilder<Locale>(
      valueListenable: LanguageController.locale,
      builder: (context, idiomaAtual, child) {
        final tema = Theme.of(context);
        final cores = tema.colorScheme;

        String traduzir(String pt, String en, String es) {
          switch (idiomaAtual.languageCode) {
            case 'en':
              return en;
            case 'es':
              return es;
            default:
              return pt;
          }
        }

        return Scaffold(
          backgroundColor: tema.scaffoldBackgroundColor,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: cores.onSurface),
                    onPressed: () => voltaDoLogin(context),
                  ),

                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Ícone de confirmação
                          Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              color: primaryPurple.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_circle_rounded,
                              color: primaryPurple,
                              size: 54,
                            ),
                          ),

                          const SizedBox(height: 24),

                          Text(
                            traduzir(
                              'Conta criada!',
                              'Account created!',
                              '¡Cuenta creada!',
                            ),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: cores.onSurface,
                            ),
                          ),

                          const SizedBox(height: 12),

                          Text(
                            traduzir(
                              'Sua conta foi criada com sucesso.\nAgora você pode continuar seus estudos.',
                              'Your account was created successfully.\nYou can now continue studying.',
                              'Tu cuenta se creó correctamente.\nAhora puedes continuar estudiando.',
                            ),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              color: cores.onSurfaceVariant,
                              height: 1.4,
                            ),
                          ),

                          const SizedBox(height: 40),

                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryPurple,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(52),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () => voltaDoLogin(context),
                            child: Text(
                              traduzir(
                                'Começar a estudar',
                                'Start studying',
                                'Empezar a estudiar',
                              ),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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

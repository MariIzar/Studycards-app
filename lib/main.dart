import 'package:flutter/material.dart';

import 'banco_de_dados/auth_helper.dart';
import 'requer_login.dart';

// Telas principais e de autenticação
import 'login_screen.dart';
import 'register_screen.dart';
import 'home_screen.dart';
import 'about_app.dart';
import 'forget_password.dart';
import 'account_created.dart'; // Nova tela de conta criada

// Telas de Decks e Flashcards
import 'creat_flashcards.dart';
import 'decks_screen.dart';
import 'camera_screen.dart';
import 'review_image.dart';
import 'processes_screen.dart';
import 'generated_fleshcards.dart';
import 'edit_flashcard.dart';
import 'select_deck.dart';
import 'deck_datails.dart';
import 'creat_decks.dart';
import 'review_cards.dart'; // Tela de estudo/revisão dos cards
import 'review_completed.dart'; // Tela de resumo da revisão

// Telas de Perfil e Configurações
import 'progress_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart'; // <--- Nova tela de configurações gerais
import 'edit_profile.dart';
import 'change_passoword.dart';
import 'private_settings.dart';
import 'notifications_settings.dart';
import 'appearance_screen.dart';
import 'lenguage_screen.dart';
import 'help_support.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Recupera quem estava logado (login local, sem servidor)
  await Sessao.carrega();
  runApp(const StudyCardsApp());
}

class StudyCardsApp extends StatelessWidget {
  const StudyCardsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StudyCards',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        primaryColor: const Color(0xFF6C4DFF),
        scaffoldBackgroundColor: const Color(0xFFF8F9FE),
      ),
      // ⚠️ Ajuste solicitado pelo professor:
      // Em vez de iniciar direto no Login ou na Home seca, iniciamos na
      // tela de boas-vindas/visitante (que permite entrar ou criar conta)[cite: 1].
      initialRoute: '/home',
      routes: {
        // Rotas de Autenticação e Boas-Vindas
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/account-created': (context) => const AccountCreatedScreen(),

        // Rota Principal
        '/home': (context) => const HomeScreen(),
        '/about': (context) => const AboutScreen(),

        // Rotas de Decks e Flashcards
        '/decks': (context) => RequerLogin(child: const DecksScreen()),
        '/deck-details': (context) =>
            RequerLogin(child: const DeckDetailsScreen()),
        '/create-deck': (context) =>
            RequerLogin(child: const CreateDeckScreen()),
        '/create-flashcards': (context) =>
            RequerLogin(child: const CreateFlashcardsScreen()),

        // Rotas de Estudo e Revisão
        '/study': (context) => RequerLogin(child: const StudyScreen()),
        '/review-completed': (context) =>
            RequerLogin(child: const ReviewCompletedScreen()),

        // Rotas do fluxo de IA e Câmera
        '/camera': (context) => RequerLogin(child: const CameraScreen()),
        '/review-image': (context) =>
            RequerLogin(child: const ReviewImageScreen()),
        '/processing': (context) =>
            RequerLogin(child: const ProcessingScreen()),
        '/generated-flashcards': (context) =>
            RequerLogin(child: const GeneratedFlashcardsScreen()),
        '/select-deck': (context) =>
            RequerLogin(child: const SelectDeckScreen()),

        // Rotas de Perfil e Sub-menus de Configuração
        '/profile': (context) => const ProfileScreen(),
        '/settings': (context) =>
            const SettingsScreen(), // <--- Nova rota de configurações
        '/progress': (context) => RequerLogin(child: const ProgressScreen()),
        '/edit-profile': (context) =>
            RequerLogin(child: const EditProfileScreen()),
        '/change-password': (context) =>
            RequerLogin(child: const ChangePasswordScreen()),
        '/privacy-settings': (context) =>
            RequerLogin(child: const PrivacySettingsScreen()),
        '/notifications-settings': (context) =>
            RequerLogin(child: const NotificationsSettingsScreen()),
        '/appearance': (context) => const AppearanceScreen(),
        '/language': (context) => const LanguageScreen(),
        '/help-support': (context) => const HelpSupportScreen(),
      },
    );
  }
}

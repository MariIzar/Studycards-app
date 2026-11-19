import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'banco_de_dados/auth_helper.dart';
import 'services/nuvem_dados.dart';
import 'services/sync_service.dart';
import 'requer_login.dart';
import 'theme_controller.dart';

// Telas principais e de autenticação
import 'login_screen.dart';
import 'register_screen.dart';
import 'home_screen.dart';
import 'about_app.dart';
import 'forget_password.dart';
import 'account_created.dart';

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
import 'review_cards.dart';
import 'review_completed.dart';

// Telas de Perfil e Configurações
import 'progress_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'edit_profile.dart';
import 'change_passoword.dart';
import 'private_settings.dart';
import 'notifications_settings.dart';
import 'appearance_screen.dart';
import 'lenguage_screen.dart';
import 'help_support.dart';

// Avisa as telas quando voltam a ficar visíveis.
final RouteObserver<ModalRoute<dynamic>> routeObserver =
    RouteObserver<ModalRoute<dynamic>>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase: usado somente para o login com Google (config vem do
  // google-services.json no Android). Se falhar, o app segue com login local.
  try {
    await Firebase.initializeApp();
    SyncService.nuvem = FirestoreNuvemDados(); // backup/sincronização na nuvem
  } catch (_) {}

  // Recupera a sessão do usuário
  await Sessao.carrega();
  SyncService.iniciar(); // se já estava logado, sincroniza ao abrir o app

  // Recupera o tema escolhido anteriormente
  await ThemeController.carregarTema();

  runApp(const StudyCardsApp());
}

class StudyCardsApp extends StatelessWidget {
  const StudyCardsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.themeMode,
      builder: (context, modoAtual, child) {
        return MaterialApp(
          title: 'StudyCards',
          debugShowCheckedModeBanner: false,
          navigatorObservers: [routeObserver],

          // Tema selecionado pelo usuário
          themeMode: modoAtual,

          // MODO CLARO
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF6C4DFF),
              brightness: Brightness.light,
            ),
            primaryColor: const Color(0xFF6C4DFF),
            scaffoldBackgroundColor: const Color(0xFFF8F9FE),
          ),

          // MODO ESCURO
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF6C4DFF),
              brightness: Brightness.dark,
            ),
            primaryColor: const Color(0xFF6C4DFF),
            scaffoldBackgroundColor: const Color(0xFF12121A),
          ),

          // Tela inicial
          initialRoute: '/home',

          routes: {
            // Autenticação
            '/login': (context) => const LoginScreen(),
            '/register': (context) => const RegisterScreen(),
            '/forgot-password': (context) => const ForgotPasswordScreen(),
            '/account-created': (context) => const AccountCreatedScreen(),

            // Principal
            '/home': (context) => const HomeScreen(),
            '/about': (context) => const AboutScreen(),

            // Decks e Flashcards
            '/decks': (context) => RequerLogin(child: const DecksScreen()),
            '/deck-details': (context) =>
                RequerLogin(child: const DeckDetailsScreen()),
            '/create-deck': (context) =>
                RequerLogin(child: const CreateDeckScreen()),
            '/create-flashcards': (context) =>
                RequerLogin(child: const CreateFlashcardsScreen()),

            // Estudo e Revisão
            '/study': (context) => RequerLogin(child: const StudyScreen()),
            '/review-completed': (context) =>
                RequerLogin(child: const ReviewCompletedScreen()),

            // IA e Câmera
            '/camera': (context) => RequerLogin(child: const CameraScreen()),
            '/review-image': (context) =>
                RequerLogin(child: const ReviewImageScreen()),
            '/processing': (context) =>
                RequerLogin(child: const ProcessingScreen()),
            '/generated-flashcards': (context) =>
                RequerLogin(child: const GeneratedFlashcardsScreen()),
            '/select-deck': (context) =>
                RequerLogin(child: const SelectDeckScreen()),

            // Perfil e Configurações
            '/profile': (context) => const ProfileScreen(),
            '/settings': (context) => const SettingsScreen(),
            '/progress': (context) =>
                RequerLogin(child: const ProgressScreen()),
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
      },
    );
  }
}

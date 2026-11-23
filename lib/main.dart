import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'firebase_options.dart';

import 'banco_de_dados/auth_helper.dart';
import 'services/nuvem_dados.dart';
import 'services/sync_service.dart';

import 'requer_login.dart';
import 'theme_controller.dart';
import 'language_controller.dart';

// Telas principais e autenticação
import 'splash_screen.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import 'home_screen.dart';
import 'about_app.dart';
import 'forget_password.dart';
import 'account_created.dart';

// Decks e flashcards
import 'creat_flashcards.dart';
import 'create_manual_flashcard.dart';
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

// Perfil e configurações
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

// Observador usado por telas que atualizam ao voltar.
final RouteObserver<ModalRoute<dynamic>> routeObserver =
    RouteObserver<ModalRoute<dynamic>>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Inicializar Firebase e sincronização.
  bool firebaseInicializado = false;

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    firebaseInicializado = true;

    SyncService.nuvem = FirestoreNuvemDados();

    debugPrint('Firebase inicializado com sucesso!');
  } catch (e) {
    debugPrint('Erro ao inicializar Firebase: $e');
  }

  // 2. Recuperar a sessão local.
  try {
    await Sessao.carrega();
  } catch (e) {
    debugPrint('Erro ao recuperar sessão: $e');
  }

  // 3. Recuperar preferências de aparência.
  try {
    await ThemeController.carregarTema();
  } catch (e) {
    debugPrint('Erro ao carregar tema: $e');
  }

  // 4. Recuperar idioma.
  try {
    await LanguageController.carregarIdioma();
  } catch (e) {
    debugPrint('Erro ao carregar idioma: $e');
  }

  // 5. Iniciar sincronização somente com Firebase disponível.
  if (firebaseInicializado) {
    try {
      SyncService.iniciar();
      debugPrint('Sincronização iniciada.');
    } catch (e) {
      debugPrint('Erro ao iniciar sincronização: $e');
    }
  } else {
    debugPrint('Sincronização não iniciada: Firebase indisponível.');
  }

  // 6. Abrir o aplicativo.
  runApp(const StudyCardsApp());
}

class StudyCardsApp extends StatelessWidget {
  const StudyCardsApp({super.key});

  static const Color primaryPurple = Color(0xFF6C4DFF);
  static const Color lightBackground = Color(0xFFF8F7FF);
  static const Color darkBackground = Color(0xFF141320);
  static const Color lightText = Color(0xFF191B31);
  static const Color darkSurface = Color(0xFF242333);

  ThemeData _buildLightTheme() {
    final scheme = ColorScheme.fromSeed(
      seedColor: primaryPurple,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme.copyWith(
        primary: primaryPurple,
        surface: Colors.white,
        onSurface: lightText,
      ),
      primaryColor: primaryPurple,
      scaffoldBackgroundColor: lightBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: lightBackground,
        foregroundColor: lightText,
        elevation: 0,
        centerTitle: true,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryPurple,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryPurple,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    final scheme = ColorScheme.fromSeed(
      seedColor: primaryPurple,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme.copyWith(
        primary: primaryPurple,
        surface: darkSurface,
        onSurface: Colors.white,
      ),
      primaryColor: primaryPurple,
      scaffoldBackgroundColor: darkBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBackground,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryPurple,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryPurple,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.themeMode,
      builder: (context, modoAtual, child) {
        return ValueListenableBuilder<Locale>(
          valueListenable: LanguageController.locale,
          builder: (context, idiomaAtual, child) {
            return MaterialApp(
              title: 'StudyCards',
              debugShowCheckedModeBanner: false,

              navigatorObservers: [routeObserver],

              // IDIOMAS
              locale: idiomaAtual,
              supportedLocales: const [
                Locale('pt', 'BR'),
                Locale('en', 'US'),
                Locale('es'),
              ],
              localizationsDelegates: GlobalMaterialLocalizations.delegates,

              // TEMAS
              themeMode: modoAtual,
              theme: _buildLightTheme(),
              darkTheme: _buildDarkTheme(),

              // TELA INICIAL
              initialRoute: '/splash',

              // ROTAS
              routes: {
                // Inicialização
                '/splash': (context) => const SplashScreen(),

                // AUTENTICAÇÃO
                '/login': (context) => const LoginScreen(),

                '/register': (context) => const RegisterScreen(),

                '/forgot-password': (context) => const ForgotPasswordScreen(),

                '/account-created': (context) => const AccountCreatedScreen(),

                // PRINCIPAL
                '/home': (context) => const HomeScreen(),

                '/about': (context) => const AboutScreen(),

                // DECKS
                '/decks': (context) => RequerLogin(child: DecksScreen()),

                '/deck-details': (context) =>
                    RequerLogin(child: DeckDetailsScreen()),

                '/create-deck': (context) =>
                    RequerLogin(child: const CreateDeckScreen()),

                '/create-flashcards': (context) =>
                    RequerLogin(child: const CreateFlashcardsScreen()),

                // NOVA TELA DE CRIAÇÃO MANUAL
                '/create-manual-flashcard': (context) =>
                    RequerLogin(child: const CreateManualFlashcardScreen()),

                // ESTUDO E REVISÃO
                '/study': (context) => RequerLogin(child: const StudyScreen()),

                '/review-completed': (context) =>
                    RequerLogin(child: const ReviewCompletedScreen()),

                // IA E CÂMERA
                '/camera': (context) =>
                    RequerLogin(child: const CameraScreen()),

                '/review-image': (context) =>
                    RequerLogin(child: const ReviewImageScreen()),

                '/processing': (context) =>
                    RequerLogin(child: const ProcessingScreen()),

                '/generated-flashcards': (context) =>
                    RequerLogin(child: const GeneratedFlashcardsScreen()),

                '/select-deck': (context) =>
                    RequerLogin(child: const SelectDeckScreen()),

                // PERFIL
                '/profile': (context) => const ProfileScreen(),

                '/progress': (context) =>
                    RequerLogin(child: const ProgressScreen()),

                '/edit-profile': (context) =>
                    RequerLogin(child: const EditProfileScreen()),

                '/change-password': (context) =>
                    RequerLogin(child: const ChangePasswordScreen()),

                // CONFIGURAÇÕES
                '/settings': (context) => const SettingsScreen(),

                '/privacy-settings': (context) =>
                    RequerLogin(child: const PrivacySettingsScreen()),

                '/notifications-settings': (context) =>
                    RequerLogin(child: const NotificationsSettingsScreen()),

                '/appearance': (context) => const AppearanceScreen(),

                '/language': (context) => const LanguageScreen(),

                // INFORMAÇÕES E SUPORTE
                '/help-support': (context) => const HelpSupportScreen(),
              },
            );
          },
        );
      },
    );
  }
}

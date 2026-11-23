import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageController {
  static const String _chaveIdioma = 'studycards_language';

  static final ValueNotifier<Locale> locale = ValueNotifier<Locale>(
    const Locale('pt'),
  );

  static const Map<String, Map<String, String>> _traducoes = {
    'pt': {
      'appearance': 'Aparência',
      'light': 'Claro',
      'dark': 'Escuro',
      'automatic': 'Automático',
      'light_description': 'Tema claro para o aplicativo.',
      'dark_description': 'Tema escuro para o aplicativo.',
      'automatic_description': 'Seguir a aparência do dispositivo.',
      'language': 'Idioma',
      'portuguese': 'Português (Brasil)',
      'english': 'English (US)',
      'spanish': 'Español',
      'settings': 'Configurações',
      'home': 'Início',
      'decks': 'Decks',
      'progress': 'Progresso',
      'profile': 'Perfil',
      'subscription': 'Assinatura',
      'login': 'Entrar',
      'register': 'Cadastrar',
      'study': 'Estudar',
      'save': 'Salvar',
      'cancel': 'Cancelar',
      'back': 'Voltar',
      'loading': 'Carregando...',
      'app_name': 'StudyCards',
      'app_slogan': 'Estude menos. Aprenda mais.',
    },
    'en': {
      'appearance': 'Appearance',
      'light': 'Light',
      'dark': 'Dark',
      'automatic': 'Automatic',
      'light_description': 'Use the light theme.',
      'dark_description': 'Use the dark theme.',
      'automatic_description': 'Follow the device appearance.',
      'language': 'Language',
      'portuguese': 'Português (Brasil)',
      'english': 'English (US)',
      'spanish': 'Español',
      'settings': 'Settings',
      'home': 'Home',
      'decks': 'Decks',
      'progress': 'Progress',
      'profile': 'Profile',
      'subscription': 'Subscription',
      'login': 'Log in',
      'register': 'Sign up',
      'study': 'Study',
      'save': 'Save',
      'cancel': 'Cancel',
      'back': 'Back',
      'loading': 'Loading...',
      'app_name': 'StudyCards',
      'app_slogan': 'Study less. Learn more.',
    },
    'es': {
      'appearance': 'Apariencia',
      'light': 'Claro',
      'dark': 'Oscuro',
      'automatic': 'Automático',
      'light_description': 'Usar el tema claro.',
      'dark_description': 'Usar el tema oscuro.',
      'automatic_description': 'Seguir la apariencia del dispositivo.',
      'language': 'Idioma',
      'portuguese': 'Português (Brasil)',
      'english': 'English (US)',
      'spanish': 'Español',
      'settings': 'Configuración',
      'home': 'Inicio',
      'decks': 'Mazos',
      'progress': 'Progreso',
      'profile': 'Perfil',
      'subscription': 'Suscripción',
      'login': 'Iniciar sesión',
      'register': 'Registrarse',
      'study': 'Estudiar',
      'save': 'Guardar',
      'cancel': 'Cancelar',
      'back': 'Volver',
      'loading': 'Cargando...',
      'app_name': 'StudyCards',
      'app_slogan': 'Estudia menos. Aprende más.',
    },
  };

  static Future<void> carregarIdioma() async {
    final prefs = await SharedPreferences.getInstance();
    final codigo = prefs.getString(_chaveIdioma) ?? 'pt';

    locale.value = Locale(_traducoes.containsKey(codigo) ? codigo : 'pt');
  }

  static Future<void> alterarIdioma(String codigo) async {
    if (!_traducoes.containsKey(codigo)) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chaveIdioma, codigo);

    locale.value = Locale(codigo);
  }

  static String traduzir(String chave) {
    final codigo = locale.value.languageCode;

    return _traducoes[codigo]?[chave] ?? _traducoes['pt']?[chave] ?? chave;
  }
}

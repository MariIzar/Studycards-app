import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController {
  static final ValueNotifier<ThemeMode> themeMode = ValueNotifier<ThemeMode>(
    ThemeMode.system,
  );

  static const String _chaveTema = 'studycards_theme';

  // Carrega o tema salvo no dispositivo.
  static Future<void> carregarTema() async {
    final prefs = await SharedPreferences.getInstance();
    final temaSalvo = prefs.getString(_chaveTema);

    switch (temaSalvo) {
      case 'light':
        themeMode.value = ThemeMode.light;
        break;

      case 'dark':
        themeMode.value = ThemeMode.dark;
        break;

      default:
        themeMode.value = ThemeMode.system;
    }
  }

  // Altera o tema e salva a escolha.
  static Future<void> alterarTema(ThemeMode novoTema) async {
    final prefs = await SharedPreferences.getInstance();

    themeMode.value = novoTema;

    await prefs.setString(_chaveTema, novoTema.name);
  }
}

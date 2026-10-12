// =============================================================================
// preferencias_helper.dart — SharedPreferences do StudyCards
// -----------------------------------------------------------------------------
// Segue a aula LDDM08: SharedPreferences serve para POUCOS dados simples
// (chave/valor). Os dados de verdade (decks, cards) ficam no SQLite.
//
// Aqui guardamos:
//   - qual usuário está logado (id + se entrou pelo Google)
//   - se o onboarding já foi visto
//   - tema (claro/escuro) e idioma
//   - horário do lembrete de estudo
// =============================================================================

import 'package:shared_preferences/shared_preferences.dart';

class PreferenciasHelper {
  // Chaves — as mesmas são usadas para salvar e para recuperar
  static const String _chaveUsuarioLogado = 'usuario_logado_id';
  static const String _chaveLoginGoogle = 'login_google';
  static const String _chaveOnboardingVisto = 'onboarding_visto';
  static const String _chaveTemaEscuro = 'tema_escuro';
  static const String _chaveIdioma = 'idioma';
  static const String _chaveHoraLembrete = 'hora_lembrete';

  // ---------------------------------------------------------------------------
  // SESSÃO / LOGIN
  // ---------------------------------------------------------------------------
  static Future<void> salvaUsuarioLogado(int usuarioId,
      {bool viaGoogle = false}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_chaveUsuarioLogado, usuarioId);
    await prefs.setBool(_chaveLoginGoogle, viaGoogle);
  }

  /// Retorna o id do usuário logado ou null se ninguém estiver logado.
  static Future<int?> recuperaUsuarioLogado() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_chaveUsuarioLogado);
  }

  static Future<bool> logadoViaGoogle() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_chaveLoginGoogle) ?? false;
  }

  /// Logout: remove as chaves da sessão.
  static Future<void> removeUsuarioLogado() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_chaveUsuarioLogado);
    await prefs.remove(_chaveLoginGoogle);
  }

  // ---------------------------------------------------------------------------
  // ONBOARDING
  // ---------------------------------------------------------------------------
  static Future<void> marcaOnboardingVisto() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_chaveOnboardingVisto, true);
  }

  static Future<bool> onboardingFoiVisto() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_chaveOnboardingVisto) ?? false;
  }

  // ---------------------------------------------------------------------------
  // APARÊNCIA / IDIOMA
  // ---------------------------------------------------------------------------
  static Future<void> salvaTemaEscuro(bool escuro) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_chaveTemaEscuro, escuro);
  }

  static Future<bool> recuperaTemaEscuro() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_chaveTemaEscuro) ?? false;
  }

  static Future<void> salvaIdioma(String idioma) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chaveIdioma, idioma);
  }

  static Future<String> recuperaIdioma() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_chaveIdioma) ?? 'pt-BR';
  }

  // ---------------------------------------------------------------------------
  // LEMBRETE DE ESTUDO (guardado como "HH:mm", ex.: "19:30")
  // ---------------------------------------------------------------------------
  static Future<void> salvaHoraLembrete(String horaMinuto) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chaveHoraLembrete, horaMinuto);
  }

  static Future<String> recuperaHoraLembrete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_chaveHoraLembrete) ?? '19:00';
  }

  /// Limpa todas as preferências (útil para testes).
  static Future<void> limpaTudo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}

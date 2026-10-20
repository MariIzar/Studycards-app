import 'package:flutter/material.dart';

import 'banco_de_dados/auth_helper.dart';
import 'banco_de_dados/sql_helper.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool profileVisible = true;
  bool showProgress = true;
  bool usageData = false;

  @override
  void initState() {
    super.initState();
    _carrega();
  }

  Future<void> _carrega() async {
    final id = Sessao.usuarioId;
    if (id == null) return;
    final u = await SQLHelper.pegaUmUsuario(id);
    if (!mounted || u.isEmpty) return;
    setState(() => profileVisible = u.first['is_profile_visible'] == 1);
  }

  @override
  Widget build(BuildContext context) {
    const primaryPurple = Color(0xFF6C4DFF);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Privacidade',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text(
                            'Perfil visível',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: const Text(
                            'Permite que outros usuários vejam seu perfil',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          value: profileVisible,
                          activeColor: primaryPurple,
                          onChanged: (val) =>
                              setState(() => profileVisible = val),
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          title: const Text(
                            'Mostrar progresso',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: const Text(
                            'Permite que outros usuários vejam seu progresso',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          value: showProgress,
                          activeColor: primaryPurple,
                          onChanged: (val) =>
                              setState(() => showProgress = val),
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          title: const Text(
                            'Dados de uso',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: const Text(
                            'Ajuda a melhorar o app com dados anônimos',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          value: usageData,
                          activeColor: primaryPurple,
                          onChanged: (val) => setState(() => usageData = val),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F0FF),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: const [
                        Icon(
                          Icons.shield_outlined,
                          color: primaryPurple,
                          size: 28,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Seus dados estão seguros!',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: primaryPurple,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Levamos sua privacidade a sério e não compartilhamos suas informações.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryPurple,
                minimumSize: const Size.fromHeight(52),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () async {
                final id = Sessao.usuarioId;
                if (id != null) {
                  await SQLHelper.atualizaPreferenciasUsuario(id,
                      perfilVisivel: profileVisible);
                }
                if (!context.mounted) return;
                Navigator.pop(context);
              },
              child: const Text(
                'Salvar alterações',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

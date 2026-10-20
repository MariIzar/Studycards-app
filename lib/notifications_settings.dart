import 'package:flutter/material.dart';

import 'banco_de_dados/auth_helper.dart';
import 'banco_de_dados/sql_helper.dart';

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() =>
      _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState
    extends State<NotificationsSettingsScreen> {
  bool studyReminder = true;
  bool newDecks = true;
  bool reviewCompleted = true;
  bool dailyTips = false;

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
    setState(() => studyReminder = u.first['notify_study_reminder'] == 1);
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
          'Notificações',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Expanded(
              child: Container(
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
                        'Lembrete de estudo',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text(
                        'Receba lembretes para revisar seus decks.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      value: studyReminder,
                      activeColor: primaryPurple,
                      onChanged: (val) => setState(() => studyReminder = val),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text(
                        'Novos decks',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text(
                        'Seus decks foram atualizados.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      value: newDecks,
                      activeColor: primaryPurple,
                      onChanged: (val) => setState(() => newDecks = val),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text(
                        'Revisão concluída',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text(
                        'Receba um resumo do seu desempenho.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      value: reviewCompleted,
                      activeColor: primaryPurple,
                      onChanged: (val) => setState(() => reviewCompleted = val),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text(
                        'Dicas do dia',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text(
                        'Dicas e conteúdos para melhorar seus estudos.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      value: dailyTips,
                      activeColor: primaryPurple,
                      onChanged: (val) => setState(() => dailyTips = val),
                    ),
                  ],
                ),
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
                      lembreteEstudo: studyReminder);
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

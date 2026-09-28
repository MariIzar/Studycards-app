import 'package:flutter/material.dart';

class AppearanceScreen extends StatefulWidget {
  const AppearanceScreen({super.key});

  @override
  State<AppearanceScreen> createState() => _AppearanceScreenState();
}

class _AppearanceScreenState extends State<AppearanceScreen> {
  bool isLightMode = true;
  bool isDarkMode = false;

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
          'Aparência',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
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
                    secondary: const Icon(
                      Icons.wb_sunny_outlined,
                      color: Colors.black87,
                    ),
                    title: const Text(
                      'Claro',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text(
                      'Tema claro para o aplicativo.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    value: isLightMode,
                    activeColor: primaryPurple,
                    onChanged: (val) {
                      setState(() {
                        isLightMode = val;
                        if (val) isDarkMode = false;
                      });
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: const Icon(
                      Icons.nightlight_outlined,
                      color: Colors.black87,
                    ),
                    title: const Text(
                      'Escuro',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text(
                      'Tema escuro para o aplicativo.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    value: isDarkMode,
                    activeColor: primaryPurple,
                    onChanged: (val) {
                      setState(() {
                        isDarkMode = val;
                        if (val) isLightMode = false;
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

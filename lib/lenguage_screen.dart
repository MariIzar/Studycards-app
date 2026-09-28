import 'package:flutter/material.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  String selectedLanguage = 'Português';

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
          'Idioma',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
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
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text(
                  'Português (Brasil)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                value: 'Português',
                groupValue: selectedLanguage,
                activeColor: primaryPurple,
                onChanged: (val) => setState(() => selectedLanguage = val!),
              ),
              const Divider(height: 1),
              RadioListTile<String>(
                title: const Text(
                  'English (US)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                value: 'English',
                groupValue: selectedLanguage,
                activeColor: primaryPurple,
                onChanged: (val) => setState(() => selectedLanguage = val!),
              ),
              const Divider(height: 1),
              RadioListTile<String>(
                title: const Text(
                  'Español',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                value: 'Español',
                groupValue: selectedLanguage,
                activeColor: primaryPurple,
                onChanged: (val) => setState(() => selectedLanguage = val!),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

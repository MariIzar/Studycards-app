import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _abrirHome();
  }

  Future<void> _abrirHome() async {
    await Future.delayed(const Duration(seconds: 5));

    if (!mounted) return;

    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    final escuro = Theme.of(context).brightness == Brightness.dark;

    final fundo = escuro ? const Color(0xFF141320) : const Color(0xFFF8F7FF);

    final texto = escuro ? Colors.white : const Color(0xFF191B31);

    final subtitulo = escuro ? Colors.white60 : const Color(0xFF73798B);

    return Scaffold(
      backgroundColor: fundo,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/studycards_logo.png',
                width: 100,
                height: 100,
                fit: BoxFit.contain,
              ),

              const SizedBox(height: 20),

              Text(
                'StudyCards',
                style: TextStyle(
                  color: texto,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                'Estude menos. Aprenda mais.',
                style: TextStyle(
                  color: subtitulo,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

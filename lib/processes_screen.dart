import 'package:flutter/material.dart';

class ProcessingScreen extends StatefulWidget {
  const ProcessingScreen({super.key});

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> {
  @override
  void initState() {
    super.initState();
    // Simulação de transição automática após 2.5 segundos
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/generated-flashcards');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Processando seu material...',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'A IA está analisando e criando seus flashcards.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 40),
            const CheckItem(title: 'Extraindo texto...', isDone: true),
            const SizedBox(height: 12),
            const CheckItem(title: 'Criando flashcards...', isDone: true),
            const SizedBox(height: 40),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: const LinearProgressIndicator(
                value: 0.75,
                minHeight: 10,
                backgroundColor: Color(0xFFE0E0E0),
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C4DFF)),
              ),
            ),
            const SizedBox(height: 12),
            const Text('75%', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => Navigator.pushReplacementNamed(
                context,
                '/generated-flashcards',
              ),
              child: const Text('Avançar (Simulação)'),
            ),
          ],
        ),
      ),
    );
  }
}

class CheckItem extends StatelessWidget {
  final String title;
  final bool isDone;
  const CheckItem({super.key, required this.title, required this.isDone});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: isDone ? const Color(0xFF6C4DFF) : Colors.grey[300],
          child: Icon(
            Icons.check,
            size: 16,
            color: isDone ? Colors.white : Colors.grey,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

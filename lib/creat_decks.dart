import 'package:flutter/material.dart';

import 'banco_de_dados/sql_helper.dart';

class CreateDeckScreen extends StatefulWidget {
  const CreateDeckScreen({super.key});

  @override
  State<CreateDeckScreen> createState() => _CreateDeckScreenState();
}

class _CreateDeckScreenState extends State<CreateDeckScreen> {
  final TextEditingController _nameController = TextEditingController();

  static const Color primaryPurple = Color(0xFF6C4DFF);

  static const List<Color> deckColors = [
    Color(0xFF6C4DFF),
    Color(0xFF2ECC71),
    Color(0xFF3498DB),
    Color(0xFFF1C40F),
    Color(0xFFE91E63),
    Color(0xFF1ABC9C),
  ];

  int selectedColorIndex = 0;
  bool _isSaving = false;

  Future<void> _saveDeck() async {
    final String name = _nameController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Digite o nome do deck!')));
      return;
    }

    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final int id = await SQLHelper.adicionaDeck(
        name,
        cor: deckColors[selectedColorIndex].toARGB32(),
      );

      if (!mounted) return;

      Navigator.pop(context, id);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erro ao criar deck: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FE),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Novo deck',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ListView(
                  children: [
                    const Text(
                      'Nome do deck',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5A5D7A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: TextField(
                        controller: _nameController,
                        maxLength: 100,
                        decoration: const InputDecoration(
                          hintText: 'Ex: Matemática',
                          border: InputBorder.none,
                          counterText: '',
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Cor do deck',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5A5D7A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Wrap(
                        spacing: 14,
                        runSpacing: 14,
                        children: List.generate(deckColors.length, (index) {
                          final bool isSelected = selectedColorIndex == index;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedColorIndex = index;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: deckColors[index],
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.black54
                                      : Colors.transparent,
                                  width: 3,
                                ),
                              ),
                              child: isSelected
                                  ? const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 22,
                                    )
                                  : null,
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveDeck,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    _isSaving ? 'Salvando...' : 'Criar deck',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

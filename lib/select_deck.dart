import 'package:flutter/material.dart';

class SelectDeckScreen extends StatefulWidget {
  const SelectDeckScreen({super.key});

  @override
  State<SelectDeckScreen> createState() => _SelectDeckScreenState();
}

class _SelectDeckScreenState extends State<SelectDeckScreen> {
  String? selectedDeck = 'Cálculo';

  // Incluímos 'Criar novo deck' na própria lista de opções para seguir o design
  final List<String> decks = [
    'Cálculo',
    'Biologia',
    'Programação',
    'História',
    'Criar novo deck',
  ];

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
          'Salvar flashcards',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Escolha um deck:',
              style: TextStyle(color: Color(0xFF6B7280), fontSize: 15),
            ),
            const SizedBox(height: 16),

            // Lista de Decks
            Expanded(
              child: ListView.builder(
                itemCount: decks.length,
                itemBuilder: (context, index) {
                  final deckName = decks[index];
                  final isCreateOption = deckName == 'Criar novo deck';
                  final isSelected = selectedDeck == deckName;

                  return GestureDetector(
                    onTap: () {
                      if (isCreateOption) {
                        Navigator.pushNamed(context, '/create-deck');
                      } else {
                        setState(() {
                          selectedDeck = deckName;
                        });
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: isSelected && !isCreateOption
                              ? primaryPurple
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              if (isCreateOption) ...[
                                const Icon(
                                  Icons.add,
                                  color: primaryPurple,
                                  size: 22,
                                ),
                                const SizedBox(width: 12),
                              ],
                              Text(
                                deckName,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isCreateOption
                                      ? primaryPurple
                                      : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          if (isCreateOption)
                            const Icon(
                              Icons.chevron_right,
                              color: Colors.black54,
                              size: 22,
                            )
                          else if (isSelected)
                            Container(
                              decoration: const BoxDecoration(
                                color: primaryPurple,
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(4),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 16,
                              ),
                            )
                          else
                            const Icon(
                              Icons.chevron_right,
                              color: Colors.black54,
                              size: 22,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 10),

            // Botão Salvar
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryPurple,
                minimumSize: const Size.fromHeight(52),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/decks',
                  ModalRoute.withName('/home'),
                );
              },
              child: const Text(
                'Salvar',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

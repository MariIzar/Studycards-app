import 'package:flutter/material.dart';

import 'banco_de_dados/auth_helper.dart';
import 'banco_de_dados/sql_helper.dart';

class SelectDeckScreen extends StatefulWidget {
  const SelectDeckScreen({super.key});

  @override
  State<SelectDeckScreen> createState() => _SelectDeckScreenState();
}

class _SelectDeckScreenState extends State<SelectDeckScreen> {
  int? selectedDeckId;

  List<Map<String, dynamic>> decks = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDecks();
  }

  // Busca os decks no SQLite
  Future<void> _loadDecks() async {
    try {
      final result = await SQLHelper.pegaDecks(usuarioId: Sessao.usuarioId);

      if (!mounted) return;

      setState(() {
        decks = result;
        isLoading = false;
        errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = 'Erro ao carregar os decks: $e';
      });
    }
  }

  // Permite criar um deck sem sair do fluxo
  Future<void> _createDeck() async {
    final createdId = await Navigator.pushNamed(context, '/create-deck');

    if (!mounted) return;

    await _loadDecks();

    if (!mounted) return;

    if (createdId is int) {
      setState(() {
        selectedDeckId = createdId;
      });
    }
  }

  // Confirma o deck selecionado
  void _confirmSelection() {
    if (selectedDeckId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um deck primeiro.')),
      );
      return;
    }

    // Retorna o ID para a tela anterior.
    Navigator.pop(context, selectedDeckId);
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
          'Salvar flashcards',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Escolha um deck:',
              style: TextStyle(color: Color(0xFF6B7280), fontSize: 15),
            ),
            const SizedBox(height: 16),

            // Lista dinâmica de decks
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: primaryPurple),
                    )
                  : errorMessage != null
                  ? Center(
                      child: TextButton(
                        onPressed: _loadDecks,
                        child: Text(errorMessage!),
                      ),
                    )
                  : ListView.builder(
                      itemCount: decks.length + 1,
                      itemBuilder: (context, index) {
                        final isCreateOption = index == decks.length;

                        final deck = isCreateOption ? null : decks[index];

                        final id = deck == null
                            ? null
                            : (deck['id'] as num).toInt();

                        final deckName = isCreateOption
                            ? 'Criar novo deck'
                            : (deck!['title']?.toString() ?? 'Sem nome');

                        final isSelected = id != null && selectedDeckId == id;

                        return GestureDetector(
                          onTap: () {
                            if (isCreateOption) {
                              _createDeck();
                            } else {
                              setState(() {
                                selectedDeckId = id;
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
                                color: isSelected
                                    ? primaryPurple
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Row(
                                    children: [
                                      if (isCreateOption) ...[
                                        const Icon(
                                          Icons.add,
                                          color: primaryPurple,
                                          size: 22,
                                        ),
                                        const SizedBox(width: 12),
                                      ],
                                      Flexible(
                                        child: Text(
                                          deckName,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: isCreateOption
                                                ? primaryPurple
                                                : Colors.black87,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
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
              onPressed: _confirmSelection,
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

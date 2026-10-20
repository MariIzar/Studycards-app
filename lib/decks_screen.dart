import 'package:flutter/material.dart';

import 'banco_de_dados/auth_helper.dart';
import 'banco_de_dados/sql_helper.dart';

class DecksScreen extends StatefulWidget {
  const DecksScreen({super.key});

  @override
  State<DecksScreen> createState() => _DecksScreenState();
}

class _DecksScreenState extends State<DecksScreen> {
  int? selectedDeckId;

  List<Map<String, dynamic>> decks = [];
  bool isLoading = true;
  String? errorMessage;

  static const Color primaryPurple = Color(0xFF6C5CE7);

  static const List<Color> deckColors = [
    Color(0xFF6C4DFF),
    Color(0xFF2ECC71),
    Color(0xFF3498DB),
    Color(0xFFF1C40F),
    Color(0xFFE91E63),
    Color(0xFF1ABC9C),
  ];

  @override
  void initState() {
    super.initState();
    _loadDecks();
  }

  Future<void> _loadDecks() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await SQLHelper.pegaDecks(usuarioId: Sessao.usuarioId);

      if (!mounted) return;

      setState(() {
        decks = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = 'Erro ao carregar decks: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _openCreateDeck() async {
    await Navigator.pushNamed(context, '/create-deck');

    if (!mounted) return;

    await _loadDecks();
  }

  Future<void> _openDeckDetails(int deckId) async {
    setState(() {
      selectedDeckId = deckId;
    });

    await Navigator.pushNamed(context, '/deck-details', arguments: deckId);

    if (!mounted) return;

    await _loadDecks();
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _editDeck(Map<String, dynamic> deck) async {
    final int deckId = (deck['id'] as num).toInt();

    final String originalName = deck['title']?.toString() ?? '';

    final int originalColor = (deck['color'] as num?)?.toInt() ?? 0xFF6C4DFF;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return _EditDeckDialog(
          initialName: originalName,
          initialColor: originalColor,
          colors: deckColors,
        );
      },
    );

    if (!mounted || result == null) return;

    try {
      final updatedRows = await SQLHelper.atualizaDeck(
        deckId,
        result['title'] as String,
        cor: result['color'] as int,
      );

      if (!mounted) return;

      if (updatedRows > 0) {
        await _loadDecks();
        _showMessage('Deck atualizado com sucesso!');
      } else {
        _showMessage('Deck não encontrado.');
      }
    } catch (e) {
      _showMessage('Erro ao editar deck: $e');
    }
  }

  Future<void> _deleteDeck(Map<String, dynamic> deck) async {
    final int deckId = (deck['id'] as num).toInt();

    final String deckName = deck['title']?.toString() ?? 'Sem nome';

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Excluir deck?',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Deseja realmente excluir "$deckName"?\n\n'
            'Todos os flashcards deste deck também '
            'serão excluídos. Essa ação não pode '
            'ser desfeita.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text(
                'Excluir',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await SQLHelper.apagaDeck(deckId);

      if (!mounted) return;

      final remaining = await SQLHelper.pegaUmDeck(deckId);

      if (!mounted) return;

      if (remaining.isEmpty) {
        if (selectedDeckId == deckId) {
          selectedDeckId = null;
        }

        await _loadDecks();
        _showMessage('Deck excluído com sucesso!');
      } else {
        _showMessage('Não foi possível excluir o deck.');
      }
    } catch (e) {
      _showMessage('Erro ao excluir deck: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Meus decks',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.search, color: Colors.black),
                    onPressed: () {
                      _showMessage('Pesquisa em desenvolvimento');
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadDecks,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Seus materiais de estudo',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Organize seus flashcards por decks.',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 20),

                      if (isLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: CircularProgressIndicator(
                              color: primaryPurple,
                            ),
                          ),
                        )
                      else if (errorMessage != null)
                        Center(
                          child: Column(
                            children: [
                              Text(
                                errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.red),
                              ),
                              TextButton(
                                onPressed: _loadDecks,
                                child: const Text('Tentar novamente'),
                              ),
                            ],
                          ),
                        )
                      else if (decks.isEmpty)
                        _buildEmptyState()
                      else
                        ...decks.map((deck) {
                          final int id = (deck['id'] as num).toInt();

                          final String title =
                              deck['title']?.toString() ?? 'Sem nome';

                          final int count =
                              (deck['cards_count'] as num?)?.toInt() ?? 0;

                          final int colorValue =
                              (deck['color'] as num?)?.toInt() ?? 0xFF6C4DFF;

                          return _buildDeckItem(
                            id: id,
                            title: title,
                            deckColor: Color(colorValue),
                            cardsCount:
                                '$count ${count == 1 ? 'card' : 'cards'}',
                            onTap: () => _openDeckDetails(id),
                            onEdit: () => _editDeck(deck),
                            onDelete: () => _deleteDeck(deck),
                          );
                        }),

                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _openCreateDeck,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryPurple,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'Criar novo deck',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Barra de navegação inferior
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  InkWell(
                    onTap: () {
                      Navigator.pushReplacementNamed(context, '/home');
                    },
                    child: _buildNavItem(Icons.home_outlined, 'Início'),
                  ),
                  _buildNavItem(Icons.style, 'Decks', active: true),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/create-flashcards');
                    },
                    child: Container(
                      width: 54,
                      height: 54,
                      decoration: const BoxDecoration(
                        color: primaryPurple,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.pushReplacementNamed(context, '/progress');
                    },
                    child: _buildNavItem(Icons.bar_chart_outlined, 'Progresso'),
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.pushReplacementNamed(context, '/profile');
                    },
                    child: _buildNavItem(Icons.person_outline, 'Perfil'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        children: [
          Icon(Icons.style_outlined, size: 52, color: primaryPurple),
          SizedBox(height: 16),
          Text(
            'Nenhum deck criado ainda',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Crie seu primeiro deck para organizar seus estudos.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildDeckItem({
    required int id,
    required String title,
    required Color deckColor,
    required String cardsCount,
    required VoidCallback onTap,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    final bool isSelected = selectedDeckId == id;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: deckColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? deckColor : deckColor.withOpacity(0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: deckColor.withOpacity(isSelected ? 0.15 : 0.05),
            blurRadius: isSelected ? 12 : 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: deckColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.style, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: deckColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            cardsCount,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: deckColor, size: 22),
                  ],
                ),
              ),
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Opções do deck',
            icon: const Icon(Icons.more_vert, color: Colors.black54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (value) {
              if (value == 'edit') {
                onEdit();
              } else if (value == 'delete') {
                onDelete();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, color: primaryPurple, size: 20),
                    SizedBox(width: 12),
                    Text('Editar'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.red, size: 20),
                    SizedBox(width: 12),
                    Text('Excluir', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, {bool active = false}) {
    final color = active ? primaryPurple : Colors.grey;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

// Diálogo separado para editar o deck.
// Isso evita descartar o TextEditingController
// antes de o diálogo terminar de fechar.

class _EditDeckDialog extends StatefulWidget {
  final String initialName;
  final int initialColor;
  final List<Color> colors;

  const _EditDeckDialog({
    required this.initialName,
    required this.initialColor,
    required this.colors,
  });

  @override
  State<_EditDeckDialog> createState() => _EditDeckDialogState();
}

class _EditDeckDialogState extends State<_EditDeckDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late int _selectedColor;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.initialName);

    _selectedColor = widget.initialColor;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.pop(context, {
      'title': _nameController.text.trim(),
      'color': _selectedColor,
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Editar deck',
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nome do deck',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                maxLength: 100,
                decoration: InputDecoration(
                  hintText: 'Nome do deck',
                  filled: true,
                  fillColor: const Color(0xFFF8F9FE),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Digite um nome para o deck';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              const Text(
                'Cor do deck',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: widget.colors.map((color) {
                  final int colorValue = color.toARGB32();
                  final bool isSelected = _selectedColor == colorValue;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedColor = colorValue;
                      });
                    },
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: color,
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
                              size: 20,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6C5CE7),
          ),
          child: const Text('Salvar', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

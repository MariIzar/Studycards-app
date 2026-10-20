import 'package:flutter/material.dart';

import 'banco_de_dados/sql_helper.dart';
import 'edit_flashcard.dart';

class DeckDetailsScreen extends StatefulWidget {
  final String title;

  const DeckDetailsScreen({super.key, this.title = ''});

  @override
  State<DeckDetailsScreen> createState() => _DeckDetailsScreenState();
}

class _DeckDetailsScreenState extends State<DeckDetailsScreen> {
  static const Color primaryPurple = Color(0xFF6C4DFF);
  static const Color backgroundColor = Color(0xFFF8F9FE);

  int? deckId;
  String deckTitle = '';
  List<Map<String, dynamic>> flashcards = [];

  bool isLoading = true;
  bool initialized = false;
  String? errorMessage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!initialized) {
      initialized = true;

      final arguments = ModalRoute.of(context)?.settings.arguments;

      if (arguments is int) {
        deckId = arguments;
        _loadDeck();
      } else {
        isLoading = false;
        errorMessage = 'Nenhum deck foi selecionado.';
      }
    }
  }

  // CARREGAR DECK E FLASHCARDS
  Future<void> _loadDeck() async {
    final id = deckId;
    if (id == null) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final deckResult = await SQLHelper.pegaUmDeck(id);
      final cardsResult = await SQLHelper.pegaFlashcardsDoDeck(id);

      if (!mounted) return;

      if (deckResult.isEmpty) {
        setState(() {
          isLoading = false;
          errorMessage = 'Este deck não foi encontrado.';
        });
        return;
      }

      setState(() {
        deckTitle = deckResult.first['title']?.toString() ?? 'Sem nome';
        flashcards = cardsResult;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = 'Erro ao carregar deck: $e';
      });
    }
  }

  // ESTATÍSTICAS DO DECK
  int get totalCards => flashcards.length;

  int get masteredCards {
    return flashcards.where((card) {
      return card['is_mastered'] == 1;
    }).length;
  }

  double get progress {
    if (totalCards == 0) return 0;
    return masteredCards / totalCards;
  }

  int get progressPercentage => (progress * 100).round();

  int get pendingCards {
    final now = DateTime.now();

    return flashcards.where((card) {
      final date = DateTime.tryParse(card['next_review']?.toString() ?? '');

      return date != null && !date.isAfter(now);
    }).length;
  }

  // MENSAGEM
  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  // CRIAR FLASHCARD
  Future<void> _addFlashcard() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        return const _FlashcardFormDialog(title: 'Novo flashcard');
      },
    );

    if (!mounted || result == null || deckId == null) return;

    try {
      await SQLHelper.adicionaFlashcard(
        deckId!,
        result['question']!,
        result['answer']!,
      );

      if (!mounted) return;

      await _loadDeck();
      _showMessage('Flashcard criado com sucesso!');
    } catch (e) {
      _showMessage('Erro ao criar flashcard: $e');
    }
  }

  // EDITAR FLASHCARD
  Future<void> _editFlashcard(Map<String, dynamic> card) async {
    final cardId = (card['id'] as num).toInt();

    final bool? changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditFlashcardScreen(flashcardId: cardId),
      ),
    );

    if (!mounted) return;

    if (changed == true) {
      await _loadDeck();
    }
  }

  // EXCLUIR FLASHCARD
  Future<void> _deleteFlashcard(Map<String, dynamic> card) async {
    final cardId = (card['id'] as num).toInt();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Excluir flashcard?',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text('Este flashcard será excluído permanentemente.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text(
                'Cancelar',
                style: TextStyle(color: primaryPurple),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) return;

    try {
      await SQLHelper.apagaFlashcard(cardId);

      final remaining = await SQLHelper.pegaUmFlashcard(cardId);

      if (!mounted) return;

      if (remaining.isNotEmpty) {
        _showMessage('Não foi possível excluir.');
        return;
      }

      await _loadDeck();
      _showMessage('Flashcard excluído!');
    } catch (e) {
      _showMessage('Erro ao excluir flashcard: $e');
    }
  }

  // INICIAR REVISÃO
  Future<void> _startReview() async {
    // Só impede a revisão se o deck estiver vazio.
    if (flashcards.isEmpty) {
      _showMessage('Adicione flashcards antes de começar.');
      return;
    }

    // Não verifica mais pendingCards.
    // O usuário pode estudar todos os cards do deck,
    // mesmo que a próxima revisão esteja agendada
    // para outro dia.
    await Navigator.pushNamed(context, '/study', arguments: deckId);

    // Atualiza o progresso quando voltar.
    if (mounted) {
      await _loadDeck();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,

        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),

        title: Text(
          deckTitle.isEmpty ? 'Detalhes do deck' : deckTitle,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),

        actions: [
          IconButton(
            tooltip: 'Atualizar',
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _loadDeck,
          ),
        ],
      ),

      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: primaryPurple),
                    )
                  : errorMessage != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(errorMessage!, textAlign: TextAlign.center),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      children: [
                        const SizedBox(height: 10),

                        // TÍTULO DO DECK
                        Text(
                          deckTitle,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          '$totalCards ${totalCards == 1 ? 'flashcard' : 'flashcards'}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 15,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // PROGRESSO DO DECK
                        Container(
                          padding: const EdgeInsets.all(20),
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Seu progresso',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),

                              const SizedBox(height: 6),

                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 12,
                                runSpacing: 4,
                                children: [
                                  Text(
                                    '$progressPercentage%',
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  Text(
                                    '$masteredCards de $totalCards cards dominados',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 8,
                                  backgroundColor: const Color(0xFFEBEBF5),
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        primaryPurple,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 28),

                        // TÍTULO DA LISTA
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Flashcards',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Adicionar flashcard',
                              onPressed: _addFlashcard,
                              icon: const Icon(
                                Icons.add_circle,
                                color: primaryPurple,
                                size: 30,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // LISTA DE FLASHCARDS
                        if (flashcards.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Column(
                              children: [
                                Icon(
                                  Icons.style_outlined,
                                  size: 44,
                                  color: primaryPurple,
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'Nenhum flashcard ainda',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Toque no botão + para adicionar seu primeiro flashcard.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        else
                          ...flashcards.map(
                            (card) => _buildFlashcardItem(card),
                          ),

                        const SizedBox(height: 20),

                        // BOTÃO COMEÇAR REVISÃO
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryPurple,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(50),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: _startReview,
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text(
                            'Começar revisão',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
            ),

            // BARRA DE NAVEGAÇÃO INFERIOR
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
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacementNamed(context, '/home');
                    },
                    child: _buildNavItem(Icons.home_outlined, 'Início'),
                  ),

                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: _buildNavItem(
                      Icons.style_outlined,
                      'Decks',
                      active: true,
                    ),
                  ),

                  GestureDetector(
                    onTap: () async {
                      await Navigator.pushNamed(context, '/create-flashcards');

                      if (mounted) {
                        await _loadDeck();
                      }
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

                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/progress');
                    },
                    child: _buildNavItem(Icons.bar_chart_outlined, 'Progresso'),
                  ),

                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/profile');
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

  // ITEM DE FLASHCARD NA LISTA
  Widget _buildFlashcardItem(Map<String, dynamic> card) {
    final question = card['question']?.toString() ?? '';
    final acertado = card['is_mastered'] == 1;
    // errado = já foi revisado e não está acertado (última resposta: Errei)
    final errado = !acertado && card['last_review'] != null;
    const verde = Color(0xFF2ECC71);
    const vermelho = Color(0xFFE53935);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: acertado
                  ? const Color(0xFFE6F9EE)
                  : errado
                      ? const Color(0xFFFDECEC)
                      : const Color(0xFFF0ECFF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              acertado
                  ? Icons.check_circle
                  : errado
                      ? Icons.cancel
                      : Icons.description,
              color: acertado
                  ? verde
                  : errado
                      ? vermelho
                      : primaryPurple,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: InkWell(
              onTap: () => _editFlashcard(card),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      acertado
                          ? 'Pergunta · Acertado'
                          : errado
                              ? 'Pergunta · Errado'
                              : 'Pergunta',
                      style: TextStyle(
                        color: acertado
                            ? verde
                            : errado
                                ? vermelho
                                : primaryPurple,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      question,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          PopupMenuButton<String>(
            tooltip: 'Opções do flashcard',
            icon: const Icon(Icons.more_vert, color: Colors.black38),
            onSelected: (value) {
              if (value == 'edit') {
                _editFlashcard(card);
              } else if (value == 'delete') {
                _deleteFlashcard(card);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, color: primaryPurple),
                    SizedBox(width: 8),
                    Text('Editar'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Excluir', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ITEM DA BARRA INFERIOR
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

// =====================================================
// FORMULÁRIO DE CRIAÇÃO DE FLASHCARDS
// =====================================================

class _FlashcardFormDialog extends StatefulWidget {
  final String title;

  const _FlashcardFormDialog({required this.title});

  @override
  State<_FlashcardFormDialog> createState() => _FlashcardFormDialogState();
}

class _FlashcardFormDialogState extends State<_FlashcardFormDialog> {
  static const Color primaryPurple = Color(0xFF6C4DFF);
  static const Color lightPurple = Color(0xFFF8F9FE);
  static const Color borderPurple = Color(0xFFE5DFFF);

  final formKey = GlobalKey<FormState>();

  late final TextEditingController questionController;
  late final TextEditingController answerController;

  @override
  void initState() {
    super.initState();

    questionController = TextEditingController();
    answerController = TextEditingController();
  }

  @override
  void dispose() {
    questionController.dispose();
    answerController.dispose();
    super.dispose();
  }

  // SALVAR FLASHCARD
  void _save() {
    if (!formKey.currentState!.validate()) return;

    Navigator.pop(context, <String, String>{
      'question': questionController.text.trim(),
      'answer': answerController.text.trim(),
    });
  }

  // CAMPO PERSONALIZADO
  Widget _buildFlashcardField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    int maxLines = 3,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: primaryPurple, size: 19),

            const SizedBox(width: 8),

            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        TextFormField(
          controller: controller,
          maxLines: maxLines,
          minLines: maxLines,
          textAlignVertical: TextAlignVertical.top,
          style: const TextStyle(fontSize: 15, color: Colors.black87),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 14, color: Color(0xFFAAAAAA)),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(16),

            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: borderPurple, width: 1.5),
            ),

            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: primaryPurple, width: 2),
            ),

            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),

            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.redAccent, width: 2),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Preencha o campo $label';
            }

            return null;
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: lightPurple,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // CABEÇALHO
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFECE7FF),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.style_rounded,
                        color: primaryPurple,
                        size: 25,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),

                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.close_rounded, color: Colors.grey),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                const Text(
                  'Preencha a pergunta e a resposta para adicionar um novo card ao seu deck.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 26),

                // CAMPO PERGUNTA
                _buildFlashcardField(
                  label: 'Pergunta',
                  hint: 'Digite sua pergunta aqui...',
                  controller: questionController,
                  icon: Icons.help_outline_rounded,
                  maxLines: 3,
                ),

                const SizedBox(height: 20),

                // CAMPO RESPOSTA
                _buildFlashcardField(
                  label: 'Resposta',
                  hint: 'Digite a resposta aqui...',
                  controller: answerController,
                  icon: Icons.lightbulb_outline_rounded,
                  maxLines: 3,
                ),

                const SizedBox(height: 28),

                // BOTÕES
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryPurple,
                          side: const BorderSide(
                            color: borderPurple,
                            width: 1.5,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryPurple,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: const Text(
                          'Salvar',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

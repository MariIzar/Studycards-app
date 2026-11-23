import 'package:flutter/material.dart';

import 'banco_de_dados/sql_helper.dart';
import 'edit_flashcard.dart';
import 'language_controller.dart';

// Traduções locais desta tela, acompanhando o idioma salvo.
String _deckTr(String pt, String en, String es) {
  switch (LanguageController.locale.value.languageCode) {
    case 'en':
      return en;
    case 'es':
      return es;
    default:
      return pt;
  }
}

class DeckDetailsScreen extends StatefulWidget {
  final String title;

  DeckDetailsScreen({super.key, this.title = ''});

  @override
  State<DeckDetailsScreen> createState() => _DeckDetailsScreenState();
}

class _DeckDetailsScreenState extends State<DeckDetailsScreen> {
  static const Color primaryPurple = Color(0xFF6C4DFF);

  int? deckId;
  String deckTitle = '';
  List<Map<String, dynamic>> flashcards = [];

  bool isLoading = true;
  bool initialized = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    LanguageController.locale.addListener(_onLocaleChanged);
  }

  void _onLocaleChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    LanguageController.locale.removeListener(_onLocaleChanged);
    super.dispose();
  }

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
        errorMessage = _deckTr(
          'Nenhum deck foi selecionado.',
          'No deck was selected.',
          'No se seleccionó ningún mazo.',
        );
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
          errorMessage = _deckTr(
            'Este deck não foi encontrado.',
            'This deck was not found.',
            'No se encontró este mazo.',
          );
        });
        return;
      }

      setState(() {
        deckTitle =
            deckResult.first['title']?.toString() ??
            _deckTr('Sem nome', 'Untitled', 'Sin nombre');
        flashcards = cardsResult;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = _deckTr(
          'Erro ao carregar deck: $e',
          'Error loading deck: $e',
          'Error al cargar el mazo: $e',
        );
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
      SnackBar(content: Text(message), duration: Duration(seconds: 2)),
    );
  }

  // CRIAR FLASHCARD
  Future<void> _addFlashcard() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        return _FlashcardFormDialog(
          title: _deckTr('Novo flashcard', 'New flashcard', 'Nueva tarjeta'),
        );
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
      _showMessage(
        _deckTr(
          'Flashcard criado com sucesso!',
          'Flashcard created successfully!',
          '¡Tarjeta creada correctamente!',
        ),
      );
    } catch (e) {
      _showMessage(
        _deckTr(
          'Erro ao criar flashcard: $e',
          'Error creating flashcard: $e',
          'Error al crear la tarjeta: $e',
        ),
      );
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
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            _deckTr(
              'Excluir flashcard?',
              'Delete flashcard?',
              '¿Eliminar tarjeta?',
            ),
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            _deckTr(
              'Este flashcard será excluído permanentemente.',
              'This flashcard will be permanently deleted.',
              'Esta tarjeta se eliminará permanentemente.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: Text(
                _deckTr('Cancelar', 'Cancel', 'Cancelar'),
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
              child: Text(_deckTr('Excluir', 'Delete', 'Eliminar')),
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
        _showMessage(
          _deckTr(
            'Não foi possível excluir.',
            'Could not delete.',
            'No se pudo eliminar.',
          ),
        );
        return;
      }

      await _loadDeck();
      _showMessage(
        _deckTr(
          'Flashcard excluído!',
          'Flashcard deleted!',
          '¡Tarjeta eliminada!',
        ),
      );
    } catch (e) {
      _showMessage(
        _deckTr(
          'Erro ao excluir flashcard: $e',
          'Error deleting flashcard: $e',
          'Error al eliminar la tarjeta: $e',
        ),
      );
    }
  }

  // INICIAR REVISÃO
  Future<void> _startReview() async {
    // Só impede a revisão se o deck estiver vazio.
    if (flashcards.isEmpty) {
      _showMessage(
        _deckTr(
          'Adicione flashcards antes de começar.',
          'Add flashcards before starting.',
          'Añade tarjetas antes de empezar.',
        ),
      );
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,

        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),

        title: Text(
          deckTitle.isEmpty
              ? _deckTr('Detalhes do deck', 'Deck details', 'Detalles del mazo')
              : deckTitle,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),

        actions: [
          IconButton(
            tooltip: _deckTr('Atualizar', 'Refresh', 'Actualizar'),
            icon: Icon(Icons.refresh, color: Colors.black),
            onPressed: _loadDeck,
          ),
        ],
      ),

      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: isLoading
                  ? Center(
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
                        SizedBox(height: 10),

                        // TÍTULO DO DECK
                        Text(
                          deckTitle,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),

                        SizedBox(height: 4),

                        Text(
                          '$totalCards ${totalCards == 1 ? _deckTr('flashcard', 'flashcard', 'tarjeta') : _deckTr('flashcards', 'flashcards', 'tarjetas')}',
                          style: TextStyle(color: Colors.grey, fontSize: 15),
                        ),

                        SizedBox(height: 20),

                        // PROGRESSO DO DECK
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 10,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _deckTr(
                                  'Seu progresso',
                                  'Your progress',
                                  'Tu progreso',
                                ),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface,
                                ),
                              ),

                              SizedBox(height: 6),

                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 12,
                                runSpacing: 4,
                                children: [
                                  Text(
                                    '$progressPercentage%',
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                    ),
                                  ),
                                  Text(
                                    _deckTr(
                                      '$masteredCards de $totalCards cards dominados',
                                      '$masteredCards of $totalCards cards mastered',
                                      '$masteredCards de $totalCards tarjetas dominadas',
                                    ),
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: 12),

                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 8,
                                  backgroundColor: Color(0xFFEBEBF5),
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        primaryPurple,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 28),

                        // TÍTULO DA LISTA
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _deckTr('Flashcards', 'Flashcards', 'Tarjetas'),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            IconButton(
                              tooltip: _deckTr(
                                'Adicionar flashcard',
                                'Add flashcard',
                                'Añadir tarjeta',
                              ),
                              onPressed: _addFlashcard,
                              icon: Icon(
                                Icons.add_circle,
                                color: primaryPurple,
                                size: 30,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 16),

                        // LISTA DE FLASHCARDS
                        if (flashcards.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.style_outlined,
                                  size: 44,
                                  color: primaryPurple,
                                ),
                                SizedBox(height: 12),
                                Text(
                                  _deckTr(
                                    'Nenhum flashcard ainda',
                                    'No flashcards yet',
                                    'Todavía no hay tarjetas',
                                  ),
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  _deckTr(
                                    'Toque no botão + para adicionar seu primeiro flashcard.',
                                    'Tap + to add your first flashcard.',
                                    'Toca + para añadir tu primera tarjeta.',
                                  ),
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

                        SizedBox(height: 20),

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
                          icon: Icon(Icons.play_arrow_rounded),
                          label: Text(
                            _deckTr(
                              'Começar revisão',
                              'Start review',
                              'Empezar repaso',
                            ),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),

                        SizedBox(height: 20),
                      ],
                    ),
            ),

            // BARRA DE NAVEGAÇÃO INFERIOR
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
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
                    child: _buildNavItem(
                      Icons.home_outlined,
                      _deckTr('Início', 'Home', 'Inicio'),
                    ),
                  ),

                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: _buildNavItem(
                      Icons.style_outlined,
                      _deckTr('Decks', 'Decks', 'Mazos'),
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
                      decoration: BoxDecoration(
                        color: primaryPurple,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.add, color: Colors.white, size: 28),
                    ),
                  ),

                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/progress');
                    },
                    child: _buildNavItem(
                      Icons.bar_chart_outlined,
                      _deckTr('Progresso', 'Progress', 'Progreso'),
                    ),
                  ),

                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/profile');
                    },
                    child: _buildNavItem(
                      Icons.person_outline,
                      _deckTr('Perfil', 'Profile', 'Perfil'),
                    ),
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
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: acertado
                  ? Color(0xFFE6F9EE)
                  : errado
                  ? Color(0xFFFDECEC)
                  : Color(0xFFF0ECFF),
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

          SizedBox(width: 12),

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
                          ? _deckTr(
                              'Pergunta · Acertado',
                              'Question · Correct',
                              'Pregunta · Correcta',
                            )
                          : errado
                          ? _deckTr(
                              'Pergunta · Errado',
                              'Question · Incorrect',
                              'Pregunta · Incorrecta',
                            )
                          : _deckTr('Pergunta', 'Question', 'Pregunta'),
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
                    SizedBox(height: 4),
                    Text(
                      question,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          PopupMenuButton<String>(
            tooltip: _deckTr(
              'Opções do flashcard',
              'Flashcard options',
              'Opciones de la tarjeta',
            ),
            icon: Icon(Icons.more_vert, color: Colors.black38),
            onSelected: (value) {
              if (value == 'edit') {
                _editFlashcard(card);
              } else if (value == 'delete') {
                _deleteFlashcard(card);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, color: primaryPurple),
                    SizedBox(width: 8),
                    Text(_deckTr('Editar', 'Edit', 'Editar')),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.red),
                    SizedBox(width: 8),
                    Text(
                      _deckTr('Excluir', 'Delete', 'Eliminar'),
                      style: TextStyle(color: Colors.red),
                    ),
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
        SizedBox(height: 4),
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

  _FlashcardFormDialog({required this.title});

  @override
  State<_FlashcardFormDialog> createState() => _FlashcardFormDialogState();
}

class _FlashcardFormDialogState extends State<_FlashcardFormDialog> {
  static const Color primaryPurple = Color(0xFF6C4DFF);
  static const Color borderPurple = Color(0xFFE5DFFF);

  final formKey = GlobalKey<FormState>();

  late final TextEditingController questionController;
  late final TextEditingController answerController;

  @override
  void initState() {
    super.initState();

    LanguageController.locale.addListener(_onLocaleChanged);
    questionController = TextEditingController();
    answerController = TextEditingController();
  }

  void _onLocaleChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    LanguageController.locale.removeListener(_onLocaleChanged);
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

            SizedBox(width: 8),

            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
              ),
            ),
          ],
        ),

        SizedBox(height: 10),

        TextFormField(
          controller: controller,
          maxLines: maxLines,
          minLines: maxLines,
          textAlignVertical: TextAlignVertical.top,
          style: TextStyle(fontSize: 15, color: Colors.black87),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: 14, color: Color(0xFFAAAAAA)),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            contentPadding: const EdgeInsets.all(16),

            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: borderPurple, width: 1.5),
            ),

            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: primaryPurple, width: 2),
            ),

            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.redAccent),
            ),

            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.redAccent, width: 2),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return _deckTr(
                'Preencha o campo $label',
                'Fill in the $label field',
                'Completa el campo $label',
              );
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
      backgroundColor: Theme.of(context).colorScheme.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 440),
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
                        color: Color(0xFFECE7FF),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.style_rounded,
                        color: primaryPurple,
                        size: 25,
                      ),
                    ),

                    SizedBox(width: 12),

                    Expanded(
                      child: Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),

                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: Icon(Icons.close_rounded, color: Colors.grey),
                    ),
                  ],
                ),

                SizedBox(height: 10),

                Text(
                  _deckTr(
                    'Preencha a pergunta e a resposta para adicionar um novo card ao seu deck.',
                    'Enter a question and answer to add a new card to your deck.',
                    'Escribe una pregunta y respuesta para añadir una tarjeta al mazo.',
                  ),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                    height: 1.4,
                  ),
                ),

                SizedBox(height: 26),

                // CAMPO PERGUNTA
                _buildFlashcardField(
                  label: _deckTr('Pergunta', 'Question', 'Pregunta'),
                  hint: _deckTr(
                    'Digite sua pergunta aqui...',
                    'Enter your question here...',
                    'Escribe tu pregunta aquí...',
                  ),
                  controller: questionController,
                  icon: Icons.help_outline_rounded,
                  maxLines: 3,
                ),

                SizedBox(height: 20),

                // CAMPO RESPOSTA
                _buildFlashcardField(
                  label: _deckTr('Resposta', 'Answer', 'Respuesta'),
                  hint: _deckTr(
                    'Digite a resposta aqui...',
                    'Enter your answer here...',
                    'Escribe tu respuesta aquí...',
                  ),
                  controller: answerController,
                  icon: Icons.lightbulb_outline_rounded,
                  maxLines: 3,
                ),

                SizedBox(height: 28),

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
                          side: BorderSide(color: borderPurple, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          _deckTr('Cancelar', 'Cancel', 'Cancelar'),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(width: 12),

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
                        icon: Icon(Icons.check_rounded, size: 18),
                        label: Text(
                          _deckTr('Salvar', 'Save', 'Guardar'),
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

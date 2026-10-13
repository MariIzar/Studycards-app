import 'package:flutter/material.dart';

import 'banco_de_dados/sql_helper.dart';

class EditFlashcardScreen extends StatefulWidget {
  final int flashcardId;

  const EditFlashcardScreen({super.key, required this.flashcardId});

  @override
  State<EditFlashcardScreen> createState() => _EditFlashcardScreenState();
}

class _EditFlashcardScreenState extends State<EditFlashcardScreen> {
  static const Color primaryPurple = Color(0xFF6C4DFF);
  static const Color backgroundColor = Color(0xFFF8F9FE);
  static const Color labelColor = Color(0xFF667085);

  final TextEditingController _questionController = TextEditingController();

  final TextEditingController _answerController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadFlashcard();
  }

  // CARREGAR FLASHCARD DO SQLITE
  Future<void> _loadFlashcard() async {
    try {
      final result = await SQLHelper.pegaUmFlashcard(widget.flashcardId);

      if (!mounted) return;

      if (result.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Flashcard não encontrado.';
        });
        return;
      }

      final flashcard = result.first;

      _questionController.text = flashcard['question']?.toString() ?? '';

      _answerController.text = flashcard['answer']?.toString() ?? '';

      setState(() {
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Erro ao carregar flashcard: $e';
      });
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  // SALVAR ALTERAÇÕES
  Future<void> _saveChanges() async {
    final question = _questionController.text.trim();
    final answer = _answerController.text.trim();

    if (question.isEmpty) {
      _showMessage('Digite a pergunta.');
      return;
    }

    if (answer.isEmpty) {
      _showMessage('Digite a resposta.');
      return;
    }

    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final updated = await SQLHelper.atualizaFlashcard(
        widget.flashcardId,
        question,
        answer,
      );

      if (!mounted) return;

      if (updated == 0) {
        _showMessage('Flashcard não encontrado.');
        return;
      }

      Navigator.pop(context, true);
    } catch (e) {
      _showMessage('Erro ao salvar alterações: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // EXCLUIR FLASHCARD
  Future<void> _deleteFlashcard() async {
    if (_isSaving) return;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Excluir flashcard?',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Tem certeza que deseja excluir este flashcard? '
            'Essa ação não pode ser desfeita.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text(
                'Excluir',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await SQLHelper.apagaFlashcard(widget.flashcardId);

      final remaining = await SQLHelper.pegaUmFlashcard(widget.flashcardId);

      if (!mounted) return;

      if (remaining.isNotEmpty) {
        _showMessage('Não foi possível excluir o flashcard.');
        return;
      }

      Navigator.pop(context, true);
    } catch (e) {
      _showMessage('Erro ao excluir flashcard: $e');
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
    _questionController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,

      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Editar flashcard',
          style: TextStyle(
            color: Color(0xFF101828),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: primaryPurple),
              )
            : _errorMessage != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_errorMessage!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('Voltar'),
                      ),
                    ],
                  ),
                ),
              )
            : Padding(
                padding: const EdgeInsets.fromLTRB(34, 40, 34, 20),
                child: Column(
                  children: [
                    Expanded(
                      child: ListView(
                        children: [
                          // CAMPO PERGUNTA
                          _buildTextCard(
                            title: 'Pergunta',
                            controller: _questionController,
                            height: 152,
                          ),

                          const SizedBox(height: 56),

                          // CAMPO RESPOSTA
                          _buildTextCard(
                            title: 'Resposta',
                            controller: _answerController,
                            height: 224,
                          ),
                        ],
                      ),
                    ),

                    // BOTÕES INFERIORES
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: OutlinedButton(
                            onPressed: _isSaving ? null : _deleteFlashcard,
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 54),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              side: const BorderSide(color: Colors.red),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Excluir',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _saveChanges,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryPurple,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(0, 54),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              _isSaving ? 'Aguarde...' : 'Salvar alterações',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),
                  ],
                ),
              ),
      ),
    );
  }

  // CARD DE PERGUNTA E RESPOSTA
  Widget _buildTextCard({
    required String title,
    required TextEditingController controller,
    required double height,
  }) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.20),
            blurRadius: 3,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(38, 24, 20, 12),
            child: Text(
              title,
              style: const TextStyle(
                color: labelColor,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
          ),

          const Divider(height: 1, thickness: 0.8, color: labelColor),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(38, 16, 20, 12),
              child: TextField(
                controller: controller,
                expands: true,
                maxLines: null,
                minLines: null,
                keyboardType: TextInputType.multiline,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                style: const TextStyle(fontSize: 16, color: Color(0xFF101828)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

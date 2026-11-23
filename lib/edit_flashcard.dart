import 'package:flutter/material.dart';

import 'banco_de_dados/sql_helper.dart';
import 'language_controller.dart';

class EditFlashcardScreen extends StatefulWidget {
  final int flashcardId;

  const EditFlashcardScreen({super.key, required this.flashcardId});

  @override
  State<EditFlashcardScreen> createState() => _EditFlashcardScreenState();
}

class _EditFlashcardScreenState extends State<EditFlashcardScreen> {
  static const primaryPurple = Color(0xFF6C4DFF);

  final _questionController = TextEditingController();
  final _answerController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  String _tr(String pt, String en, String es) {
    switch (LanguageController.locale.value.languageCode) {
      case 'en':
        return en;
      case 'es':
        return es;
      default:
        return pt;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadFlashcard();
  }

  Future<void> _loadFlashcard() async {
    try {
      final result = await SQLHelper.pegaUmFlashcard(widget.flashcardId);
      if (!mounted) return;

      if (result.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = _tr(
            'Flashcard não encontrado.',
            'Flashcard not found.',
            'No se encontró la tarjeta.',
          );
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
      debugPrint('Erro ao carregar flashcard: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = _tr(
          'Erro ao carregar flashcard.',
          'Could not load flashcard.',
          'No se pudo cargar la tarjeta.',
        );
      });
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _saveChanges() async {
    if (_isSaving || _isLoading) return;

    final question = _questionController.text.trim();
    final answer = _answerController.text.trim();

    if (question.isEmpty) {
      _showMessage(
        _tr('Digite a pergunta.', 'Enter a question.', 'Escribe la pregunta.'),
      );
      return;
    }
    if (answer.isEmpty) {
      _showMessage(
        _tr('Digite a resposta.', 'Enter an answer.', 'Escribe la respuesta.'),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);

    try {
      final updated = await SQLHelper.atualizaFlashcard(
        widget.flashcardId,
        question,
        answer,
      );
      if (!mounted) return;
      if (updated == 0) {
        _showMessage(
          _tr(
            'Flashcard não encontrado.',
            'Flashcard not found.',
            'No se encontró la tarjeta.',
          ),
        );
        return;
      }
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('Erro ao salvar flashcard: $e');
      _showMessage(
        _tr(
          'Erro ao salvar alterações.',
          'Could not save changes.',
          'No se pudieron guardar los cambios.',
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteFlashcard() async {
    if (_isSaving || _isLoading) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          _tr('Excluir flashcard?', 'Delete flashcard?', '¿Eliminar tarjeta?'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          _tr(
            'Tem certeza que deseja excluir este flashcard? Essa ação não pode ser desfeita.',
            'Are you sure you want to delete this flashcard? This action cannot be undone.',
            '¿Seguro que quieres eliminar esta tarjeta? Esta acción no se puede deshacer.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(_tr('Cancelar', 'Cancel', 'Cancelar')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              _tr('Excluir', 'Delete', 'Eliminar'),
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) return;
    setState(() => _isSaving = true);

    try {
      await SQLHelper.apagaFlashcard(widget.flashcardId);
      final remaining = await SQLHelper.pegaUmFlashcard(widget.flashcardId);
      if (!mounted) return;
      if (remaining.isNotEmpty) {
        _showMessage(
          _tr(
            'Não foi possível excluir o flashcard.',
            'Could not delete the flashcard.',
            'No se pudo eliminar la tarjeta.',
          ),
        );
        return;
      }
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('Erro ao excluir flashcard: $e');
      _showMessage(
        _tr(
          'Erro ao excluir flashcard.',
          'Error deleting flashcard.',
          'Error al eliminar la tarjeta.',
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
    return ValueListenableBuilder<Locale>(
      valueListenable: LanguageController.locale,
      builder: (context, locale, child) {
        final theme = Theme.of(context);
        final colors = theme.colorScheme;
        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: theme.scaffoldBackgroundColor,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            foregroundColor: colors.onSurface,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _isSaving ? null : () => Navigator.pop(context),
            ),
            title: Text(
              _tr('Editar flashcard', 'Edit flashcard', 'Editar tarjeta'),
              style: TextStyle(
                color: colors.onSurface,
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
                            onPressed: () => Navigator.pop(context),
                            child: Text(_tr('Voltar', 'Back', 'Volver')),
                          ),
                        ],
                      ),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                    child: Column(
                      children: [
                        Expanded(
                          child: ListView(
                            children: [
                              _buildTextCard(
                                title: _tr('Pergunta', 'Question', 'Pregunta'),
                                controller: _questionController,
                                height: 152,
                              ),
                              const SizedBox(height: 30),
                              _buildTextCard(
                                title: _tr('Resposta', 'Answer', 'Respuesta'),
                                controller: _answerController,
                                height: 224,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _isSaving ? null : _deleteFlashcard,
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(0, 54),
                                  side: const BorderSide(color: Colors.red),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  _tr('Excluir', 'Delete', 'Eliminar'),
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
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
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: _isSaving
                                    ? const SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        _tr(
                                          'Salvar alterações',
                                          'Save changes',
                                          'Guardar cambios',
                                        ),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
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
        );
      },
    );
  }

  Widget _buildTextCard({
    required String title,
    required TextEditingController controller,
    required double height,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Text(
              title,
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
          ),
          Divider(height: 1, color: colors.outlineVariant),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: TextField(
                controller: controller,
                enabled: !_isSaving,
                expands: true,
                maxLines: null,
                minLines: null,
                keyboardType: TextInputType.multiline,
                textAlignVertical: TextAlignVertical.top,
                style: TextStyle(fontSize: 16, color: colors.onSurface),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import 'banco_de_dados/sql_helper.dart';
import 'language_controller.dart';

class CreateManualFlashcardScreen extends StatefulWidget {
  const CreateManualFlashcardScreen({super.key});

  @override
  State<CreateManualFlashcardScreen> createState() =>
      _CreateManualFlashcardScreenState();
}

class _CreateManualFlashcardScreenState
    extends State<CreateManualFlashcardScreen> {
  final _questionController = TextEditingController();
  final _answerController = TextEditingController();
  bool _saving = false;

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
  void dispose() {
    _questionController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _save() async {
    if (_saving) return;

    final question = _questionController.text.trim();
    final answer = _answerController.text.trim();

    if (question.isEmpty || answer.isEmpty) {
      _message(
        _tr(
          'Preencha a pergunta e a resposta.',
          'Enter both the question and the answer.',
          'Completa la pregunta y la respuesta.',
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _saving = true);

    try {
      final selectedDeck = await Navigator.pushNamed(context, '/select-deck');
      if (!mounted) return;
      if (selectedDeck is! int) return;

      await SQLHelper.adicionaFlashcard(selectedDeck, question, answer);
      if (!mounted) return;

      // Retorna sucesso à tela anterior sem depender de uma rota de home.
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('Erro ao criar flashcard manual: $e');
      _message(
        _tr(
          'Não foi possível salvar o flashcard. Tente novamente.',
          'Could not save the flashcard. Please try again.',
          'No se pudo guardar la tarjeta. Inténtalo de nuevo.',
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LanguageController.locale,
      builder: (context, locale, child) {
        final colors = Theme.of(context).colorScheme;
        return Scaffold(
          appBar: AppBar(
            title: Text(
              _tr(
                'Criar card manualmente',
                'Create card manually',
                'Crear tarjeta manualmente',
              ),
            ),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      children: [
                        TextField(
                          controller: _questionController,
                          enabled: !_saving,
                          maxLines: 4,
                          minLines: 2,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            labelText: _tr('Pergunta', 'Question', 'Pregunta'),
                            hintText: _tr(
                              'Digite a pergunta do flashcard',
                              'Enter the flashcard question',
                              'Escribe la pregunta de la tarjeta',
                            ),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _answerController,
                          enabled: !_saving,
                          maxLines: 7,
                          minLines: 3,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            labelText: _tr('Resposta', 'Answer', 'Respuesta'),
                            hintText: _tr(
                              'Digite a resposta do flashcard',
                              'Enter the flashcard answer',
                              'Escribe la respuesta de la tarjeta',
                            ),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C4DFF),
                        foregroundColor: Colors.white,
                      ),
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save),
                      label: Text(
                        _saving
                            ? _tr('Salvando...', 'Saving...', 'Guardando...')
                            : _tr(
                                'Salvar no deck',
                                'Save to deck',
                                'Guardar en el mazo',
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

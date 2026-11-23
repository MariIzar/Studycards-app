import 'package:flutter/material.dart';

import 'banco_de_dados/auth_helper.dart';
import 'banco_de_dados/sql_helper.dart';
import 'banco_de_dados/ai_storage_helper.dart';
import 'services/material_storage_service.dart';
import 'language_controller.dart';

class GeneratedFlashcardsScreen extends StatefulWidget {
  const GeneratedFlashcardsScreen({super.key});

  @override
  State<GeneratedFlashcardsScreen> createState() =>
      _GeneratedFlashcardsScreenState();
}

class _GeneratedFlashcardsScreenState extends State<GeneratedFlashcardsScreen> {
  static const Color purple = Color(0xFF6C4DFF);

  bool _saving = false;
  bool _initialized = false;

  Map<String, dynamic> _data = {};
  List<Map<String, dynamic>> _cards = [];

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
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_initialized) return;
    _initialized = true;

    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is Map) {
      _data = Map<String, dynamic>.from(args);

      final raw = _data['cards'];

      if (raw is List) {
        _cards = raw
            .whereType<Map>()
            .map((card) => Map<String, dynamic>.from(card))
            .where((card) {
              final question = card['question']?.toString().trim() ?? '';
              final answer = card['answer']?.toString().trim() ?? '';

              return question.isNotEmpty && answer.isNotEmpty;
            })
            .toList();
      }
    }
  }

  Future<void> _save() async {
    if (_saving || _cards.isEmpty) return;

    final deckId = await Navigator.pushNamed(context, '/select-deck');

    if (!mounted || deckId is! int) return;

    setState(() {
      _saving = true;
    });

    try {
      final cardsToSave = _cards.map<Map<String, String>>((card) {
        return {
          'question': card['question']?.toString().trim() ?? '',
          'answer': card['answer']?.toString().trim() ?? '',
        };
      }).toList();

      // Salva os flashcards no deck selecionado.
      await SQLHelper.adicionaFlashcardsEmLote(deckId, cardsToSave);

      if (!mounted) return;

      // O material original é arquivado separadamente.
      // Uma falha aqui não significa que os cards não
      // tenham sido salvos no deck.
      bool materialArquivado = true;

      try {
        final localPath = await MaterialStorageService.saveCopy(
          _data['localFilePath']?.toString(),
        );

        final sourceName = _data['sourceName']?.toString();

        final isPdf = sourceName?.toLowerCase().endsWith('.pdf') ?? false;

        await AIStorageHelper.salvaMaterial(
          titulo:
              (_data['title'] ??
                      _tr(
                        'Material de estudo',
                        'Study material',
                        'Material de estudio',
                      ))
                  .toString(),
          nomeArquivo: sourceName,
          caminhoArquivo: localPath,
          tipo: isPdf ? 'pdf' : 'image_or_text',
          resumo: _data['summary']?.toString(),
          usuarioId: Sessao.usuarioId,
        );
      } catch (e) {
        materialArquivado = false;

        debugPrint('Erro ao arquivar material original: $e');
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            materialArquivado
                ? _tr(
                    'Flashcards salvos no deck com sucesso!',
                    'Flashcards saved to the deck successfully!',
                    '¡Flashcards guardados en el mazo correctamente!',
                  )
                : _tr(
                    'Flashcards salvos! Não foi possível arquivar o material original.',
                    'Flashcards saved! The original material could not be archived.',
                    '¡Flashcards guardados! No se pudo archivar el material original.',
                  ),
          ),
          duration: const Duration(seconds: 3),
        ),
      );

      Navigator.popUntil(context, ModalRoute.withName('/home'));
    } catch (e) {
      debugPrint('Erro ao salvar flashcards: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _tr(
              'Não foi possível salvar os flashcards. Tente novamente.',
              'Could not save the flashcards. Please try again.',
              'No se pudieron guardar las tarjetas. Inténtalo de nuevo.',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Widget _buildFlashcard(
    BuildContext context,
    Map<String, dynamic> card,
    int index,
  ) {
    final colors = Theme.of(context).colorScheme;

    final question = card['question']?.toString() ?? '';

    final answer = card['answer']?.toString() ?? '';

    final topic = card['topic']?.toString().trim() ?? '';

    return Card(
      color: colors.surface,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_tr('PERGUNTA', 'QUESTION', 'PREGUNTA')} ${index + 1}',
              style: const TextStyle(
                color: purple,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              question,
              style: TextStyle(
                color: colors.onSurface,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),

            const Divider(height: 22),

            Text(
              _tr('RESPOSTA', 'ANSWER', 'RESPUESTA'),
              style: const TextStyle(
                color: purple,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),

            const SizedBox(height: 5),

            Text(answer, style: TextStyle(color: colors.onSurface)),

            if (topic.isNotEmpty) ...[
              const SizedBox(height: 8),

              Text(
                '${_tr('Assunto', 'Topic', 'Tema')}: $topic',
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LanguageController.locale,
      builder: (context, locale, child) {
        final theme = Theme.of(context);
        final colors = theme.colorScheme;

        final title =
            (_data['title'] ??
                    _tr(
                      'Seu novo material',
                      'Your new material',
                      'Tu nuevo material',
                    ))
                .toString();

        final subject =
            (_data['subject'] ??
                    _tr(
                      'Matéria identificada pela IA',
                      'Subject identified by AI',
                      'Materia identificada por IA',
                    ))
                .toString();

        final summary = _data['summary']?.toString().trim() ?? '';

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,

          appBar: AppBar(
            backgroundColor: Colors.transparent,
            foregroundColor: colors.onSurface,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            title: Text(
              _tr(
                'Flashcards gerados',
                'Generated flashcards',
                'Flashcards generados',
              ),
              style: TextStyle(
                color: colors.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          body: _cards.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _tr(
                        'Nenhum flashcard válido foi recebido.',
                        'No valid flashcards were received.',
                        'No se recibieron tarjetas válidas.',
                      ),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 16,
                      ),
                    ),
                  ),
                )
              : SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Column(
                      children: [
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: colors.onSurface,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          '${_cards.length} ${_cards.length == 1 ? _tr('card gerado', 'card generated', 'tarjeta generada') : _tr('cards gerados', 'cards generated', 'tarjetas generadas')} • $subject',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),

                        if (summary.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Text(
                              summary,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: colors.onSurfaceVariant),
                            ),
                          ),

                        const SizedBox(height: 12),

                        Expanded(
                          child: ListView.builder(
                            itemCount: _cards.length,
                            itemBuilder: (context, index) {
                              return _buildFlashcard(
                                context,
                                _cards[index],
                                index,
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 12),

                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: _saving ? null : _save,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: purple,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: purple.withValues(
                                alpha: 0.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(13),
                              ),
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
                                : const Icon(Icons.save_alt),
                            label: Text(
                              _saving
                                  ? _tr(
                                      'Salvando...',
                                      'Saving...',
                                      'Guardando...',
                                    )
                                  : _tr(
                                      'Salvar no deck',
                                      'Save to deck',
                                      'Guardar en el mazo',
                                    ),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }
}

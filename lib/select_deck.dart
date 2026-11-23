import 'package:flutter/material.dart';

import 'banco_de_dados/auth_helper.dart';
import 'banco_de_dados/sql_helper.dart';
import 'language_controller.dart';

class SelectDeckScreen extends StatefulWidget {
  const SelectDeckScreen({super.key});

  @override
  State<SelectDeckScreen> createState() => _SelectDeckScreenState();
}

class _SelectDeckScreenState extends State<SelectDeckScreen> {
  static const Color primaryPurple = Color(0xFF6C4DFF);

  int? selectedDeckId;

  List<Map<String, dynamic>> decks = [];

  bool isLoading = true;
  bool isCreating = false;

  bool hasError = false;

  int _loadVersion = 0;

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
    _loadDecks();
  }

  @override
  void dispose() {
    _loadVersion++;
    super.dispose();
  }

  int? _deckId(Map<String, dynamic> deck) {
    final value = deck['id'];

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '');
  }

  // CARREGAR DECKS DO SQLITE
  Future<void> _loadDecks() async {
    if (!mounted) return;

    final version = ++_loadVersion;

    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      final result = await SQLHelper.pegaDecks(usuarioId: Sessao.usuarioId);

      if (!mounted || version != _loadVersion) {
        return;
      }

      setState(() {
        decks = result;
        isLoading = false;
        hasError = false;

        // Limpa a seleção se o deck não existir mais.
        if (selectedDeckId != null &&
            !decks.any((deck) => _deckId(deck) == selectedDeckId)) {
          selectedDeckId = null;
        }
      });
    } catch (e) {
      debugPrint('Erro ao carregar decks: $e');

      if (!mounted || version != _loadVersion) {
        return;
      }

      setState(() {
        isLoading = false;
        hasError = true;
      });
    }
  }

  // CRIAR UM DECK SEM SAIR DO FLUXO
  Future<void> _createDeck() async {
    if (isCreating || isLoading) return;

    setState(() {
      isCreating = true;
    });

    try {
      final createdId = await Navigator.pushNamed(context, '/create-deck');

      if (!mounted) return;

      await _loadDecks();

      if (!mounted) return;

      if (createdId is int && decks.any((deck) => _deckId(deck) == createdId)) {
        setState(() {
          selectedDeckId = createdId;
        });
      }
    } catch (e) {
      debugPrint('Erro ao criar/abrir deck: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _tr(
              'Não foi possível abrir a criação de deck.',
              'Could not open deck creation.',
              'No se pudo abrir la creación de mazos.',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isCreating = false;
        });
      }
    }
  }

  // CONFIRMAR SELEÇÃO
  void _confirmSelection() {
    if (isLoading || isCreating || hasError) {
      return;
    }

    final id = selectedDeckId;

    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _tr(
              'Selecione um deck primeiro.',
              'Select a deck first.',
              'Selecciona un mazo primero.',
            ),
          ),
        ),
      );
      return;
    }

    final existe = decks.any((deck) => _deckId(deck) == id);

    if (!existe) {
      setState(() {
        selectedDeckId = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _tr(
              'O deck selecionado não está mais disponível.',
              'The selected deck is no longer available.',
              'El mazo seleccionado ya no está disponible.',
            ),
          ),
        ),
      );
      return;
    }

    // Devolve o ID à tela que abriu esta seleção.
    Navigator.pop(context, id);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LanguageController.locale,
      builder: (context, locale, child) {
        final dark = Theme.of(context).brightness == Brightness.dark;

        final background = dark
            ? const Color(0xFF141320)
            : const Color(0xFFF8F7FF);

        final surface = dark ? const Color(0xFF242333) : Colors.white;

        final text = dark ? Colors.white : const Color(0xFF191B31);

        final secondary = dark ? Colors.white60 : const Color(0xFF73798B);

        final border = dark ? const Color(0xFF454357) : const Color(0xFFE7E5F2);

        Widget deckItem({
          required String title,
          required VoidCallback? onTap,
          bool selected = false,
          bool createOption = false,
        }) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Material(
              color: surface,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selected ? primaryPurple : border,
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      if (createOption) ...[
                        const Icon(Icons.add, color: primaryPurple, size: 22),
                        const SizedBox(width: 12),
                      ] else ...[
                        Icon(
                          Icons.style_outlined,
                          color: selected ? primaryPurple : secondary,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                      ],

                      Expanded(
                        child: Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: createOption ? primaryPurple : text,
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      if (selected)
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
                        Icon(Icons.chevron_right, color: secondary, size: 22),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: background,
          appBar: AppBar(
            backgroundColor: background,
            foregroundColor: text,
            elevation: 0,
            centerTitle: true,
            title: Text(
              _tr('Salvar flashcards', 'Save flashcards', 'Guardar tarjetas'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _tr('Escolha um deck:', 'Choose a deck:', 'Elige un mazo:'),
                    style: TextStyle(color: secondary, fontSize: 15),
                  ),

                  const SizedBox(height: 16),

                  // LISTA DE DECKS
                  Expanded(
                    child: isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: primaryPurple,
                            ),
                          )
                        : hasError
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 44,
                                  color: secondary,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _tr(
                                    'Não foi possível carregar os decks.',
                                    'Could not load the decks.',
                                    'No se pudieron cargar los mazos.',
                                  ),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: text),
                                ),
                                const SizedBox(height: 12),
                                TextButton.icon(
                                  onPressed: _loadDecks,
                                  icon: const Icon(Icons.refresh),
                                  label: Text(
                                    _tr(
                                      'Tentar novamente',
                                      'Try again',
                                      'Intentar de nuevo',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView(
                            children: [
                              if (decks.isEmpty) ...[
                                const SizedBox(height: 36),
                                Center(
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.auto_stories_outlined,
                                        size: 54,
                                        color: secondary,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        _tr(
                                          'Você ainda não tem decks.',
                                          'You do not have any decks yet.',
                                          'Todavía no tienes mazos.',
                                        ),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: text,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        _tr(
                                          'Crie um deck para organizar seus flashcards.',
                                          'Create a deck to organize your flashcards.',
                                          'Crea un mazo para organizar tus tarjetas.',
                                        ),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: secondary,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 30),
                              ],

                              // DECKS EXISTENTES
                              for (final deck in decks)
                                deckItem(
                                  title:
                                      deck['title']
                                              ?.toString()
                                              .trim()
                                              .isNotEmpty ==
                                          true
                                      ? deck['title'].toString()
                                      : _tr(
                                          'Sem nome',
                                          'Untitled',
                                          'Sin nombre',
                                        ),
                                  selected: selectedDeckId == _deckId(deck),
                                  onTap: isCreating
                                      ? null
                                      : () {
                                          setState(() {
                                            selectedDeckId = _deckId(deck);
                                          });
                                        },
                                ),

                              // CRIAR NOVO DECK
                              deckItem(
                                title: _tr(
                                  'Criar novo deck',
                                  'Create new deck',
                                  'Crear nuevo mazo',
                                ),
                                createOption: true,
                                onTap: isCreating ? null : _createDeck,
                              ),
                            ],
                          ),
                  ),

                  const SizedBox(height: 10),

                  // CONFIRMAR SELEÇÃO
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryPurple,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: primaryPurple.withValues(
                        alpha: 0.4,
                      ),
                      minimumSize: const Size.fromHeight(52),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed:
                        selectedDeckId != null &&
                            !isLoading &&
                            !isCreating &&
                            !hasError
                        ? _confirmSelection
                        : null,
                    child: isCreating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _tr('Salvar', 'Save', 'Guardar'),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),

                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';

import 'banco_de_dados/auth_helper.dart';
import 'banco_de_dados/sql_helper.dart';
import 'language_controller.dart';

class CreateDeckScreen extends StatefulWidget {
  const CreateDeckScreen({super.key});

  @override
  State<CreateDeckScreen> createState() => _CreateDeckScreenState();
}

class _CreateDeckScreenState extends State<CreateDeckScreen> {
  final TextEditingController _nameController = TextEditingController();

  static const Color primaryPurple = Color(0xFF6C4DFF);

  static const List<Color> deckColors = [
    Color(0xFF6C4DFF),
    Color(0xFF2ECC71),
    Color(0xFF3498DB),
    Color(0xFFF1C40F),
    Color(0xFFE91E63),
    Color(0xFF1ABC9C),
  ];

  int selectedColorIndex = 0;
  bool _isSaving = false;

  String _traduzir(String pt, String en, String es) {
    switch (LanguageController.locale.value.languageCode) {
      case 'en':
        return en;
      case 'es':
        return es;
      default:
        return pt;
    }
  }

  Future<void> _saveDeck() async {
    if (_isSaving) return;

    final String name = _nameController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _traduzir(
              'Digite o nome do deck!',
              'Enter a deck name!',
              '¡Introduce el nombre del mazo!',
            ),
          ),
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isSaving = true;
    });

    try {
      final int id = await SQLHelper.adicionaDeck(
        name,
        usuarioId: Sessao.usuarioId,
        cor: deckColors[selectedColorIndex].toARGB32(),
      );

      if (!mounted) return;

      Navigator.pop(context, id);
    } catch (e) {
      if (!mounted) return;

      debugPrint('Erro ao criar deck: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _traduzir(
              'Não foi possível criar o deck. Tente novamente.',
              'Could not create the deck. Please try again.',
              'No se pudo crear el mazo. Inténtalo de nuevo.',
            ),
          ),
        ),
      );
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
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LanguageController.locale,
      builder: (context, idiomaAtual, child) {
        final tema = Theme.of(context);
        final cores = tema.colorScheme;

        return Scaffold(
          backgroundColor: tema.scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            foregroundColor: cores.onSurface,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _isSaving ? null : () => Navigator.pop(context),
            ),
            title: Text(
              _traduzir('Novo deck', 'New deck', 'Nuevo mazo'),
              style: TextStyle(
                color: cores.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ListView(
                      children: [
                        // Nome do deck
                        Text(
                          _traduzir(
                            'Nome do deck',
                            'Deck name',
                            'Nombre del mazo',
                          ),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: cores.onSurfaceVariant,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Container(
                          decoration: BoxDecoration(
                            color: cores.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: cores.outlineVariant.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ),
                          child: TextField(
                            controller: _nameController,
                            enabled: !_isSaving,
                            maxLength: 100,
                            textCapitalization: TextCapitalization.sentences,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _saveDeck(),
                            style: TextStyle(color: cores.onSurface),
                            decoration: InputDecoration(
                              hintText: _traduzir(
                                'Ex: Matemática',
                                'E.g. Mathematics',
                                'Ej.: Matemáticas',
                              ),
                              hintStyle: TextStyle(
                                color: cores.onSurfaceVariant,
                              ),
                              border: InputBorder.none,
                              counterText: '',
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Seleção da cor
                        Text(
                          _traduzir(
                            'Cor do deck',
                            'Deck color',
                            'Color del mazo',
                          ),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: cores.onSurfaceVariant,
                          ),
                        ),

                        const SizedBox(height: 12),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cores.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: cores.outlineVariant.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ),
                          child: Wrap(
                            spacing: 14,
                            runSpacing: 14,
                            children: List.generate(deckColors.length, (index) {
                              final bool isSelected =
                                  selectedColorIndex == index;

                              return Semantics(
                                button: true,
                                selected: isSelected,
                                label: _traduzir(
                                  'Selecionar cor ${index + 1}',
                                  'Select color ${index + 1}',
                                  'Seleccionar color ${index + 1}',
                                ),
                                child: GestureDetector(
                                  onTap: _isSaving
                                      ? null
                                      : () {
                                          setState(() {
                                            selectedColorIndex = index;
                                          });
                                        },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: deckColors[index],
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected
                                            ? cores.onSurface
                                            : Colors.transparent,
                                        width: 3,
                                      ),
                                    ),
                                    child: isSelected
                                        ? const Icon(
                                            Icons.check,
                                            color: Colors.white,
                                            size: 22,
                                          )
                                        : null,
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Botão criar deck
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveDeck,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryPurple,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: primaryPurple.withValues(
                          alpha: 0.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _traduzir(
                                'Criar deck',
                                'Create deck',
                                'Crear mazo',
                              ),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
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

import 'package:flutter/material.dart';

import 'banco_de_dados/auth_helper.dart';
import 'banco_de_dados/sql_helper.dart';
import 'banco_de_dados/repeticao_espacada.dart';
import 'language_controller.dart';

class StudyScreen extends StatefulWidget {
  const StudyScreen({super.key});

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> {
  static const Color primaryPurple = Color(0xFF6C4DFF);

  int? deckId;

  bool initialized = false;
  bool isLoading = true;
  bool isSaving = false;
  bool showAnswer = false;
  bool askedAboutMastered = false;

  int currentIndex = 0;
  int _loadVersion = 0;

  String? errorMessage;

  List<Map<String, dynamic>> flashcards = [];

  int correctAnswers = 0;
  int difficultAnswers = 0;
  int wrongAnswers = 0;
  int easyAnswers = 0;
  int veryEasyAnswers = 0;

  DateTime? sessionStart;

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

  bool get _dark => Theme.of(context).brightness == Brightness.dark;

  Color get _background =>
      _dark ? const Color(0xFF141320) : const Color(0xFFF8F7FF);

  Color get _surface => _dark ? const Color(0xFF242333) : Colors.white;

  Color get _text => _dark ? Colors.white : const Color(0xFF191B31);

  Color get _secondary => _dark ? Colors.white60 : const Color(0xFF73798B);

  Color get _track => _dark ? const Color(0xFF454357) : const Color(0xFFEBEBF5);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!initialized) {
      initialized = true;

      final arguments = ModalRoute.of(context)?.settings.arguments;

      if (arguments is int) {
        deckId = arguments;
      }

      _loadFlashcards();
    }
  }

  @override
  void dispose() {
    _loadVersion++;
    super.dispose();
  }

  Future<void> _loadFlashcards() async {
    if (!mounted) return;

    final version = ++_loadVersion;

    setState(() {
      isLoading = true;
      errorMessage = null;
      isSaving = false;
      askedAboutMastered = false;
    });

    try {
      final result = deckId != null
          ? await SQLHelper.pegaFlashcardsDoDeck(deckId!)
          : await SQLHelper.pegaFlashcardsPendentes(
              usuarioId: Sessao.usuarioId,
            );

      if (!mounted || version != _loadVersion) return;

      setState(() {
        flashcards = result;
        currentIndex = 0;
        showAnswer = false;

        isLoading = false;
        isSaving = false;

        correctAnswers = 0;
        difficultAnswers = 0;
        wrongAnswers = 0;
        easyAnswers = 0;
        veryEasyAnswers = 0;

        sessionStart = DateTime.now();
      });

      if (deckId != null && result.isNotEmpty) {
        await _stopAtMasteredBoundary(0);
      }
    } catch (e) {
      debugPrint('Erro ao carregar flashcards: $e');

      if (!mounted || version != _loadVersion) return;

      setState(() {
        isLoading = false;
        errorMessage = _tr(
          'Não foi possível carregar os flashcards.',
          'Could not load the flashcards.',
          'No se pudieron cargar las tarjetas.',
        );
      });
    }
  }

  Map<String, dynamic> get currentCard {
    return flashcards[currentIndex];
  }

  Future<void> _evaluateCard(Avaliacao avaliacao) async {
    if (isSaving ||
        flashcards.isEmpty ||
        !showAnswer ||
        currentIndex >= flashcards.length) {
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final cardId = (currentCard['id'] as num).toInt();

      // Mantém o algoritmo de repetição espaçada.
      await SQLHelper.registraRevisao(cardId, avaliacao);

      if (!mounted) return;

      setState(() {
        switch (avaliacao) {
          case Avaliacao.errei:
            wrongAnswers++;
            break;

          case Avaliacao.dificil:
            difficultAnswers++;
            break;

          case Avaliacao.facil:
            correctAnswers++;
            easyAnswers++;
            break;

          case Avaliacao.muitoFacil:
            correctAnswers++;
            veryEasyAnswers++;
            break;
        }
      });

      if (currentIndex < flashcards.length - 1) {
        final deveSair = await _stopAtMasteredBoundary(currentIndex + 1);

        if (deveSair || !mounted) return;

        setState(() {
          currentIndex++;
          showAnswer = false;
          isSaving = false;
        });
      } else {
        final duration = sessionStart == null
            ? Duration.zero
            : DateTime.now().difference(sessionStart!);

        if (!mounted) return;

        Navigator.pushReplacementNamed(
          context,
          '/review-completed',
          arguments: {
            'totalCards': flashcards.length,
            'correctAnswers': correctAnswers,
            'difficultAnswers': difficultAnswers,
            'wrongAnswers': wrongAnswers,
            'easyAnswers': easyAnswers,
            'veryEasyAnswers': veryEasyAnswers,
            'durationSeconds': duration.inSeconds,
          },
        );
      }
    } catch (e) {
      debugPrint('Erro ao registrar revisão: $e');

      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _tr(
              'Não foi possível registrar sua avaliação. Tente novamente.',
              'Could not save your rating. Please try again.',
              'No se pudo guardar tu evaluación. Inténtalo de nuevo.',
            ),
          ),
        ),
      );
    }
  }

  Future<bool> _stopAtMasteredBoundary(int nextIndex) async {
    if (deckId == null || askedAboutMastered) {
      return false;
    }

    if (nextIndex < 0 || nextIndex >= flashcards.length) {
      return false;
    }

    final mastered = flashcards[nextIndex]['is_mastered'];

    if (mastered != 1) return false;

    askedAboutMastered = true;

    final escolha = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final dialogDark =
            Theme.of(dialogContext).brightness == Brightness.dark;

        final dialogBg = dialogDark ? const Color(0xFF242333) : Colors.white;

        final dialogText = dialogDark ? Colors.white : const Color(0xFF191B31);

        final dialogSecondary = dialogDark
            ? Colors.white70
            : const Color(0xFF73798B);

        Widget opcao(String texto, String valor, {bool destaque = false}) {
          return SizedBox(
            width: double.infinity,
            height: 50,
            child: destaque
                ? ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryPurple,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(dialogContext, valor);
                    },
                    child: Text(
                      texto,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  )
                : OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryPurple,
                      side: const BorderSide(color: primaryPurple, width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(dialogContext, valor);
                    },
                    child: Text(
                      texto,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
          );
        }

        return Dialog(
          backgroundColor: dialogBg,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: 44,
                    color: Color(0xFF2ECC71),
                  ),

                  const SizedBox(height: 14),

                  Text(
                    _tr(
                      'Você chegou aos cards já dominados',
                      'You have reached previously mastered cards',
                      'Has llegado a las tarjetas ya dominadas',
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: dialogText,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    _tr(
                      'O próximo card já foi dominado anteriormente. Como deseja continuar?',
                      'The next card was previously mastered. How would you like to continue?',
                      'La siguiente tarjeta ya fue dominada. ¿Cómo quieres continuar?',
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: dialogSecondary, height: 1.4),
                  ),

                  const SizedBox(height: 24),

                  opcao(
                    _tr(
                      'Continuar a revisão',
                      'Continue reviewing',
                      'Continuar el repaso',
                    ),
                    'continuar',
                    destaque: true,
                  ),

                  const SizedBox(height: 12),

                  opcao(
                    _tr(
                      'Continuar na matéria',
                      'Return to the subject',
                      'Volver a la materia',
                    ),
                    'materia',
                  ),

                  const SizedBox(height: 12),

                  opcao(
                    _tr(
                      'Voltar para a Home',
                      'Back to Home',
                      'Volver al inicio',
                    ),
                    'home',
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (!mounted) return true;

    if (escolha == 'home') {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      return true;
    }

    if (escolha == 'materia') {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      } else {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
      return true;
    }

    return false;
  }

  Widget _buildEvaluationButton({
    required String label,
    required Color color,
    required Avaliacao avaliacao,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        disabledBackgroundColor: color.withValues(alpha: 0.5),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: isSaving ? null : () => _evaluateCard(avaliacao),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: _secondary, size: 48),
            const SizedBox(height: 14),
            Text(
              _tr(
                'Não foi possível carregar os flashcards.',
                'Could not load the flashcards.',
                'No se pudieron cargar las tarjetas.',
              ),
              textAlign: TextAlign.center,
              style: TextStyle(color: _text, fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadFlashcards,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryPurple,
                foregroundColor: Colors.white,
              ),
              child: Text(
                _tr('Tentar novamente', 'Try again', 'Intentar de nuevo'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: primaryPurple,
              size: 64,
            ),

            const SizedBox(height: 16),

            Text(
              _tr('Tudo em dia!', 'All caught up!', '¡Todo al día!'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _text,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              _tr(
                'Não há flashcards disponíveis para estudar agora.',
                'There are no flashcards available to study right now.',
                'No hay tarjetas disponibles para estudiar ahora.',
              ),
              textAlign: TextAlign.center,
              style: TextStyle(color: _secondary, fontSize: 15),
            ),

            const SizedBox(height: 24),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryPurple,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/home',
                    (route) => false,
                  );
                }
              },
              child: Text(_tr('Voltar', 'Back', 'Volver')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudyContent() {
    final progresso = flashcards.isEmpty
        ? 0.0
        : currentIndex / flashcards.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight > 48
                  ? constraints.maxHeight - 48
                  : 0,
            ),
            child: Column(
              children: [
                // PROGRESSO
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progresso.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: _track,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      primaryPurple,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  _tr(
                    '$currentIndex de ${flashcards.length} cards revisados',
                    '$currentIndex of ${flashcards.length} cards reviewed',
                    '$currentIndex de ${flashcards.length} tarjetas repasadas',
                  ),
                  style: TextStyle(fontSize: 13, color: _secondary),
                ),

                const SizedBox(height: 36),

                // FLASHCARD
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(minHeight: 280),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _track),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: _dark ? 0 : 0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        showAnswer
                            ? _tr('RESPOSTA', 'ANSWER', 'RESPUESTA')
                            : _tr('PERGUNTA', 'QUESTION', 'PREGUNTA'),
                        style: const TextStyle(
                          color: primaryPurple,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: 1.1,
                        ),
                      ),

                      const SizedBox(height: 24),

                      Text(
                        showAnswer
                            ? currentCard['answer']?.toString() ?? ''
                            : currentCard['question']?.toString() ?? '',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: _text,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 36),

                // MOSTRAR RESPOSTA
                if (!showAnswer)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryPurple,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(52),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        showAnswer = true;
                      });
                    },
                    child: Text(
                      _tr(
                        'Mostrar resposta',
                        'Show answer',
                        'Mostrar respuesta',
                      ),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  )
                else ...[
                  Text(
                    _tr(
                      'Como foi sua resposta?',
                      'How did you do?',
                      '¿Cómo te fue?',
                    ),
                    style: TextStyle(
                      color: _text,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _buildEvaluationButton(
                          label: _tr('Errei', 'Again', 'Fallé'),
                          color: Colors.redAccent,
                          avaliacao: Avaliacao.errei,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildEvaluationButton(
                          label: _tr('Difícil', 'Hard', 'Difícil'),
                          color: Colors.orange,
                          avaliacao: Avaliacao.dificil,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: _buildEvaluationButton(
                          label: _tr('Fácil', 'Easy', 'Fácil'),
                          color: primaryPurple,
                          avaliacao: Avaliacao.facil,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildEvaluationButton(
                          label: _tr('Muito fácil', 'Very easy', 'Muy fácil'),
                          color: Colors.green,
                          avaliacao: Avaliacao.muitoFacil,
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LanguageController.locale,
      builder: (context, locale, child) {
        return Scaffold(
          backgroundColor: _background,
          appBar: AppBar(
            backgroundColor: _background,
            foregroundColor: _text,
            elevation: 0,
            centerTitle: true,
            title: !isLoading && flashcards.isNotEmpty
                ? Text(
                    _tr(
                      '${currentIndex + 1} de ${flashcards.length}',
                      '${currentIndex + 1} of ${flashcards.length}',
                      '${currentIndex + 1} de ${flashcards.length}',
                    ),
                    style: TextStyle(
                      color: _text,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          body: SafeArea(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: primaryPurple),
                  )
                : errorMessage != null
                ? _buildErrorScreen()
                : flashcards.isEmpty
                ? _buildEmptyScreen()
                : _buildStudyContent(),
          ),
        );
      },
    );
  }
}

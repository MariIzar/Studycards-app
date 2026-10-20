import 'package:flutter/material.dart';

import 'banco_de_dados/auth_helper.dart';
import 'banco_de_dados/sql_helper.dart';
import 'banco_de_dados/repeticao_espacada.dart';

class StudyScreen extends StatefulWidget {
  const StudyScreen({super.key});

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> {
  static const Color primaryPurple = Color(0xFF6C4DFF);
  static const Color backgroundColor = Color(0xFFF8F9FE);

  int? deckId;
  bool initialized = false;
  bool isLoading = true;
  bool isSaving = false;
  bool showAnswer = false;

  int currentIndex = 0;
  String? errorMessage;
  List<Map<String, dynamic>> flashcards = [];

  int correctAnswers = 0;
  int difficultAnswers = 0;
  int wrongAnswers = 0;
  int easyAnswers = 0;
  int veryEasyAnswers = 0;

  DateTime? sessionStart;

  // Já perguntou o que fazer ao chegar nos cards acertados?
  bool askedAboutMastered = false;

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

  // ESTUDO LIVRE PELO DECK OU REVISÃO AGENDADA GERAL
  Future<void> _loadFlashcards() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Pelo deck, carrega TODOS os cards,
      // independentemente da data da próxima revisão.
      //
      // Sem deck, mantém a revisão espaçada geral.
      final result = deckId != null
          ? await SQLHelper.pegaFlashcardsDoDeck(deckId!)
          : await SQLHelper.pegaFlashcardsPendentes(
              usuarioId: Sessao.usuarioId,
            );

      if (!mounted) return;

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

      // Deck só com cards acertados: já pergunta de início.
      if (deckId != null && result.isNotEmpty) {
        await _stopAtMasteredBoundary(0);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = 'Erro ao carregar flashcards: $e';
      });
    }
  }

  Map<String, dynamic> get currentCard {
    return flashcards[currentIndex];
  }

  // REGISTRAR A AVALIAÇÃO NO SQLITE
  Future<void> _evaluateCard(Avaliacao avaliacao) async {
    if (isSaving || flashcards.isEmpty || !showAnswer) {
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final cardId = (currentCard['id'] as num).toInt();

      // Mantém a repetição espaçada funcionando.
      await SQLHelper.registraRevisao(cardId, avaliacao);

      if (!mounted) return;

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

      if (currentIndex < flashcards.length - 1) {
        // Chegou nos cards já acertados? Deixa a pessoa escolher o que fazer.
        if (await _stopAtMasteredBoundary(currentIndex + 1)) return;
        if (!mounted) return;

        setState(() {
          currentIndex++;
          showAnswer = false;
          isSaving = false;
        });
      } else {
        // FINALIZAR A SESSÃO
        final duration = sessionStart == null
            ? Duration.zero
            : DateTime.now().difference(sessionStart!);

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
      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao registrar revisão: $e')));
    }
  }

  // Ao chegar no 1º card acertado (estudo por deck), pergunta o que fazer.
  // Retorna true se a pessoa escolheu sair da revisão.
  Future<bool> _stopAtMasteredBoundary(int nextIndex) async {
    if (deckId == null || askedAboutMastered) return false;
    if (flashcards[nextIndex]['is_mastered'] != 1) return false;

    askedAboutMastered = true;
    final escolha = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        Widget opcao(String texto, String valor, {bool destaque = false}) {
          return SizedBox(
            width: double.infinity,
            height: 50,
            child: destaque
                ? ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryPurple,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => Navigator.pop(dialogContext, valor),
                    child: Text(
                      texto,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  )
                : OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: primaryPurple, width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => Navigator.pop(dialogContext, valor),
                    child: Text(
                      texto,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: primaryPurple,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
          );
        }

        return Dialog(
          backgroundColor: backgroundColor,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
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
                const Text(
                  'Você chegou nos cards acertados',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Os cards errados e novos acabaram.\nO que você quer fazer?',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54, height: 1.4),
                ),
                const SizedBox(height: 24),
                opcao('Continuar a revisão', 'continuar', destaque: true),
                const SizedBox(height: 12),
                opcao('Continuar na matéria', 'materia'),
                const SizedBox(height: 12),
                opcao('Voltar para a Home', 'home'),
              ],
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
      // volta para a tela do deck (a matéria)
      Navigator.pop(context);
      return true;
    }
    return false; // continuar a revisão
  }

  // BOTÕES DE AVALIAÇÃO
  Widget _buildEvaluationButton({
    required String label,
    required Color color,
    required Avaliacao avaliacao,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        disabledBackgroundColor: color.withOpacity(0.5),
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: isSaving ? null : () => _evaluateCard(avaliacao),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }

  // TELA DE ERRO
  Widget _buildErrorScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadFlashcards,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }

  // TELA SEM FLASHCARDS
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
            const Text(
              'Tudo em dia!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Não há flashcards disponíveis para estudar agora.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 15),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryPurple,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Voltar'),
            ),
          ],
        ),
      ),
    );
  }

  // CONTEÚDO DA REVISÃO
  Widget _buildStudyContent() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // BARRA DE PROGRESSO
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: currentIndex / flashcards.length,
              minHeight: 6,
              backgroundColor: const Color(0xFFEBEBF5),
              valueColor: const AlwaysStoppedAnimation<Color>(primaryPurple),
            ),
          ),

          const SizedBox(height: 12),

          Text(
            '$currentIndex de ${flashcards.length} cards revisados',
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),

          const Spacer(),

          // FLASHCARD
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 280),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  showAnswer ? 'RESPOSTA' : 'PERGUNTA',
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
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

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
              child: const Text(
                'Mostrar resposta',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            )
          else ...[
            const Text(
              'Como foi sua resposta?',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildEvaluationButton(
                    label: 'Errei',
                    color: Colors.redAccent,
                    avaliacao: Avaliacao.errei,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildEvaluationButton(
                    label: 'Difícil',
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
                    label: 'Fácil',
                    color: primaryPurple,
                    avaliacao: Avaliacao.facil,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildEvaluationButton(
                    label: 'Muito fácil',
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: !isLoading && flashcards.isNotEmpty
            ? Text(
                '${currentIndex + 1} de ${flashcards.length}',
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
        centerTitle: true,
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
  }
}

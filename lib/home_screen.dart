import 'package:flutter/material.dart';

import 'banco_de_dados/auth_helper.dart';
import 'banco_de_dados/sql_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color primaryPurple = Color(0xFF6C5CE7);
  static const Color lightPurple = Color(0xFFDCD6FE);

  String? selectedDeckTitle;

  List<Map<String, dynamic>> decks = [];

  bool isLoadingDecks = true;
  String? deckError;

  int pendingCards = 0;
  int totalCards = 0;
  int masteredCards = 0;
  double masteryPercentage = 0;

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  // CARREGA DECKS E ESTATÍSTICAS DO SQLITE
  Future<void> _loadHomeData() async {
    if (!mounted) return;

    setState(() {
      isLoadingDecks = true;
      deckError = null;
    });

    // Visitante: Home vazia, sem consultar o banco.
    if (!Sessao.logado) {
      setState(() {
        decks = [];
        pendingCards = 0;
        totalCards = 0;
        masteredCards = 0;
        masteryPercentage = 0;
        isLoadingDecks = false;
        deckError = null;
      });
      return;
    }

    try {
      final results = await Future.wait<dynamic>([
        SQLHelper.pegaDecks(usuarioId: Sessao.usuarioId),
        SQLHelper.pegaEstatisticas(usuarioId: Sessao.usuarioId),
      ]);

      final loadedDecks = results[0] as List<Map<String, dynamic>>;

      final stats = results[1] as Map<String, dynamic>;

      if (!mounted) return;

      setState(() {
        decks = loadedDecks;

        pendingCards = (stats['pending_cards'] as num?)?.toInt() ?? 0;

        totalCards = (stats['total_cards'] as num?)?.toInt() ?? 0;

        masteredCards = (stats['mastered_cards'] as num?)?.toInt() ?? 0;

        masteryPercentage =
            (stats['mastery_percentage'] as num?)?.toDouble() ?? 0;

        isLoadingDecks = false;
        deckError = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoadingDecks = false;
        deckError = 'Não foi possível carregar seus dados.';
      });

      debugPrint('Erro ao carregar Home: $e');
    }
  }

  // ABRE UM DECK E ATUALIZA A HOME AO VOLTAR
  Future<void> _openDeck(int id) async {
    await Navigator.pushNamed(context, '/deck-details', arguments: id);

    if (mounted) {
      await _loadHomeData();
    }
  }

  // ABRE A LISTA DE DECKS
  Future<void> _openAllDecks() async {
    await Navigator.pushNamed(context, '/decks');

    if (mounted) {
      await _loadHomeData();
    }
  }

  // COMEÇA REVISÃO DE TODOS OS CARDS PENDENTES
  Future<void> _startReview() async {
    if (Sessao.logado && pendingCards == 0) return;

    await Navigator.pushNamed(context, '/study');

    if (mounted) {
      await _loadHomeData();
    }
  }

  // ABRE OUTRAS TELAS E RECARREGA OS DADOS AO VOLTAR
  Future<void> _openRoute(String route) async {
    await Navigator.pushNamed(context, route);

    if (mounted) {
      await _loadHomeData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                color: primaryPurple,
                onRefresh: _loadHomeData,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  children: [
                    // CABEÇALHO
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                Sessao.logado ? 'Olá, ${Sessao.primeiroNome}!' : 'Olá, estudante!',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Pronta para aprender hoje?',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.help_outline_rounded,
                            size: 28,
                          ),
                          onPressed: () {
                            _openRoute('/about');
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // REVISÃO DE HOJE
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: primaryPurple,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: primaryPurple.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Revisão de hoje',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                isLoadingDecks ? '...' : '$pendingCards',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Flexible(
                                child: Text(
                                  'cards pendentes',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          Text(
                            isLoadingDecks
                                ? 'Carregando revisões...'
                                : pendingCards == 0
                                ? 'Tudo em dia! Nenhuma revisão pendente.'
                                : 'Você tem $pendingCards ${pendingCards == 1 ? 'flashcard' : 'flashcards'} para revisar.',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),

                          const SizedBox(height: 16),

                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: primaryPurple,
                              elevation: 0,
                              disabledBackgroundColor: Colors.white54,
                              disabledForegroundColor: Colors.white70,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            onPressed:
                                isLoadingDecks ||
                                    deckError != null ||
                                    pendingCards == 0
                                ? null
                                : _startReview,
                            icon: const Icon(
                              Icons.play_arrow_rounded,
                              size: 20,
                            ),
                            label: Text(
                              pendingCards == 0
                                  ? 'Nenhuma revisão pendente'
                                  : 'Começar revisão',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // TÍTULO DOS DECKS
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Seus decks',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        TextButton(
                          onPressed: _openAllDecks,
                          child: const Text(
                            'Ver todos',
                            style: TextStyle(color: primaryPurple),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // LISTA DE DECKS
                    if (isLoadingDecks)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: primaryPurple,
                          ),
                        ),
                      )
                    else if (deckError != null)
                      TextButton(
                        onPressed: _loadHomeData,
                        child: Text('$deckError Toque para tentar novamente.'),
                      )
                    else if (decks.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          'Você ainda não criou nenhum deck.',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      )
                    else
                      ...decks.take(3).map((deck) {
                        final int id = (deck['id'] as num).toInt();

                        final int count =
                            (deck['cards_count'] as num?)?.toInt() ?? 0;

                        final int colorValue =
                            (deck['color'] as num?)?.toInt() ?? 0xFF6C4DFF;

                        final Color deckColor = Color(colorValue);

                        return _buildInteractiveDeckCard(
                          title: deck['title']?.toString() ?? 'Sem nome',
                          cardsCount: '$count ${count == 1 ? 'card' : 'cards'}',
                          deckColor: deckColor,
                          onTap: () => _openDeck(id),
                        );
                      }),

                    const SizedBox(height: 20),

                    // CARD DE PROGRESSO REAL
                    GestureDetector(
                      onTap: () {
                        _openRoute('/progress');
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: lightPurple,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Seu progresso',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),

                            const SizedBox(height: 8),

                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  isLoadingDecks
                                      ? '...'
                                      : '${masteryPercentage.round()}%',
                                  style: const TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'dos seus cards dominados',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: (masteryPercentage / 100).clamp(
                                  0.0,
                                  1.0,
                                ),
                                minHeight: 8,
                                backgroundColor: Colors.white54,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  primaryPurple,
                                ),
                              ),
                            ),

                            const SizedBox(height: 10),

                            Text(
                              '$masteredCards de $totalCards cards dominados',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),

            // BARRA INFERIOR
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
                  _buildNavItem(Icons.home, 'Início', active: true),

                  GestureDetector(
                    onTap: _openAllDecks,
                    child: _buildNavItem(Icons.style_outlined, 'Decks'),
                  ),

                  GestureDetector(
                    onTap: () {
                      _openRoute('/create-flashcards');
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
                      _openRoute('/progress');
                    },
                    child: _buildNavItem(Icons.bar_chart_outlined, 'Progresso'),
                  ),

                  GestureDetector(
                    onTap: () {
                      _openRoute('/profile');
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

  // CARD COLORIDO DE DECK
  Widget _buildInteractiveDeckCard({
    required String title,
    required String cardsCount,
    required Color deckColor,
    VoidCallback? onTap,
  }) {
    final bool isSelected = selectedDeckTitle == title;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedDeckTitle = isSelected ? null : title;
        });

        onTap?.call();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: deckColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? deckColor : deckColor.withOpacity(0.35),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: deckColor.withOpacity(isSelected ? 0.15 : 0.05),
              blurRadius: isSelected ? 12 : 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: deckColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.style, color: Colors.white, size: 24),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: deckColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    cardsCount,
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                ],
              ),
            ),

            Icon(Icons.chevron_right, color: deckColor, size: 22),
          ],
        ),
      ),
    );
  }

  // ITEM DA BARRA INFERIOR
  Widget _buildNavItem(IconData icon, String label, {bool active = false}) {
    final Color color = active ? primaryPurple : Colors.grey;

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

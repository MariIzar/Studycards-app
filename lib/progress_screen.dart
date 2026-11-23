import 'package:flutter/material.dart';

import 'main.dart' show routeObserver;
import 'banco_de_dados/auth_helper.dart';
import 'banco_de_dados/sql_helper.dart';
import 'language_controller.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> with RouteAware {
  static const Color purple = Color(0xFF7138F5);

  bool isLoading = true;
  String? errorMessage;

  int totalCards = 0;
  int reviewedCards = 0;
  int masteredCards = 0;
  int pendingCards = 0;
  double masteryPercentage = 0;

  List<Map<String, dynamic>> deckProgress = [];

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
    _loadProgress();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final route = ModalRoute.of(context);

    if (route != null) {
      routeObserver.unsubscribe(this);
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void didPopNext() {
    _loadProgress();
  }

  @override
  void dispose() {
    _loadVersion++;
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  int _toInt(dynamic value) {
    if (value is num) return value.toInt();

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  Future<void> _loadProgress() async {
    if (!mounted) return;

    final version = ++_loadVersion;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final usuarioId = Sessao.usuarioId;

      // Evita consultar dados de outros usuários
      // quando não existe uma sessão ativa.
      if (!Sessao.logado || usuarioId == null) {
        if (!mounted || version != _loadVersion) return;

        setState(() {
          totalCards = 0;
          reviewedCards = 0;
          masteredCards = 0;
          pendingCards = 0;
          masteryPercentage = 0;
          deckProgress = [];
          isLoading = false;
        });

        return;
      }

      final stats = await SQLHelper.pegaEstatisticas(usuarioId: usuarioId);

      final database = await SQLHelper.db();

      final decks = await database.rawQuery(
        '''
        SELECT
          d.id,
          d.title,
          COUNT(f.id) AS total_cards,
          COALESCE(
            SUM(
              CASE
                WHEN f.is_mastered = 1 THEN 1
                ELSE 0
              END
            ),
            0
          ) AS mastered_cards
        FROM decks d
        LEFT JOIN flashcards f
          ON f.deck_id = d.id
        WHERE d.user_id = ?
        GROUP BY d.id, d.title
        ORDER BY d.title COLLATE NOCASE
        ''',
        [usuarioId],
      );

      final progressList = decks.map((deck) {
        final total = _toInt(deck['total_cards']);
        final mastered = _toInt(deck['mastered_cards']);

        return <String, dynamic>{
          'title': deck['title']?.toString() ?? '',
          'total': total,
          'mastered': mastered,
          'percentage': total == 0
              ? 0.0
              : (mastered / total).clamp(0.0, 1.0).toDouble(),
        };
      }).toList();

      if (!mounted || version != _loadVersion) return;

      // Ignora resultados de uma sessão anterior
      // caso o usuário tenha mudado durante a consulta.
      if (Sessao.usuarioId != usuarioId) return;

      setState(() {
        totalCards = _toInt(stats['total_cards']);

        reviewedCards = _toInt(stats['total_cards_reviewed']);

        masteredCards = _toInt(stats['mastered_cards']);

        pendingCards = _toInt(stats['pending_cards']);

        masteryPercentage = _toDouble(stats['mastery_percentage'])
            .clamp(0.0, 100.0)
            .toDouble();

        deckProgress = progressList;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Erro ao carregar progresso: $e');

      if (!mounted || version != _loadVersion) return;

      setState(() {
        isLoading = false;
        errorMessage = _tr(
          'Não foi possível carregar seu progresso.',
          'Could not load your progress.',
          'No se pudo cargar tu progreso.',
        );
      });
    }
  }

  Future<void> _abrir(String rota) async {
    await Navigator.pushNamed(context, rota);

    if (mounted) {
      await _loadProgress();
    }
  }

  Widget _metricCard({
    required String title,
    required String value,
    required Color surface,
    required Color text,
    required Color secondary,
    required Color border,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 12, color: secondary)),
          const SizedBox(height: 7),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: text,
            ),
          ),
        ],
      ),
    );
  }

  Widget _circularProgress({
    required Color text,
    required Color secondary,
    required Color track,
  }) {
    final percentage = masteryPercentage.clamp(0.0, 100.0).toDouble();

    return SizedBox(
      width: 130,
      height: 130,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 130,
            height: 130,
            child: CircularProgressIndicator(
              value: percentage / 100,
              strokeWidth: 14,
              strokeCap: StrokeCap.round,
              backgroundColor: track,
              valueColor: const AlwaysStoppedAnimation<Color>(purple),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${percentage.round()}%',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: text,
                ),
              ),
              Text(
                _tr('Dominados', 'Mastered', 'Dominadas'),
                style: TextStyle(fontSize: 11, color: secondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _subjectProgress(
    Map<String, dynamic> deck, {
    required Color text,
    required Color secondary,
    required Color track,
  }) {
    final title = deck['title'] as String;
    final total = deck['total'] as int;
    final mastered = deck['mastered'] as int;
    final percentage = deck['percentage'] as double;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title.isEmpty
                    ? _tr('Sem nome', 'Untitled', 'Sin nombre')
                    : title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  color: text,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${(percentage * 100).round()}%',
              style: TextStyle(fontSize: 14, color: secondary),
            ),
          ],
        ),

        const SizedBox(height: 9),

        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: percentage.clamp(0.0, 1.0),
            minHeight: 10,
            backgroundColor: track,
            valueColor: const AlwaysStoppedAnimation<Color>(purple),
          ),
        ),

        const SizedBox(height: 7),

        Text(
          _tr(
            '$mastered de $total cards dominados',
            '$mastered of $total cards mastered',
            '$mastered de $total tarjetas dominadas',
          ),
          style: TextStyle(fontSize: 12, color: secondary),
        ),
      ],
    );
  }

  Widget _navItem(
    IconData icon,
    String label,
    String route,
    Color inactive, {
    bool active = false,
  }) {
    return Expanded(
      child: InkWell(
        onTap: active
            ? null
            : () {
                if (route == '/home') {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/home',
                    (r) => false,
                  );
                } else {
                  Navigator.pushReplacementNamed(context, route);
                }
              },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 23, color: active ? purple : inactive),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: active ? purple : inactive,
                  fontWeight: active ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

        final track = dark ? const Color(0xFF454357) : const Color(0xFFEBE7F7);

        return Scaffold(
          backgroundColor: background,
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: purple),
                        )
                      : errorMessage != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: secondary,
                                  size: 42,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _tr(
                                    'Não foi possível carregar seu progresso.',
                                    'Could not load your progress.',
                                    'No se pudo cargar tu progreso.',
                                  ),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: text),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _loadProgress,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: purple,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: Text(
                                    _tr(
                                      'Tentar novamente',
                                      'Try again',
                                      'Intentar de nuevo',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          color: purple,
                          onRefresh: _loadProgress,
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(21, 24, 21, 30),
                            children: [
                              // CABEÇALHO
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _tr(
                                        'Seu progresso',
                                        'Your progress',
                                        'Tu progreso',
                                      ),
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                        color: text,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: _tr(
                                      'Atualizar progresso',
                                      'Refresh progress',
                                      'Actualizar progreso',
                                    ),
                                    onPressed: _loadProgress,
                                    icon: const Icon(
                                      Icons.refresh_rounded,
                                      color: purple,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 6),

                              Text(
                                _tr(
                                  'Acompanhe sua evolução nos estudos.',
                                  'Track your learning progress.',
                                  'Sigue tu evolución en los estudios.',
                                ),
                                style: TextStyle(
                                  color: secondary,
                                  fontSize: 15,
                                ),
                              ),

                              const SizedBox(height: 28),

                              // PROGRESSO GERAL
                              Row(
                                children: [
                                  _circularProgress(
                                    text: text,
                                    secondary: secondary,
                                    track: track,
                                  ),
                                  const SizedBox(width: 18),
                                  Expanded(
                                    child: Column(
                                      children: [
                                        _metricCard(
                                          title: _tr(
                                            'Revisões realizadas',
                                            'Completed reviews',
                                            'Repasos realizados',
                                          ),
                                          value: '$reviewedCards',
                                          surface: surface,
                                          text: text,
                                          secondary: secondary,
                                          border: border,
                                        ),
                                        const SizedBox(height: 12),
                                        _metricCard(
                                          title: _tr(
                                            'Cards criados',
                                            'Cards created',
                                            'Tarjetas creadas',
                                          ),
                                          value: '$totalCards',
                                          surface: surface,
                                          text: text,
                                          secondary: secondary,
                                          border: border,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 22),

                              Row(
                                children: [
                                  Expanded(
                                    child: _metricCard(
                                      title: _tr(
                                        'Cards dominados',
                                        'Mastered cards',
                                        'Tarjetas dominadas',
                                      ),
                                      value: '$masteredCards',
                                      surface: surface,
                                      text: text,
                                      secondary: secondary,
                                      border: border,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _metricCard(
                                      title: _tr(
                                        'Pendentes',
                                        'Pending',
                                        'Pendientes',
                                      ),
                                      value: '$pendingCards',
                                      surface: surface,
                                      text: text,
                                      secondary: secondary,
                                      border: border,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 34),

                              // DESEMPENHO POR MATÉRIA
                              Text(
                                _tr(
                                  'Desempenho por matéria',
                                  'Performance by subject',
                                  'Rendimiento por materia',
                                ),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: text,
                                ),
                              ),

                              const SizedBox(height: 7),

                              Text(
                                _tr(
                                  'Porcentagem de flashcards dominados em cada deck.',
                                  'Percentage of mastered flashcards in each deck.',
                                  'Porcentaje de tarjetas dominadas en cada mazo.',
                                ),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: secondary,
                                ),
                              ),

                              const SizedBox(height: 16),

                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: surface,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: border),
                                ),
                                child: deckProgress.isEmpty
                                    ? Column(
                                        children: [
                                          Icon(
                                            Icons.auto_stories_outlined,
                                            color: secondary,
                                            size: 38,
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            _tr(
                                              'Nenhuma matéria cadastrada.',
                                              'No subjects added yet.',
                                              'No hay materias registradas.',
                                            ),
                                            style: TextStyle(color: text),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            _tr(
                                              'Crie um deck para acompanhar seu progresso.',
                                              'Create a deck to track your progress.',
                                              'Crea un mazo para seguir tu progreso.',
                                            ),
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: secondary,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      )
                                    : Column(
                                        children: [
                                          for (
                                            int i = 0;
                                            i < deckProgress.length;
                                            i++
                                          ) ...[
                                            _subjectProgress(
                                              deckProgress[i],
                                              text: text,
                                              secondary: secondary,
                                              track: track,
                                            ),
                                            if (i < deckProgress.length - 1)
                                              const SizedBox(height: 22),
                                          ],
                                        ],
                                      ),
                              ),

                              const SizedBox(height: 24),

                              Text(
                                _tr(
                                  'O progresso é calculado com base nas avaliações registradas e no algoritmo de repetição espaçada.',
                                  'Progress is calculated using recorded reviews and the spaced repetition algorithm.',
                                  'El progreso se calcula a partir de las evaluaciones registradas y del algoritmo de repetición espaciada.',
                                ),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),

                // NAVEGAÇÃO INFERIOR
                Container(
                  decoration: BoxDecoration(
                    color: surface,
                    border: Border(top: BorderSide(color: border)),
                  ),
                  child: Row(
                    children: [
                      _navItem(
                        Icons.home_outlined,
                        _tr('Início', 'Home', 'Inicio'),
                        '/home',
                        secondary,
                      ),
                      _navItem(
                        Icons.style_outlined,
                        _tr('Decks', 'Decks', 'Mazos'),
                        '/decks',
                        secondary,
                      ),
                      Expanded(
                        child: Center(
                          child: InkWell(
                            onTap: () => _abrir('/create-flashcards'),
                            customBorder: const CircleBorder(),
                            child: Container(
                              width: 59,
                              height: 59,
                              decoration: const BoxDecoration(
                                color: purple,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                          ),
                        ),
                      ),
                      _navItem(
                        Icons.bar_chart_outlined,
                        _tr('Progresso', 'Progress', 'Progreso'),
                        '/progress',
                        secondary,
                        active: true,
                      ),
                      _navItem(
                        Icons.person_outline,
                        _tr('Perfil', 'Profile', 'Perfil'),
                        '/profile',
                        secondary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

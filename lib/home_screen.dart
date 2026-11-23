import 'package:flutter/material.dart';

import 'main.dart' show routeObserver;
import 'banco_de_dados/auth_helper.dart';
import 'banco_de_dados/sql_helper.dart';
import 'language_controller.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with RouteAware {
  static const purple = Color(0xFF7138F5);

  List<Map<String, dynamic>> decks = [];
  bool carregando = true;
  String? erro;

  int pendentes = 0;
  int total = 0;
  int dominados = 0;
  double percentual = 0;

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
    _carregar();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final rota = ModalRoute.of(context);

    if (rota != null) {
      routeObserver.unsubscribe(this);
      routeObserver.subscribe(this, rota);
    }
  }

  @override
  void didPopNext() {
    _carregar();
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  Future<void> _carregar() async {
    if (!mounted) return;

    setState(() {
      carregando = true;
      erro = null;
    });

    if (!Sessao.logado) {
      setState(() {
        decks = [];
        pendentes = 0;
        total = 0;
        dominados = 0;
        percentual = 0;
        carregando = false;
      });
      return;
    }

    try {
      final resultados = await Future.wait<dynamic>([
        SQLHelper.pegaDecks(usuarioId: Sessao.usuarioId),
        SQLHelper.pegaEstatisticas(usuarioId: Sessao.usuarioId),
      ]);

      if (!mounted) return;

      final stats = resultados[1] as Map<String, dynamic>;

      setState(() {
        decks = resultados[0] as List<Map<String, dynamic>>;

        pendentes = (stats['pending_cards'] as num?)?.toInt() ?? 0;

        total = (stats['total_cards'] as num?)?.toInt() ?? 0;

        dominados = (stats['mastered_cards'] as num?)?.toInt() ?? 0;

        percentual = (stats['mastery_percentage'] as num?)?.toDouble() ?? 0;

        carregando = false;
      });
    } catch (e) {
      debugPrint('Erro na Home: $e');

      if (!mounted) return;

      setState(() {
        carregando = false;
        erro = _tr(
          'Não foi possível carregar seus estudos.',
          'Could not load your study data.',
          'No se pudieron cargar tus estudios.',
        );
      });
    }
  }

  Future<void> _abrir(String rota, {Object? argumentos}) async {
    await Navigator.pushNamed(context, rota, arguments: argumentos);

    if (mounted) {
      await _carregar();
    }
  }

  Widget _itemNav(
    IconData icone,
    String titulo,
    String rota,
    Color corInativa, {
    bool ativo = false,
  }) {
    return Expanded(
      child: InkWell(
        onTap: ativo ? null : () => _abrir(rota),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icone, size: 23, color: ativo ? purple : corInativa),
              const SizedBox(height: 3),
              Text(
                titulo,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: ativo ? purple : corInativa,
                  fontWeight: ativo ? FontWeight.bold : FontWeight.normal,
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
        final escuro = Theme.of(context).brightness == Brightness.dark;

        final fundo = escuro
            ? const Color(0xFF141320)
            : const Color(0xFFF8F7FF);

        final superficie = escuro ? const Color(0xFF242333) : Colors.white;

        final texto = escuro ? Colors.white : const Color(0xFF191B31);

        final secundario = escuro ? Colors.white60 : const Color(0xFF73798B);

        final borda = escuro
            ? const Color(0xFF454357)
            : const Color(0xFFE7E5F2);

        Widget cartaoDeck(Map<String, dynamic> deck) {
          final id = (deck['id'] as num).toInt();

          final titulo =
              deck['title']?.toString() ??
              _tr('Sem nome', 'Untitled', 'Sin nombre');

          final quantidade = (deck['cards_count'] as num?)?.toInt() ?? 0;

          final cor = Color((deck['color'] as num?)?.toInt() ?? 0xFF7138F5);

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: superficie,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: () => _abrir('/deck-details', argumentos: id),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borda),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: escuro ? 0 : 0.04,
                        ),
                        blurRadius: 9,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 14,
                        height: 40,
                        decoration: BoxDecoration(
                          color: cor,
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              titulo,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: texto,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              '$quantidade ${quantidade == 1 ? _tr('card', 'card', 'tarjeta') : _tr('cards', 'cards', 'tarjetas')}',
                              style: TextStyle(color: secundario, fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: texto),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: fundo,
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    color: purple,
                    onRefresh: _carregar,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(21, 24, 21, 25),
                      children: [
                        // CABEÇALHO
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    Sessao.logado
                                        ? _tr(
                                            'Olá, ${Sessao.primeiroNome}!',
                                            'Hello, ${Sessao.primeiroNome}!',
                                            '¡Hola, ${Sessao.primeiroNome}!',
                                          )
                                        : _tr(
                                            'Olá, estudante!',
                                            'Hello, student!',
                                            '¡Hola, estudiante!',
                                          ),
                                    style: TextStyle(
                                      color: texto,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _tr(
                                      'Hora de estudar um pouco?',
                                      'Ready to study?',
                                      '¿Es hora de estudiar?',
                                    ),
                                    style: TextStyle(
                                      color: secundario,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: _tr(
                                'Notificações',
                                'Notifications',
                                'Notificaciones',
                              ),
                              onPressed: () =>
                                  _abrir('/notifications-settings'),
                              icon: Icon(
                                Icons.notifications_none_outlined,
                                color: texto,
                              ),
                            ),
                            InkWell(
                              onTap: () => _abrir('/profile'),
                              borderRadius: BorderRadius.circular(14),
                              child: SizedBox(
                                width: 52,
                                height: 52,
                                child: Image.asset(
                                  'assets/images/studycards_logo.png',
                                  width: 52,
                                  height: 52,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        // REVISÃO DE HOJE
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: purple,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _tr(
                                  'Revisão de hoje',
                                  "Today's review",
                                  'Repaso de hoy',
                                ),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                carregando ? '...' : '$pendentes',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 46,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 9),
                              ElevatedButton(
                                onPressed:
                                    carregando || erro != null || pendentes == 0
                                    ? null
                                    : () => _abrir('/study'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: purple,
                                  disabledBackgroundColor: Colors.white70,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 14,
                                  ),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(13),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      pendentes == 0 && !carregando
                                          ? _tr(
                                              'Tudo revisado!',
                                              'All reviewed!',
                                              '¡Todo repasado!',
                                            )
                                          : _tr(
                                              'Começar revisão',
                                              'Start review',
                                              'Comenzar repaso',
                                            ),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.chevron_right, size: 20),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),

                        // SEUS DECKS
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _tr('Seus decks', 'Your decks', 'Tus mazos'),
                                style: TextStyle(
                                  color: texto,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => _abrir('/decks'),
                              child: Text(
                                _tr('Ver todos', 'See all', 'Ver todos'),
                                style: const TextStyle(
                                  color: purple,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 5),

                        if (carregando)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator(color: purple),
                            ),
                          )
                        else if (erro != null)
                          TextButton(
                            onPressed: _carregar,
                            child: Text(
                              '${_tr('Não foi possível carregar seus estudos.', 'Could not load your study data.', 'No se pudieron cargar tus estudios.')} ${_tr('Tentar novamente', 'Try again', 'Intentar de nuevo')}',
                            ),
                          )
                        else if (decks.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Text(
                              _tr(
                                'Você ainda não criou nenhum deck.',
                                "You haven't created any decks yet.",
                                'Todavía no has creado ningún mazo.',
                              ),
                              style: TextStyle(color: secundario),
                            ),
                          )
                        else
                          ...decks.take(3).map(cartaoDeck),

                        const SizedBox(height: 2),

                        // PROGRESSO
                        InkWell(
                          onTap: () => _abrir('/progress'),
                          borderRadius: BorderRadius.circular(17),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: escuro
                                  ? const Color(0xFF302747)
                                  : const Color(0xFFEEE8FF),
                              borderRadius: BorderRadius.circular(17),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _tr(
                                    'Seu progresso',
                                    'Your progress',
                                    'Tu progreso',
                                  ),
                                  style: TextStyle(
                                    color: texto,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 12,
                                  children: [
                                    Text(
                                      carregando
                                          ? '...'
                                          : '${percentual.round()}%',
                                      style: TextStyle(
                                        color: texto,
                                        fontSize: 40,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    Text(
                                      _tr(
                                        'dos seus cards dominados',
                                        'of your cards mastered',
                                        'de tus tarjetas dominadas',
                                      ),
                                      style: const TextStyle(
                                        color: purple,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: LinearProgressIndicator(
                                    value: (percentual / 100).clamp(0.0, 1.0),
                                    minHeight: 9,
                                    backgroundColor: escuro
                                        ? Colors.white12
                                        : Colors.white,
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                          purple,
                                        ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _tr(
                                    '$dominados de $total cards dominados',
                                    '$dominados of $total cards mastered',
                                    '$dominados de $total tarjetas dominadas',
                                  ),
                                  style: TextStyle(
                                    color: secundario,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // NAVEGAÇÃO INFERIOR
                Container(
                  decoration: BoxDecoration(
                    color: superficie,
                    border: Border(top: BorderSide(color: borda)),
                  ),
                  child: Row(
                    children: [
                      _itemNav(
                        Icons.home_outlined,
                        _tr('Início', 'Home', 'Inicio'),
                        '/home',
                        secundario,
                        ativo: true,
                      ),
                      _itemNav(
                        Icons.style_outlined,
                        _tr('Decks', 'Decks', 'Mazos'),
                        '/decks',
                        secundario,
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
                                size: 30,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      _itemNav(
                        Icons.bar_chart_outlined,
                        _tr('Progresso', 'Progress', 'Progreso'),
                        '/progress',
                        secundario,
                      ),
                      _itemNav(
                        Icons.person_outline,
                        _tr('Perfil', 'Profile', 'Perfil'),
                        '/profile',
                        secundario,
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

// =============================================================================
// teste_banco.dart — App de TESTE do banco de dados (não faz parte do app final)
// -----------------------------------------------------------------------------
// Roda separado do app principal, sem mexer no main.dart:
//
//     flutter run -t lib/banco_de_dados/teste_banco.dart
//
// Mesmo estilo da aula LDDM10 (ListView + showModalBottomSheet + setState):
//   - Tela 1: lista de decks (criar, editar, apagar) + estatísticas no topo
//   - Tela 2: cards do deck (criar, editar, apagar, gerar exemplos em lote)
//   - Tela 3: revisão com os botões Errei / Difícil / Fácil / Muito fácil,
//             mostrando quantos dias faltam para o card voltar
// =============================================================================

import 'package:flutter/material.dart';

import 'preferencias_helper.dart';
import 'repeticao_espacada.dart';
import 'sql_helper.dart';

final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void _mostraMensagem(String texto) {
  _scaffoldMessengerKey.currentState
    ?..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(texto)));
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TesteBancoApp());
}

class TesteBancoApp extends StatelessWidget {
  const TesteBancoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: _scaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      title: 'Teste do Banco - StudyCards',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const TelaDecks(),
    );
  }
}

// =============================================================================
// TELA 1 — DECKS
// =============================================================================
class TelaDecks extends StatefulWidget {
  const TelaDecks({super.key});

  @override
  State<TelaDecks> createState() => _TelaDecksState();
}

class _TelaDecksState extends State<TelaDecks> {
  List<Map<String, dynamic>> _decks = [];
  Map<String, dynamic> _estatisticas = {};
  int? _usuarioId;
  bool _estaAtualizando = true;

  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _descricaoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _iniciaSessao();
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  /// Simula um login: cria (ou reaproveita) um usuário de teste e salva
  /// o id dele no SharedPreferences.
  Future<void> _iniciaSessao() async {
    var id = await PreferenciasHelper.recuperaUsuarioLogado();
    id ??= await SQLHelper.pegaOuCriaUsuario('Usuário Teste', 'teste@studycards.app');
    await PreferenciasHelper.salvaUsuarioLogado(id);
    _usuarioId = id;
    await _atualizaDecks();
  }

  Future<void> _atualizaDecks() async {
    final decks = await SQLHelper.pegaDecks(usuarioId: _usuarioId);
    final estatisticas = await SQLHelper.pegaEstatisticas(usuarioId: _usuarioId);
    setState(() {
      _decks = decks;
      _estatisticas = estatisticas;
      _estaAtualizando = false;
    });
  }

  void _mostraEdicao(int? id) {
    if (id != null) {
      final deck = _decks.firstWhere((d) => d['id'] == id);
      _tituloController.text = deck['title'];
      _descricaoController.text = deck['description'] ?? '';
    } else {
      _tituloController.clear();
      _descricaoController.clear();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          top: 15,
          left: 15,
          right: 15,
          bottom: MediaQuery.of(context).viewInsets.bottom + 40,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            TextField(
              controller: _tituloController,
              decoration: const InputDecoration(hintText: 'Título do deck (ex: Física)'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descricaoController,
              decoration: const InputDecoration(hintText: 'Descrição (opcional)'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final titulo = _tituloController.text.trim();
                if (titulo.isEmpty) return;
                final descricao = _descricaoController.text.trim();
                if (id == null) {
                  await SQLHelper.adicionaDeck(titulo,
                      descricao: descricao, usuarioId: _usuarioId);
                } else {
                  await SQLHelper.atualizaDeck(id, titulo, descricao: descricao);
                }
                await _atualizaDecks();
                if (!mounted) return;
                Navigator.of(context).pop();
              },
              child: Text(id == null ? 'Adicionar' : 'Atualizar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _apagaDeck(int id) async {
    await SQLHelper.apagaDeck(id);
    _mostraMensagem('Deck apagado (e os cards dele também)!');
    await _atualizaDecks();
  }

  Future<void> _resetaTudo() async {
    await SQLHelper.apagaBancoInteiro();
    await PreferenciasHelper.limpaTudo();
    setState(() => _estaAtualizando = true);
    await _iniciaSessao();
    _mostraMensagem('Banco e preferências zerados!');
  }

  Widget _estatistica(String rotulo, Object? valor) => Column(
        children: [
          Text('$valor', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(rotulo, style: const TextStyle(fontSize: 11)),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final percentual = (_estatisticas['mastery_percentage'] ?? 0.0) as double;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teste do Banco - Decks'),
        actions: [
          IconButton(
            tooltip: 'Zerar banco',
            icon: const Icon(Icons.restart_alt),
            onPressed: _resetaTudo,
          ),
        ],
      ),
      body: _estaAtualizando
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Card(
                  margin: const EdgeInsets.all(8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _estatistica('cards', _estatisticas['total_cards']),
                        _estatistica('pendentes', _estatisticas['pending_cards']),
                        _estatistica('dominados', _estatisticas['mastered_cards']),
                        _estatistica('revisões', _estatisticas['total_cards_reviewed']),
                        _estatistica('domínio', '${percentual.toStringAsFixed(0)}%'),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: _decks.isEmpty
                      ? const Center(child: Text('Nenhum deck ainda. Toque em + para criar.'))
                      : ListView.builder(
                          itemCount: _decks.length,
                          itemBuilder: (context, index) {
                            final deck = _decks[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: ListTile(
                                title: Text(deck['title'],
                                    style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text(
                                    '${deck['cards_count']} cards • ${deck['pending_count']} para revisar'),
                                onTap: () async {
                                  await Navigator.of(context).push(MaterialPageRoute(
                                    builder: (_) => TelaCards(
                                        deckId: deck['id'], titulo: deck['title']),
                                  ));
                                  _atualizaDecks();
                                },
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () => _mostraEdicao(deck['id']),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () => _apagaDeck(deck['id']),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostraEdicao(null),
        child: const Icon(Icons.add),
      ),
    );
  }
}

// =============================================================================
// TELA 2 — CARDS DE UM DECK
// =============================================================================
class TelaCards extends StatefulWidget {
  final int deckId;
  final String titulo;
  const TelaCards({super.key, required this.deckId, required this.titulo});

  @override
  State<TelaCards> createState() => _TelaCardsState();
}

class _TelaCardsState extends State<TelaCards> {
  List<Map<String, dynamic>> _cards = [];
  bool _estaAtualizando = true;

  final TextEditingController _perguntaController = TextEditingController();
  final TextEditingController _respostaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _atualizaCards();
  }

  @override
  void dispose() {
    _perguntaController.dispose();
    _respostaController.dispose();
    super.dispose();
  }

  Future<void> _atualizaCards() async {
    final cards = await SQLHelper.pegaFlashcardsDoDeck(widget.deckId);
    setState(() {
      _cards = cards;
      _estaAtualizando = false;
    });
  }

  void _mostraEdicao(int? id) {
    if (id != null) {
      final card = _cards.firstWhere((c) => c['id'] == id);
      _perguntaController.text = card['question'];
      _respostaController.text = card['answer'];
    } else {
      _perguntaController.clear();
      _respostaController.clear();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          top: 15,
          left: 15,
          right: 15,
          bottom: MediaQuery.of(context).viewInsets.bottom + 40,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            TextField(
              controller: _perguntaController,
              decoration: const InputDecoration(hintText: 'Pergunta'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _respostaController,
              decoration: const InputDecoration(hintText: 'Resposta'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final pergunta = _perguntaController.text.trim();
                final resposta = _respostaController.text.trim();
                if (pergunta.isEmpty || resposta.isEmpty) return;
                if (id == null) {
                  await SQLHelper.adicionaFlashcard(widget.deckId, pergunta, resposta);
                } else {
                  await SQLHelper.atualizaFlashcard(id, pergunta, resposta);
                }
                await _atualizaCards();
                if (!mounted) return;
                Navigator.of(context).pop();
              },
              child: Text(id == null ? 'Adicionar' : 'Atualizar'),
            ),
          ],
        ),
      ),
    );
  }

  /// Simula os cards que viriam da IA/OCR, para testar a inserção em lote.
  Future<void> _geraExemplos() async {
    await SQLHelper.adicionaFlashcardsEmLote(widget.deckId, [
      {'question': 'Qual a unidade de força no SI?', 'answer': 'Newton (N)'},
      {'question': 'Fórmula da 2ª Lei de Newton', 'answer': 'F = m · a'},
      {'question': 'Valor aproximado de g na Terra', 'answer': '9,8 m/s²'},
    ]);
    _mostraMensagem('3 cards de exemplo adicionados em lote!');
    await _atualizaCards();
  }

  Future<void> _apagaCard(int id) async {
    await SQLHelper.apagaFlashcard(id);
    _mostraMensagem('Card apagado!');
    await _atualizaCards();
  }

  String _formataData(String? iso) {
    if (iso == null) return '-';
    final d = DateTime.parse(iso);
    String dois(int n) => n.toString().padLeft(2, '0');
    return '${dois(d.day)}/${dois(d.month)} ${dois(d.hour)}:${dois(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.titulo),
        actions: [
          IconButton(
            tooltip: 'Gerar 3 cards de exemplo (lote)',
            icon: const Icon(Icons.auto_awesome),
            onPressed: _geraExemplos,
          ),
          IconButton(
            tooltip: 'Revisar pendentes',
            icon: const Icon(Icons.school),
            onPressed: () async {
              await Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => TelaRevisao(deckId: widget.deckId),
              ));
              _atualizaCards();
            },
          ),
        ],
      ),
      body: _estaAtualizando
          ? const Center(child: CircularProgressIndicator())
          : _cards.isEmpty
              ? const Center(child: Text('Nenhum card. Toque em + ou no ✨ para criar.'))
              : ListView.builder(
                  itemCount: _cards.length,
                  itemBuilder: (context, index) {
                    final card = _cards[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: ListTile(
                        leading: Icon(
                          card['is_mastered'] == 1 ? Icons.star : Icons.style,
                          color: card['is_mastered'] == 1 ? Colors.amber : null,
                        ),
                        title: Text(card['question']),
                        subtitle: Text(
                          '${card['answer']}\n'
                          'Intervalo: ${card['interval_days']}d • '
                          'Fator: ${card['ease_factor']} • '
                          'Próxima: ${_formataData(card['next_review'])}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _mostraEdicao(card['id']),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _apagaCard(card['id']),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostraEdicao(null),
        child: const Icon(Icons.add),
      ),
    );
  }
}

// =============================================================================
// TELA 3 — REVISÃO
// =============================================================================
class TelaRevisao extends StatefulWidget {
  final int deckId;
  const TelaRevisao({super.key, required this.deckId});

  @override
  State<TelaRevisao> createState() => _TelaRevisaoState();
}

class _TelaRevisaoState extends State<TelaRevisao> {
  List<Map<String, dynamic>> _pendentes = [];
  int _indice = 0;
  bool _mostraResposta = false;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregaPendentes();
  }

  Future<void> _carregaPendentes() async {
    final pendentes = await SQLHelper.pegaFlashcardsPendentes(deckId: widget.deckId);
    setState(() {
      _pendentes = pendentes;
      _indice = 0;
      _mostraResposta = false;
      _carregando = false;
    });
  }

  Future<void> _avalia(Avaliacao avaliacao) async {
    final card = _pendentes[_indice];
    final dias = await SQLHelper.registraRevisao(card['id'], avaliacao);
    _mostraMensagem('${avaliacao.rotulo}: volta em $dias dia(s)');
    setState(() {
      _indice++;
      _mostraResposta = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget corpo;
    if (_carregando) {
      corpo = const Center(child: CircularProgressIndicator());
    } else if (_indice >= _pendentes.length) {
      corpo = const Center(
        child: Text('Nenhum card pendente agora. 🎉', style: TextStyle(fontSize: 18)),
      );
    } else {
      final card = _pendentes[_indice];
      corpo = Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Card ${_indice + 1} de ${_pendentes.length}', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _mostraResposta ? card['answer'] : card['question'],
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (!_mostraResposta)
              ElevatedButton(
                onPressed: () => setState(() => _mostraResposta = true),
                child: const Text('Mostrar resposta'),
              )
            else
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                children: [
                  for (final a in Avaliacao.values)
                    ElevatedButton(onPressed: () => _avalia(a), child: Text(a.rotulo)),
                ],
              ),
          ],
        ),
      );
    }

    return Scaffold(appBar: AppBar(title: const Text('Revisão')), body: corpo);
  }
}

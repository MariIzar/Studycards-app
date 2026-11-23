import 'package:flutter/material.dart';

import 'language_controller.dart';

import 'main.dart' show routeObserver;
import 'banco_de_dados/auth_helper.dart';
import 'banco_de_dados/sql_helper.dart';

class DecksScreen extends StatefulWidget {
  DecksScreen({super.key});

  @override
  State<DecksScreen> createState() => _DecksScreenState();
}

class _DecksScreenState extends State<DecksScreen> with RouteAware {
  static const Color purple = Color(0xFF7138F5);

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

  static const List<Color> cores = [
    Color(0xFF7138F5),
    Color(0xFF16A34A),
    Color(0xFF0EA5E9),
    Color(0xFFF59E0B),
    Color(0xFFEC4899),
    Color(0xFF14B8A6),
  ];

  final _buscaCtrl = TextEditingController();

  List<Map<String, dynamic>> decks = [];
  bool carregando = true;
  String? erro;
  String busca = '';

  @override
  void initState() {
    super.initState();
    _carregar();
    _buscaCtrl.addListener(_atualizarBusca);
  }

  void _atualizarBusca() {
    if (mounted) {
      setState(() => busca = _buscaCtrl.text.toLowerCase().trim());
    }
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
    _buscaCtrl.removeListener(_atualizarBusca);
    _buscaCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    if (!mounted) return;
    setState(() {
      carregando = true;
      erro = null;
    });

    try {
      final resultado = await SQLHelper.pegaDecks(usuarioId: Sessao.usuarioId);
      if (!mounted) return;

      setState(() {
        decks = resultado;
        carregando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        carregando = false;
        erro = _tr(
          'Não foi possível carregar os decks.',
          'Could not load decks.',
          'No se pudieron cargar los mazos.',
        );
      });
      debugPrint('Erro ao carregar decks: $e');
    }
  }

  Future<void> _abrir(String rota, {Object? argumentos}) async {
    await Navigator.pushNamed(context, rota, arguments: argumentos);
    if (mounted) await _carregar();
  }

  void _mensagem(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensagem)));
  }

  Future<void> _editar(Map<String, dynamic> deck) async {
    final id = (deck['id'] as num).toInt();
    final nome = deck['title']?.toString() ?? '';
    final corAtual = (deck['color'] as num?)?.toInt() ?? 0xFF7138F5;

    final resultado = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) =>
          _EditarDeckDialog(nomeInicial: nome, corInicial: corAtual),
    );

    if (!mounted || resultado == null) return;

    try {
      final alterados = await SQLHelper.atualizaDeck(
        id,
        resultado['title'] as String,
        cor: resultado['color'] as int,
      );

      if (!mounted) return;

      if (alterados > 0) {
        await _carregar();
        _mensagem(
          _tr(
            'Deck atualizado com sucesso!',
            'Deck updated successfully!',
            '¡Mazo actualizado correctamente!',
          ),
        );
      } else {
        _mensagem(
          _tr('Deck não encontrado.', 'Deck not found.', 'Mazo no encontrado.'),
        );
      }
    } catch (e) {
      _mensagem(
        _tr(
          'Não foi possível editar o deck.',
          'Could not edit the deck.',
          'No se pudo editar el mazo.',
        ),
      );
    }
  }

  Future<void> _excluir(Map<String, dynamic> deck) async {
    final id = (deck['id'] as num).toInt();
    final nome =
        deck['title']?.toString() ?? _tr('Sem nome', 'Untitled', 'Sin nombre');

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_tr('Excluir deck?', 'Delete deck?', '¿Eliminar mazo?')),
        content: Text(
          _tr(
            'Deseja excluir \"$nome\"?\n\nTodos os flashcards deste deck serão excluídos. Essa ação não pode ser desfeita.',
            'Delete \"$nome\"?\n\nAll flashcards in this deck will be deleted. This cannot be undone.',
            '¿Eliminar \"$nome\"?\n\nSe eliminarán todas las tarjetas de este mazo. Esta acción no se puede deshacer.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(_tr('Cancelar', 'Cancel', 'Cancelar')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              _tr('Excluir', 'Delete', 'Eliminar'),
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmado != true || !mounted) return;

    try {
      await SQLHelper.apagaDeck(id);
      if (!mounted) return;

      final restante = await SQLHelper.pegaUmDeck(id);
      if (!mounted) return;

      if (restante.isEmpty) {
        await _carregar();
        _mensagem(
          _tr(
            'Deck excluído com sucesso!',
            'Deck deleted successfully!',
            '¡Mazo eliminado correctamente!',
          ),
        );
      } else {
        _mensagem(
          _tr(
            'Não foi possível excluir o deck.',
            'Could not delete the deck.',
            'No se pudo eliminar el mazo.',
          ),
        );
      }
    } catch (e) {
      _mensagem(
        _tr(
          'Não foi possível excluir o deck.',
          'Could not delete the deck.',
          'No se pudo eliminar el mazo.',
        ),
      );
    }
  }

  Widget _navItem(
    IconData icone,
    String titulo,
    String rota,
    Color inativa, {
    bool ativo = false,
  }) {
    return Expanded(
      child: InkWell(
        onTap: ativo
            ? null
            : () => Navigator.pushReplacementNamed(context, rota),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 7),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icone, size: 23, color: ativo ? purple : inativa),
              SizedBox(height: 3),
              Text(
                titulo,
                style: TextStyle(
                  fontSize: 11,
                  color: ativo ? purple : inativa,
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
        final fundo = escuro ? Color(0xFF141320) : Color(0xFFF8F7FF);
        final superficie = escuro ? Color(0xFF242333) : Colors.white;
        final texto = escuro ? Colors.white : Color(0xFF191B31);
        final secundario = escuro ? Colors.white60 : Color(0xFF73798B);
        final borda = escuro ? Color(0xFF454357) : Color(0xFFE7E5F2);

        final filtrados = decks.where((deck) {
          final nome = deck['title']?.toString().toLowerCase() ?? '';
          return nome.contains(busca);
        }).toList();

        Widget cartao(Map<String, dynamic> deck) {
          final id = (deck['id'] as num).toInt();
          final nome =
              deck['title']?.toString() ??
              _tr('Sem nome', 'Untitled', 'Sin nombre');
          final quantidade = (deck['cards_count'] as num?)?.toInt() ?? 0;
          final cor = Color((deck['color'] as num?)?.toInt() ?? 0xFF7138F5);

          return Container(
            margin: EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: superficie,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borda),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: escuro ? 0 : 0.04),
                  blurRadius: 9,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _abrir('/deck-details', argumentos: id),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16, 18, 4, 18),
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
                          SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  nome,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: texto,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  '$quantidade ${quantidade == 1 ? _tr('card', 'card', 'tarjeta') : _tr('cards', 'cards', 'tarjetas')}',
                                  style: TextStyle(
                                    color: secundario,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right, color: texto, size: 22),
                        ],
                      ),
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: _tr(
                    'Opções do deck',
                    'Deck options',
                    'Opciones del mazo',
                  ),
                  icon: Icon(Icons.more_vert, color: secundario),
                  onSelected: (opcao) {
                    if (opcao == 'editar') _editar(deck);
                    if (opcao == 'excluir') _excluir(deck);
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'editar',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 20),
                          SizedBox(width: 10),
                          Text(_tr('Editar', 'Edit', 'Editar')),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'excluir',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                            size: 20,
                          ),
                          SizedBox(width: 10),
                          Text(
                            _tr('Excluir', 'Delete', 'Eliminar'),
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        return Scaffold(
          backgroundColor: fundo,
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(21, 12, 21, 10),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          } else {
                            Navigator.pushReplacementNamed(context, '/home');
                          }
                        },
                        icon: Icon(Icons.arrow_back, color: texto),
                      ),
                      Expanded(
                        child: Text(
                          _tr('Meus decks', 'My decks', 'Mis mazos'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: texto,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(width: 48),
                    ],
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    color: purple,
                    onRefresh: _carregar,
                    child: ListView(
                      physics: AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(21, 8, 21, 25),
                      children: [
                        Text(
                          _tr(
                            'Seus materiais de estudo',
                            'Your study materials',
                            'Tus materiales de estudio',
                          ),
                          style: TextStyle(
                            color: texto,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          _tr(
                            'Organize seus flashcards por matéria.',
                            'Organize your flashcards by subject.',
                            'Organiza tus tarjetas por asignatura.',
                          ),
                          style: TextStyle(color: secundario, fontSize: 16),
                        ),
                        SizedBox(height: 16),
                        TextField(
                          controller: _buscaCtrl,
                          style: TextStyle(color: texto),
                          decoration: InputDecoration(
                            hintText: _tr(
                              'Buscar decks',
                              'Search decks',
                              'Buscar mazos',
                            ),
                            hintStyle: TextStyle(color: secundario),
                            filled: true,
                            fillColor: superficie,
                            prefixIcon: Icon(Icons.search, color: purple),
                            suffixIcon: busca.isEmpty
                                ? null
                                : IconButton(
                                    icon: Icon(Icons.close, color: secundario),
                                    onPressed: _buscaCtrl.clear,
                                  ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 15,
                              vertical: 17,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: borda),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: purple, width: 1.5),
                            ),
                          ),
                        ),
                        SizedBox(height: 13),
                        if (carregando)
                          Padding(
                            padding: EdgeInsets.all(25),
                            child: Center(
                              child: CircularProgressIndicator(color: purple),
                            ),
                          )
                        else if (erro != null)
                          TextButton(
                            onPressed: _carregar,
                            child: Text(
                              '${erro ?? ''} ${_tr('Tentar novamente', 'Try again', 'Intentar de nuevo')}',
                            ),
                          )
                        else if (filtrados.isEmpty)
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 30),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.style_outlined,
                                  size: 45,
                                  color: secundario,
                                ),
                                SizedBox(height: 10),
                                Text(
                                  busca.isNotEmpty
                                      ? _tr(
                                          'Nenhum deck encontrado.',
                                          'No decks found.',
                                          'No se encontraron mazos.',
                                        )
                                      : _tr(
                                          'Nenhum deck criado ainda.',
                                          'No decks created yet.',
                                          'Todavía no has creado mazos.',
                                        ),
                                  style: TextStyle(
                                    color: texto,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          ...filtrados.map(cartao),
                        SizedBox(height: 12),
                        SizedBox(
                          height: 57,
                          child: ElevatedButton.icon(
                            onPressed: () => _abrir('/create-deck'),
                            icon: Icon(Icons.add, color: Colors.white),
                            label: Text(
                              _tr(
                                'Criar novo deck',
                                'Create new deck',
                                'Crear nuevo mazo',
                              ),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: purple,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: superficie,
                    border: Border(top: BorderSide(color: borda)),
                  ),
                  child: Row(
                    children: [
                      _navItem(
                        Icons.home_outlined,
                        _tr('Início', 'Home', 'Inicio'),
                        '/home',
                        secundario,
                      ),
                      _navItem(
                        Icons.style_outlined,
                        'Decks',
                        '/decks',
                        secundario,
                        ativo: true,
                      ),
                      Expanded(
                        child: Center(
                          child: InkWell(
                            onTap: () => _abrir('/create-flashcards'),
                            customBorder: CircleBorder(),
                            child: Container(
                              width: 59,
                              height: 59,
                              decoration: BoxDecoration(
                                color: purple,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.add,
                                size: 30,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      _navItem(
                        Icons.bar_chart_outlined,
                        _tr('Progresso', 'Progress', 'Progreso'),
                        '/progress',
                        secundario,
                      ),
                      _navItem(
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

class _EditarDeckDialog extends StatefulWidget {
  final String nomeInicial;
  final int corInicial;

  _EditarDeckDialog({required this.nomeInicial, required this.corInicial});

  @override
  State<_EditarDeckDialog> createState() => _EditarDeckDialogState();
}

class _EditarDeckDialogState extends State<_EditarDeckDialog> {
  static const Color purple = Color(0xFF7138F5);

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

  static const List<Color> cores = [
    Color(0xFF7138F5),
    Color(0xFF16A34A),
    Color(0xFF0EA5E9),
    Color(0xFFF59E0B),
    Color(0xFFEC4899),
    Color(0xFF14B8A6),
  ];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomeCtrl;
  late int _cor;

  @override
  void initState() {
    super.initState();
    _nomeCtrl = TextEditingController(text: widget.nomeInicial);
    _cor = widget.corInicial;
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    super.dispose();
  }

  void _salvar() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.pop(context, {'title': _nomeCtrl.text.trim(), 'color': _cor});
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LanguageController.locale,
      builder: (context, locale, child) => AlertDialog(
        title: Text(_tr('Editar deck', 'Edit deck', 'Editar mazo')),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _tr('Nome do deck', 'Deck name', 'Nombre del mazo'),
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                TextFormField(
                  controller: _nomeCtrl,
                  maxLength: 100,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: _tr(
                      'Nome do deck',
                      'Deck name',
                      'Nombre del mazo',
                    ),
                  ),
                  validator: (valor) {
                    if (valor == null || valor.trim().isEmpty) {
                      return _tr(
                        'Digite um nome para o deck',
                        'Enter a deck name',
                        'Introduce un nombre para el mazo',
                      );
                    }
                    return null;
                  },
                ),
                SizedBox(height: 12),
                Text(
                  _tr('Cor do deck', 'Deck color', 'Color del mazo'),
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: cores.map((cor) {
                    final selecionada = _cor == cor.toARGB32();

                    return InkWell(
                      onTap: () {
                        setState(() => _cor = cor.toARGB32());
                      },
                      customBorder: CircleBorder(),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: cor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selecionada
                                ? Theme.of(context).colorScheme.onSurface
                                : Colors.transparent,
                            width: 2.5,
                          ),
                        ),
                        child: selecionada
                            ? Icon(Icons.check, color: Colors.white)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_tr('Cancelar', 'Cancel', 'Cancelar')),
          ),
          ElevatedButton(
            onPressed: _salvar,
            style: ElevatedButton.styleFrom(
              backgroundColor: purple,
              foregroundColor: Colors.white,
            ),
            child: Text(_tr('Salvar', 'Save', 'Guardar')),
          ),
        ],
      ),
    );
  }
}

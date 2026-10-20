import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:study_cards/banco_de_dados/auth_helper.dart';
import 'package:study_cards/banco_de_dados/repeticao_espacada.dart';
import 'package:study_cards/banco_de_dados/sql_helper.dart';
import 'package:study_cards/main.dart';

Future<void> espera(WidgetTester t) async {
  for (var i = 0; i < 10; i++) {
    await t.runAsync(() => Future.delayed(const Duration(milliseconds: 150)));
    await t.pump(const Duration(milliseconds: 300));
  }
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('card novo criado pelo deck, respondido, aparece no progresso',
      (t) async {
    final antigo = FlutterError.onError;
    FlutterError.onError = (d) {
      if (!d.toString().contains('overflowed')) antigo!(d);
    };
    t.view.physicalSize = const Size(1080, 2400);
    t.view.devicePixelRatio = 2.75;
    addTearDown(t.view.reset);
    SharedPreferences.setMockInitialValues({});
    late int deckId;
    await t.runAsync(() async {
      await SQLHelper.apagaBancoInteiro();
      await AuthHelper.cadastrar(
          nome: 'Ana', email: 'a@a.com', senha: 'Senha123', confirmacao: 'Senha123');
      deckId = await SQLHelper.adicionaDeck('Deck X', usuarioId: Sessao.usuarioId);
    });
    await t.pumpWidget(const StudyCardsApp());
    await espera(t);
    final nav = () => t.state<NavigatorState>(find.byType(Navigator).first);
    nav().pushNamed('/deck-details', arguments: deckId);
    await espera(t);

    await t.tap(find.byTooltip('Adicionar flashcard').first);
    await espera(t);
    final campos = find.byType(TextField);
    await t.enterText(campos.at(0), 'Pergunta nova');
    await t.enterText(campos.at(1), 'Resposta nova');
    await t.tap(find.text('Salvar'));
    await espera(t);
    expect(find.text('Pergunta nova'), findsWidgets);
    expect(find.textContaining('0 de 1 cards dominados'), findsOneWidget);

    await t.tap(find.text('Começar revisão'));
    await espera(t);
    await t.tap(find.text('Mostrar resposta'));
    await espera(t);
    await t.tap(find.text('Fácil'));
    await espera(t);
    expect(find.text('Voltar para Home'), findsOneWidget);
    await t.ensureVisible(find.text('Voltar para Home'));
    await t.tap(find.text('Voltar para Home'));
    await espera(t);
    expect(find.textContaining('1 de 1 cards dominados'), findsOneWidget);
    // ordem: novos, depois errados, depois acertados
    await t.runAsync(() async {
      final idNovo = await SQLHelper.adicionaFlashcard(deckId, 'Novo', 'R');
      final idErr = await SQLHelper.adicionaFlashcard(deckId, 'Errado', 'R');
      await SQLHelper.registraRevisao(idErr, Avaliacao.errei);
      final lista = await SQLHelper.pegaFlashcardsDoDeck(deckId);
      expect(lista.map((c) => c['question']),
          ['Novo', 'Errado', 'Pergunta nova']);
      expect(idNovo > 0, true);
    });
    nav().pushNamed('/deck-details', arguments: deckId);
    await espera(t);
    expect(find.text('Pergunta · Acertado'), findsOneWidget);
    expect(find.text('Pergunta · Errado'), findsOneWidget);
    expect(find.byIcon(Icons.cancel), findsOneWidget);
    expect(find.text('Pergunta'), findsOneWidget);
    FlutterError.onError = antigo;
  });

  testWidgets('ao chegar nos acertados pergunta o que fazer', (t) async {
    final antigo = FlutterError.onError;
    FlutterError.onError = (d) {
      if (!d.toString().contains('overflowed')) antigo!(d);
    };
    t.view.physicalSize = const Size(1080, 2400);
    t.view.devicePixelRatio = 2.75;
    addTearDown(t.view.reset);
    SharedPreferences.setMockInitialValues({});
    late int deckId;
    await t.runAsync(() async {
      await SQLHelper.apagaBancoInteiro();
      await AuthHelper.cadastrar(
          nome: 'Ana', email: 'b@b.com', senha: 'Senha123', confirmacao: 'Senha123');
      deckId = await SQLHelper.adicionaDeck('D', usuarioId: Sessao.usuarioId);
      await SQLHelper.adicionaFlashcard(deckId, 'Novo', 'R');
      final ok = await SQLHelper.adicionaFlashcard(deckId, 'Acertado', 'R');
      await SQLHelper.registraRevisao(ok, Avaliacao.facil);
    });
    await t.pumpWidget(const StudyCardsApp());
    await espera(t);
    final nav = () => t.state<NavigatorState>(find.byType(Navigator).first);
    nav().pushNamed('/deck-details', arguments: deckId);
    await espera(t);
    await t.tap(find.text('Começar revisão'));
    await espera(t);
    expect(find.text('Novo'), findsOneWidget);
    await t.tap(find.text('Mostrar resposta'));
    await espera(t);
    await t.tap(find.text('Errei'));
    await espera(t);
    expect(find.text('Você chegou nos cards acertados'), findsOneWidget);
    expect(find.text('Continuar a revisão'), findsOneWidget);
    expect(find.text('Continuar na matéria'), findsOneWidget);
    expect(find.text('Voltar para a Home'), findsOneWidget);

    // continuar a revisão mostra o card acertado
    await t.tap(find.text('Continuar a revisão'));
    await espera(t);
    expect(find.text('Acertado'), findsOneWidget);
    FlutterError.onError = antigo;
  });

  testWidgets('escolher continuar na matéria volta ao deck', (t) async {
    final antigo = FlutterError.onError;
    FlutterError.onError = (d) {
      if (!d.toString().contains('overflowed')) antigo!(d);
    };
    t.view.physicalSize = const Size(1080, 2400);
    t.view.devicePixelRatio = 2.75;
    addTearDown(t.view.reset);
    SharedPreferences.setMockInitialValues({});
    late int deckId;
    await t.runAsync(() async {
      await SQLHelper.apagaBancoInteiro();
      await AuthHelper.cadastrar(
          nome: 'Ana', email: 'c@c.com', senha: 'Senha123', confirmacao: 'Senha123');
      deckId = await SQLHelper.adicionaDeck('Deck M', usuarioId: Sessao.usuarioId);
      await SQLHelper.adicionaFlashcard(deckId, 'Novo', 'R');
      final ok = await SQLHelper.adicionaFlashcard(deckId, 'Acertado', 'R');
      await SQLHelper.registraRevisao(ok, Avaliacao.facil);
    });
    await t.pumpWidget(const StudyCardsApp());
    await espera(t);
    t.state<NavigatorState>(find.byType(Navigator).first)
        .pushNamed('/deck-details', arguments: deckId);
    await espera(t);
    await t.tap(find.text('Começar revisão'));
    await espera(t);
    await t.tap(find.text('Mostrar resposta'));
    await espera(t);
    await t.tap(find.text('Fácil'));
    await espera(t);
    await t.tap(find.text('Continuar na matéria'));
    await espera(t);
    expect(find.text('Começar revisão'), findsOneWidget);
    expect(find.text('Mostrar resposta'), findsNothing);
    FlutterError.onError = antigo;
  });
}

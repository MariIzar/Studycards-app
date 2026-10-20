// Fluxo pela interface: cadastro -> Home -> sair -> login com erro e acerto.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:study_cards/banco_de_dados/auth_helper.dart';
import 'package:study_cards/banco_de_dados/sql_helper.dart';
import 'package:study_cards/main.dart';

Future<void> espera(WidgetTester t) async {
  for (var i = 0; i < 12; i++) {
    await t.runAsync(() => Future.delayed(const Duration(milliseconds: 150)));
    await t.pump(const Duration(milliseconds: 300));
  }
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('cadastro, sair e entrar pela interface', (t) async {
    final antigo = FlutterError.onError;
    FlutterError.onError = (d) {
      if (!d.toString().contains('overflowed')) antigo!(d);
    };
    t.view.physicalSize = const Size(1500, 2400);
    t.view.devicePixelRatio = 2.75;
    addTearDown(t.view.reset);

    SharedPreferences.setMockInitialValues({});
    await t.runAsync(() async {
      await SQLHelper.apagaBancoInteiro();
      await Sessao.carrega();
    });

    await t.pumpWidget(const StudyCardsApp());
    await espera(t);
    final nav = () => t.state<NavigatorState>(find.byType(Navigator).first);

    // abre direto na Home, como visitante (sem tela de login)
    expect(find.text('Olá, estudante!'), findsOneWidget);
    expect(find.text('Entre no StudyCards'), findsNothing);

    // usar uma função (progresso) pede login
    nav().pushNamed('/progress');
    await espera(t);
    // vai direto para a tela de login (sem a tela de convite)
    expect(find.text('Entre no StudyCards'), findsNothing);
    expect(find.text('Ainda não possui conta? '), findsOneWidget);

    await t.tap(find.text('Criar conta'));
    await espera(t);
    expect(find.text('Google'), findsNothing);

    // erro de validação
    await t.tap(find.text('Criar minha conta'));
    await espera(t);
    expect(find.text('Informe seu nome.'), findsOneWidget);

    final campos = find.byType(TextField);
    await t.enterText(campos.at(0), 'Maria Souza');
    await t.enterText(campos.at(1), 'maria@mail.com');
    await t.enterText(campos.at(2), 'Senha123');
    await t.enterText(campos.at(3), 'Senha123');
    await t.tap(find.text('Criar minha conta'));
    await espera(t);
    expect(find.text('Conta criada!'), findsOneWidget);

    // continua na função que pediu o login (a tela de progresso abre)
    await t.tap(find.text('Começar a estudar'));
    await espera(t);
    expect(find.text('Entre no StudyCards'), findsNothing);
    expect(find.text('Conta criada!'), findsNothing);
    expect(Sessao.logado, true);

    // logout pelo perfil volta para a Home de visitante
    nav().pushNamed('/profile');
    await espera(t);
    expect(find.text('Maria Souza'), findsOneWidget);
    await t.ensureVisible(find.text('Sair da conta'));
    await t.tap(find.text('Sair da conta'));
    await espera(t);
    expect(find.text('Olá, estudante!'), findsOneWidget);
    expect(Sessao.logado, false);

    // perfil de visitante: livre, com login, ajuda, configurações e sobre
    nav().pushNamed('/profile');
    await espera(t);
    expect(find.text('Visitante'), findsOneWidget);
    expect(find.text('Fazer login'), findsOneWidget);
    expect(find.text('Configurações'), findsOneWidget);
    expect(find.text('Ajuda e suporte'), findsOneWidget);
    expect(find.text('Sobre o StudyCards'), findsOneWidget);
    expect(find.text('Meus decks'), findsNothing);
    expect(find.text('Sair da conta'), findsNothing);

    // login errado e certo a partir do perfil
    await t.tap(find.text('Fazer login'));
    await espera(t);
    expect(find.text('Google'), findsNothing);
    await t.enterText(find.byType(TextField).at(0), 'maria@mail.com');
    await t.enterText(find.byType(TextField).at(1), 'errada');
    await t.tap(find.text('Entrar'));
    await espera(t);
    expect(find.text('E-mail ou senha incorretos.'), findsOneWidget);
    await t.enterText(find.byType(TextField).at(1), 'Senha123');
    await t.tap(find.text('Entrar'));
    await espera(t);
    // voltou ao perfil, já logado
    expect(find.text('Maria Souza'), findsOneWidget);
    expect(find.text('Fazer login'), findsNothing);
    expect(find.text('Meus decks'), findsOneWidget);
    FlutterError.onError = antigo;
  });
}

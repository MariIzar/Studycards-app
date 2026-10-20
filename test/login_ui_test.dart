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
    t.view.physicalSize = const Size(1080, 2400);
    t.view.devicePixelRatio = 2.75;
    addTearDown(t.view.reset);

    SharedPreferences.setMockInitialValues({});
    await t.runAsync(() async {
      await SQLHelper.apagaBancoInteiro();
      await Sessao.carrega();
    });

    await t.pumpWidget(const StudyCardsApp());
    await espera(t);
    expect(find.text('Entre no StudyCards'), findsOneWidget);

    // Google não existe mais
    t.state<NavigatorState>(find.byType(Navigator).first).pushNamed('/register');
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

    await t.tap(find.text('Começar a estudar'));
    await espera(t);
    expect(find.text('Olá, Maria!'), findsOneWidget);

    // logout
    t.state<NavigatorState>(find.byType(Navigator).first).pushNamed('/profile');
    await espera(t);
    expect(find.text('Maria Souza'), findsOneWidget);
    await t.ensureVisible(find.text('Sair da conta'));
    await t.tap(find.text('Sair da conta'));
    await espera(t);
    expect(find.text('Entre no StudyCards'), findsOneWidget);
    expect(Sessao.logado, false);

    // login errado e certo
    t.state<NavigatorState>(find.byType(Navigator).first).pushNamed('/login');
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
    expect(find.text('Olá, Maria!'), findsOneWidget);
    FlutterError.onError = antigo;
  });
}

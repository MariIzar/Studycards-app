import 'package:flutter/material.dart';

import 'banco_de_dados/auth_helper.dart';
import 'login_screen.dart';

/// Telas do fluxo de autenticação (somem da pilha quando o login termina).
const Set<String> _rotasDeAutenticacao = {
  '/login',
  '/register',
  '/forgot-password',
  '/account-created',
};

/// Chamado quando o login/cadastro termina: fecha as telas de autenticação e
/// volta para a tela que pediu o login (Home ou uma função do app).
void voltaDoLogin(BuildContext context) {
  Navigator.popUntil(
    context,
    (rota) => !_rotasDeAutenticacao.contains(rota.settings.name),
  );
}

/// Protege uma função do app: visitante vê o convite para entrar; depois do
/// login, a própria tela aparece no lugar do convite.
class RequerLogin extends StatefulWidget {
  final Widget child;
  const RequerLogin({super.key, required this.child});

  @override
  State<RequerLogin> createState() => _RequerLoginState();
}

class _RequerLoginState extends State<RequerLogin> {
  @override
  Widget build(BuildContext context) {
    if (Sessao.logado) return widget.child;
    // Visitante: mostra direto a tela de login no lugar da função.
    return LoginScreen(
      onLogado: () {
        if (mounted) setState(() {});
      },
    );
  }
}

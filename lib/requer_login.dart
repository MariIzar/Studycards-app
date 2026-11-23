import 'package:flutter/material.dart';

import 'banco_de_dados/auth_helper.dart';
import 'login_screen.dart';

/// Rotas que fazem parte do fluxo de autenticação.
const Set<String> _rotasDeAutenticacao = {
  '/login',
  '/register',
  '/forgot-password',
  '/account-created',
};

void voltaDoLogin(BuildContext context) {
  final navigator = Navigator.of(context);

  bool encontrouDestino = false;

  navigator.popUntil((rota) {
    final nome = rota.settings.name;

    if (!_rotasDeAutenticacao.contains(nome)) {
      encontrouDestino = true;
      return true;
    }

    return rota.isFirst;
  });

  // Se a primeira rota também era de autenticação,
  // substitui a pilha pela Home.
  if (!encontrouDestino && context.mounted) {
    navigator.pushNamedAndRemoveUntil('/home', (route) => false);
  }
}

/// Protege uma funcionalidade que exige login.
///
/// Usuário autenticado:
///   mostra a tela solicitada.
///
/// Visitante:
///   mostra a tela de login.
///
/// Depois do login:
///   atualiza automaticamente o conteúdo protegido.
class RequerLogin extends StatefulWidget {
  final Widget child;

  const RequerLogin({super.key, required this.child});

  @override
  State<RequerLogin> createState() => _RequerLoginState();
}

class _RequerLoginState extends State<RequerLogin> {
  void _aoLogar() {
    if (!mounted) return;

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (Sessao.logado) {
      return widget.child;
    }

    return LoginScreen(onLogado: _aoLogar);
  }
}

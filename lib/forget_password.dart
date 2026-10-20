import 'package:flutter/material.dart';

import 'banco_de_dados/auth_helper.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  final _novaCtrl = TextEditingController();
  final _confirmaCtrl = TextEditingController();
  bool _carregando = false;
  String? _erro;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _novaCtrl.dispose();
    _confirmaCtrl.dispose();
    super.dispose();
  }

  Future<void> _redefinir() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    final r = await AuthHelper.redefinirSenha(
      email: _emailCtrl.text,
      nova: _novaCtrl.text,
      confirmacao: _confirmaCtrl.text,
    );
    if (!mounted) return;
    if (r.ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Senha redefinida! Entre com a nova senha.')),
      );
      Navigator.pop(context);
    } else {
      setState(() {
        _carregando = false;
        _erro = r.erro;
      });
    }
  }

  Widget _campo(String hint, TextEditingController c,
      {bool senha = false, TextInputType? tipo}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: c,
        obscureText: senha,
        keyboardType: tipo,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.black45, fontSize: 15),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryPurple = Color(0xFF6C5CE7);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),

              // Botão de Voltar isolado no topo
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.black,
                  size: 24,
                ),
                onPressed: () => Navigator.pop(context),
              ),

              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Título centralizado
                        const Text(
                          'Recuperar senha',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Subtítulo
                        const Text(
                          'Informe o e-mail da sua conta e escolha\numa nova senha neste aparelho',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: Color(0xFF64748B),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 36),

                        _campo('E-mail', _emailCtrl,
                            tipo: TextInputType.emailAddress),
                        _campo('Nova senha', _novaCtrl, senha: true),
                        _campo('Confirmar nova senha', _confirmaCtrl,
                            senha: true),
                        if (_erro != null) ...[
                          Text(
                            _erro!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFFE53935),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        const SizedBox(height: 6),

                        // Botão Enviar Link
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryPurple,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: _carregando ? null : _redefinir,
                            child: const Text(
                              'Redefinir senha',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Link Voltar para o Login
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Text(
                            'Voltar para o login',
                            style: TextStyle(
                              color: primaryPurple,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

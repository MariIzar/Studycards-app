import 'package:flutter/material.dart';

import 'banco_de_dados/auth_helper.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nomeCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  final _confirmaCtrl = TextEditingController();
  bool _carregando = false;
  String? _erro;

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    _confirmaCtrl.dispose();
    super.dispose();
  }

  Future<void> _cadastrar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    final r = await AuthHelper.cadastrar(
      nome: _nomeCtrl.text,
      email: _emailCtrl.text,
      senha: _senhaCtrl.text,
      confirmacao: _confirmaCtrl.text,
    );
    if (!mounted) return;
    if (r.ok) {
      Navigator.pushNamedAndRemoveUntil(
          context, '/account-created', (_) => false);
    } else {
      setState(() {
        _carregando = false;
        _erro = r.erro;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryPurple = Color(0xFF6C5CE7);
    const lightPurple = Color(0xFF8C7CFF);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),

                // Título
                const Text(
                  'Crie sua conta',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),

                // Subtítulo
                const Text(
                  'Comece sua jornada de estudos\ninteligentes.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 32),

                // Campo: Nome completo
                _buildInputField(hint: 'Nome completo', controller: _nomeCtrl),
                const SizedBox(height: 14),

                // Campo: E-mail
                _buildInputField(
                  hint: 'E-mail',
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 14),

                // Campo: Senha
                _buildInputField(hint: 'Senha', obscureText: true, controller: _senhaCtrl),
                const SizedBox(height: 14),

                // Campo: Confirmar senha
                _buildInputField(
                    hint: 'Confirmar senha',
                    obscureText: true,
                    controller: _confirmaCtrl),
                const SizedBox(height: 24),

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

                // Botão "Criar minha conta"
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryPurple,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _carregando ? null : _cadastrar,
                    child: const Text(
                      'Criar minha conta',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Link para voltar ao Login
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Já possui uma conta? ',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Entrar',
                        style: TextStyle(
                          color: lightPurple,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String hint,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    TextEditingController? controller,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.black45, fontSize: 15),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }
}
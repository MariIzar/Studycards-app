import 'package:flutter/material.dart';

import 'banco_de_dados/auth_helper.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _atualCtrl = TextEditingController();
  final _novaCtrl = TextEditingController();
  final _confirmaCtrl = TextEditingController();
  bool _carregando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    // atualiza os requisitos (✓/✗) enquanto o usuário digita
    _novaCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _atualCtrl.dispose();
    _novaCtrl.dispose();
    _confirmaCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    final r = await AuthHelper.alterarSenha(
      atual: _atualCtrl.text,
      nova: _novaCtrl.text,
      confirmacao: _confirmaCtrl.text,
    );
    if (!mounted) return;
    if (r.ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Senha alterada com sucesso!')),
      );
      Navigator.pop(context);
    } else {
      setState(() {
        _carregando = false;
        _erro = r.erro;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final nova = _novaCtrl.text;
    const primaryPurple = Color(0xFF6C4DFF);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Alterar senha',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Senha atual',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 8),
              _buildPasswordField('Digite sua senha atual', _atualCtrl),
              const SizedBox(height: 20),
              const Text(
                'Nova senha',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 8),
              _buildPasswordField('Digite sua nova senha', _novaCtrl),
              const SizedBox(height: 20),
              const Text(
                'Confirmar nova senha',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 8),
              _buildPasswordField('Confirme sua nova senha', _confirmaCtrl),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F0FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'A senha deve conter:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: primaryPurple,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildRequirementRow('Pelo menos 8 caracteres', AuthHelper.temOito(nova)),
                    _buildRequirementRow('Uma letra maiúscula', AuthHelper.temMaiuscula(nova)),
                    _buildRequirementRow('Uma letra minúscula', AuthHelper.temMinuscula(nova)),
                    _buildRequirementRow('Um número', AuthHelper.temNumero(nova)),
                  ],
                ),
              ),
              if (_erro != null) ...[
                const SizedBox(height: 16),
                Text(
                  _erro!,
                  style: const TextStyle(color: Color(0xFFE53935), fontSize: 13),
                ),
              ],
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryPurple,
                  minimumSize: const Size.fromHeight(52),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _carregando ? null : _salvar,
                child: const Text(
                  'Salvar nova senha',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField(String hint, TextEditingController controller) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: true,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.black45, fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildRequirementRow(String text, bool met) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            met ? Icons.check : x_icon,
            size: 16,
            color: met ? const Color(0xFF6C4DFF) : Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: met ? Colors.black87 : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  IconData get x_icon => Icons.close;
}

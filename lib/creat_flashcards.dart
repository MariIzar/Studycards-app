import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'services/ai_service.dart';

class CreateFlashcardsScreen extends StatefulWidget {
  const CreateFlashcardsScreen({super.key});

  @override
  State<CreateFlashcardsScreen> createState() => _CreateFlashcardsScreenState();
}

class _CreateFlashcardsScreenState extends State<CreateFlashcardsScreen> {
  static const purple = Color(0xFF7038F5);
  static const lightPurple = Color(0xFFBFA3FF);
  static const background = Color(0xFFF8F7FF);
  static const darkText = Color(0xFF17192D);

  final _picker = ImagePicker();
  final _subject = TextEditingController();
  final _text = TextEditingController();

  File? _file;
  String? _fileName;
  bool _loading = false;

  @override
  void dispose() {
    _subject.dispose();
    _text.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_loading) return;

    try {
      final image = await _picker.pickImage(source: source, imageQuality: 85);

      if (image == null || !mounted) return;

      setState(() {
        _file = File(image.path);
        _fileName = image.name;
      });

      _openGenerateDialog();
    } catch (e) {
      _showError('Não foi possível abrir a imagem: $e');
    }
  }

  Future<void> _pickPdf() async {
    if (_loading) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: false,
      );

      if (result == null || !mounted) return;

      final selected = result.files.single;
      final path = selected.path;

      if (path == null || path.isEmpty) {
        _showError('Não foi possível acessar o PDF.');
        return;
      }

      final file = File(path);

      if (!await file.exists()) {
        _showError('O PDF selecionado não foi encontrado.');
        return;
      }

      final tamanho = await file.length();
      const limite = 12 * 1024 * 1024;

      if (tamanho > limite) {
        _showError(
          'Este PDF ultrapassa o limite de 12 MB. '
          'Escolha um arquivo menor.',
        );
        return;
      }

      if (!mounted) return;

      setState(() {
        _file = file;
        _fileName = selected.name;
      });

      _openGenerateDialog();
    } catch (e) {
      _showError('Não foi possível importar o PDF: $e');
    }
  }

  void _openGenerateDialog() {
    if (!mounted || _loading) return;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Gerar flashcards com IA'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_fileName != null) ...[
                    Row(
                      children: [
                        const Icon(Icons.attach_file, color: purple),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _fileName!,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                  ],
                  TextField(
                    controller: _subject,
                    decoration: const InputDecoration(
                      labelText: 'Matéria (opcional)',
                      hintText: 'Ex.: Física',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _text,
                    minLines: 2,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Texto complementar (opcional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'A IA vai gerar 8 flashcards do material.',
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: _loading ? null : () => Navigator.pop(dialogContext),
                child: const Text('Cancelar'),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: purple,
                  foregroundColor: Colors.white,
                ),
                onPressed: _loading
                    ? null
                    : () {
                        Navigator.pop(dialogContext);
                        _generate();
                      },
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Gerar'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _generate() async {
    if (_loading) return;

    if (_file == null && _text.text.trim().length < 30) {
      _showError('Selecione um arquivo ou digite pelo menos 30 caracteres.');
      return;
    }

    setState(() => _loading = true);

    try {
      final result = await AiService.gerarFlashcards(
        arquivo: _file,
        texto: _text.text.trim(),
        materia: _subject.text.trim(),
      );

      if (!mounted) return;

      result['localFilePath'] = _file?.path;

      Navigator.pushReplacementNamed(
        context,
        '/generated-flashcards',
        arguments: result,
      );
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Widget _importButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 62,
      child: OutlinedButton.icon(
        onPressed: _loading ? null : onPressed,
        icon: Icon(icon, size: 24),
        label: Text(
          label,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: lightPurple,
          side: const BorderSide(color: lightPurple, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }

  Widget _mainButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool filled = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: filled
          ? ElevatedButton.icon(
              onPressed: _loading ? null : onPressed,
              icon: Icon(icon),
              label: Text(
                label,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: purple,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            )
          : OutlinedButton.icon(
              onPressed: _loading ? null : onPressed,
              icon: Icon(icon),
              label: Text(
                label,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: purple,
                side: const BorderSide(color: purple, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Criar flashcards',
          style: TextStyle(
            color: darkText,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        iconTheme: const IconThemeData(color: darkText),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Deixe a IA transformar seu material em cards',
                style: TextStyle(
                  color: darkText,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 22),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE7E2F3)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x12000000),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'Escolha como deseja enviar seu material. '
                      'A inteligência artificial vai analisar '
                      'o conteúdo e criar flashcards para você.',
                      style: TextStyle(
                        color: Color(0xFF737A8C),
                        fontSize: 17,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),

                    _importButton(
                      icon: Icons.camera_alt_outlined,
                      label: 'Abrir câmera',
                      onPressed: () => _pickImage(ImageSource.camera),
                    ),
                    const SizedBox(height: 12),

                    _importButton(
                      icon: Icons.image_outlined,
                      label: 'Importar da galeria',
                      onPressed: () => _pickImage(ImageSource.gallery),
                    ),
                    const SizedBox(height: 12),

                    _importButton(
                      icon: Icons.insert_drive_file_outlined,
                      label: 'Importar PDF',
                      onPressed: _pickPdf,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              _mainButton(
                icon: Icons.note_add_outlined,
                label: 'Criar card manualmente',
                filled: true,
                onPressed: () {
                  // Substituir pela rota real do editor manual.
                  _showError(
                    'Precisamos conectar este botão à tela de criação manual.',
                  );
                },
              ),

              const SizedBox(height: 12),

              _mainButton(
                icon: Icons.add,
                label: 'Criar novo deck',
                onPressed: () {
                  Navigator.pushNamed(context, '/create-deck');
                },
              ),

              if (_loading) ...[
                const SizedBox(height: 26),
                const Center(child: CircularProgressIndicator(color: purple)),
                const SizedBox(height: 12),
                const Center(
                  child: Text(
                    'Analisando material com IA...\n'
                    'Isso pode levar alguns minutos.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: darkText),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

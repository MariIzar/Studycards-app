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
  static const purple = Color(0xFF6C4DFF);
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

  Future<void> _pickImage(ImageSource source) async {
    try {
      final image = await _picker.pickImage(source: source, imageQuality: 85);
      if (image != null && mounted) {
        setState(() { _file = File(image.path); _fileName = image.name; });
      }
    } catch (e) { _showError('Não foi possível abrir a imagem: $e'); }
  }

  Future<void> _pickPdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: false,
      );
      if (result == null || !mounted) return;

      final selected = result.files.single;
      final selectedPath = selected.path;
      if (selectedPath == null || selectedPath.isEmpty) {
        _showError('O seletor encontrou o PDF, mas não disponibilizou o caminho do arquivo. Salve o PDF no aparelho e tente novamente.');
        return;
      }

      final selectedFile = File(selectedPath);
      if (!await selectedFile.exists()) {
        _showError('Não consegui acessar o PDF selecionado. Salve-o no aparelho e tente novamente.');
        return;
      }

      if (!mounted) return;
      setState(() {
        _file = selectedFile;
        _fileName = selected.name;
      });
    } catch (e) {
      _showError('Não foi possível importar o PDF: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _generate() async {
    if (_file == null && _text.text.trim().length < 30) {
      _showError('Selecione uma foto/PDF ou digite pelo menos 30 caracteres da matéria.');
      return;
    }
    setState(() => _loading = true);
    try {
      final result = await AiService.gerarFlashcards(
        arquivo: _file, texto: _text.text.trim(), materia: _subject.text.trim(),
      );
      if (!mounted) return;
      result['localFilePath'] = _file?.path;
      Navigator.pushReplacementNamed(context, '/generated-flashcards', arguments: result);
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _option(IconData icon, String label, VoidCallback onTap) =>
      SizedBox(width: double.infinity, child: OutlinedButton.icon(
        onPressed: _loading ? null : onTap, icon: Icon(icon, color: purple),
        label: Text(label), style: OutlinedButton.styleFrom(
          foregroundColor: Colors.black87, minimumSize: const Size.fromHeight(48),
          side: const BorderSide(color: Color(0x22000000)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ));

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF8F9FE),
    appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text('Criar flashcards', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)), iconTheme: const IconThemeData(color: Colors.black)),
    body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Transforme seu material em estudo', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      const SizedBox(height: 6), const Text('Envie uma foto, apostila PDF ou cole o conteúdo. A IA cria os flashcards para você.' , style: TextStyle(color: Colors.black54)),
      const SizedBox(height: 20),
      _option(Icons.camera_alt_outlined, 'Fotografar anotações', () => _pickImage(ImageSource.camera)),
      const SizedBox(height: 10),
      _option(Icons.photo_library_outlined, 'Escolher imagem da galeria', () => _pickImage(ImageSource.gallery)),
      const SizedBox(height: 10),
      _option(Icons.picture_as_pdf_outlined, 'Importar apostila PDF', _pickPdf),
      if (_fileName != null) ...[
        const SizedBox(height: 12), Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFECE7FF), borderRadius: BorderRadius.circular(12)), child: Row(children: [const Icon(Icons.attach_file, color: purple), Expanded(child: Text(_fileName!, overflow: TextOverflow.ellipsis)), IconButton(onPressed: () => setState(() { _file = null; _fileName = null; }), icon: const Icon(Icons.close))])),
      ],
      const SizedBox(height: 20),
      TextField(controller: _subject, decoration: InputDecoration(labelText: 'Matéria (opcional)', hintText: 'Ex.: Física, Biologia, Cálculo...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
      const SizedBox(height: 14),
      TextField(controller: _text, minLines: 4, maxLines: 8, decoration: InputDecoration(labelText: 'Complementar com texto (opcional)', hintText: 'Cole aqui um resumo, tópicos ou trechos da apostila...', alignLabelWithHint: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
      const SizedBox(height: 10),
      const Center(child: Text('A IA gera 8 flashcards por material.', style: TextStyle(fontSize: 12, color: Colors.black54))),
      const SizedBox(height: 14),
      SizedBox(width: double.infinity, height: 54, child: ElevatedButton.icon(
        onPressed: _loading ? null : _generate, style: ElevatedButton.styleFrom(backgroundColor: purple, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        icon: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.auto_awesome),
        label: Text(_loading ? 'Analisando material...' : 'Gerar flashcards com IA', style: const TextStyle(fontWeight: FontWeight.bold)),
      )),
      const SizedBox(height: 4),
      const Text('É necessário estar conectado à internet. O arquivo é enviado ao backend para processamento e não é salvo automaticamente no servidor.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.black45)),
    ]))),
  );
}

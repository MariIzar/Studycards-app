import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'language_controller.dart';

class CreateFlashcardsScreen extends StatefulWidget {
  const CreateFlashcardsScreen({super.key});

  @override
  State<CreateFlashcardsScreen> createState() => _CreateFlashcardsScreenState();
}

class _CreateFlashcardsScreenState extends State<CreateFlashcardsScreen> {
  static const purple = Color(0xFF7038F5);
  static const lightPurple = Color(0xFFBFA3FF);

  final _picker = ImagePicker();
  final _subject = TextEditingController();
  final _text = TextEditingController();

  File? _file;
  String? _fileName;
  bool _loading = false;
  bool _picking = false;

  String _tr(String pt, String en, String es) {
    switch (LanguageController.locale.value.languageCode) {
      case 'en':
        return en;
      case 'es':
        return es;
      default:
        return pt;
    }
  }

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
    if (_loading || _picking) return;

    setState(() => _picking = true);

    try {
      final image = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 2048,
        maxHeight: 2048,
        requestFullMetadata: false,
      );

      if (image == null || !mounted) return;

      final file = File(image.path);

      if (!await file.exists()) {
        _showError(
          _tr(
            'A imagem selecionada não foi encontrada.',
            'The selected image was not found.',
            'No se encontró la imagen seleccionada.',
          ),
        );
        return;
      }

      if (!mounted) return;

      setState(() {
        _file = file;
        _fileName = image.name;
      });

      _openGenerateDialog();
    } catch (e) {
      debugPrint('Erro ao selecionar imagem: $e');

      _showError(
        _tr(
          'Não foi possível acessar a câmera ou a galeria. Verifique as permissões.',
          'Could not access the camera or gallery. Check permissions.',
          'No se pudo acceder a la cámara o galería. Comprueba los permisos.',
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _picking = false);
      }
    }
  }

  Future<void> _pickPdf() async {
    if (_loading || _picking) return;

    setState(() => _picking = true);

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
        _showError(
          _tr(
            'Não foi possível acessar o PDF.',
            'Could not access the PDF.',
            'No se pudo acceder al PDF.',
          ),
        );
        return;
      }

      final file = File(path);

      if (!await file.exists()) {
        _showError(
          _tr(
            'O PDF selecionado não foi encontrado.',
            'The selected PDF was not found.',
            'No se encontró el PDF seleccionado.',
          ),
        );
        return;
      }

      const limite = 12 * 1024 * 1024;
      final tamanho = await file.length();

      if (tamanho > limite) {
        _showError(
          _tr(
            'Este PDF ultrapassa o limite de 12 MB. Escolha um arquivo menor.',
            'This PDF exceeds the 12 MB limit. Choose a smaller file.',
            'Este PDF supera el límite de 12 MB. Elige un archivo más pequeño.',
          ),
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
      debugPrint('Erro ao importar PDF: $e');

      _showError(
        _tr(
          'Não foi possível importar o PDF.',
          'Could not import the PDF.',
          'No se pudo importar el PDF.',
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _picking = false);
      }
    }
  }

  void _openGenerateDialog() {
    if (!mounted || _loading) return;

    final cores = Theme.of(context).colorScheme;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return ValueListenableBuilder<Locale>(
          valueListenable: LanguageController.locale,
          builder: (context, idioma, child) {
            return AlertDialog(
              title: Text(
                _tr(
                  'Gerar flashcards com IA',
                  'Generate flashcards with AI',
                  'Generar tarjetas con IA',
                ),
              ),
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
                      decoration: InputDecoration(
                        labelText: _tr(
                          'Matéria (opcional)',
                          'Subject (optional)',
                          'Asignatura (opcional)',
                        ),
                        hintText: _tr(
                          'Ex.: Física',
                          'E.g. Physics',
                          'Ej.: Física',
                        ),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _text,
                      minLines: 2,
                      maxLines: 5,
                      decoration: InputDecoration(
                        labelText: _tr(
                          'Texto complementar (opcional)',
                          'Additional text (optional)',
                          'Texto adicional (opcional)',
                        ),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _tr(
                        'A IA vai gerar 8 flashcards do material.',
                        'AI will generate 8 flashcards from your material.',
                        'La IA generará 8 tarjetas a partir del material.',
                      ),
                      style: TextStyle(
                        fontSize: 13,
                        color: cores.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(_tr('Cancelar', 'Cancel', 'Cancelar')),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: purple,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    _generate();
                  },
                  icon: const Icon(Icons.auto_awesome),
                  label: Text(_tr('Gerar', 'Generate', 'Generar')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _generate() async {
    if (_loading || _picking) return;

    if (_file == null && _text.text.trim().length < 30) {
      _showError(
        _tr(
          'Selecione um arquivo ou digite pelo menos 30 caracteres.',
          'Select a file or enter at least 30 characters.',
          'Selecciona un archivo o escribe al menos 30 caracteres.',
        ),
      );
      return;
    }

    setState(() => _loading = true);

    final arquivo = _file;
    final texto = _text.text.trim();
    final materia = _subject.text.trim();

    try {
      await Navigator.pushNamed(
        context,
        '/processing',
        arguments: {'arquivo': arquivo, 'texto': texto, 'materia': materia},
      );
    } catch (e) {
      debugPrint('Erro ao iniciar processamento: $e');

      _showError(
        _tr(
          'Não foi possível iniciar o processamento.',
          'Could not start processing.',
          'No se pudo iniciar el procesamiento.',
        ),
      );
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
    required Color borderColor,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 62,
      child: OutlinedButton.icon(
        onPressed: (_loading || _picking) ? null : onPressed,
        icon: Icon(icon, size: 24),
        label: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: borderColor,
          side: BorderSide(color: borderColor, width: 2),
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
    final disabled = _loading || _picking;

    return SizedBox(
      width: double.infinity,
      height: 60,
      child: filled
          ? ElevatedButton.icon(
              onPressed: disabled ? null : onPressed,
              icon: Icon(icon),
              label: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
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
              onPressed: disabled ? null : onPressed,
              icon: Icon(icon),
              label: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
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
    return ValueListenableBuilder<Locale>(
      valueListenable: LanguageController.locale,
      builder: (context, idioma, child) {
        final dark = Theme.of(context).brightness == Brightness.dark;

        final background = dark
            ? const Color(0xFF141320)
            : const Color(0xFFF8F7FF);

        final surface = dark ? const Color(0xFF242333) : Colors.white;

        final textColor = dark ? Colors.white : const Color(0xFF17192D);

        final secondaryText = dark ? Colors.white60 : const Color(0xFF737A8C);

        final borderColor = dark
            ? const Color(0xFF454357)
            : const Color(0xFFE7E2F3);

        return Scaffold(
          backgroundColor: background,
          appBar: AppBar(
            backgroundColor: background,
            elevation: 0,
            centerTitle: true,
            title: Text(
              _tr('Criar flashcards', 'Create flashcards', 'Crear tarjetas'),
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            iconTheme: IconThemeData(color: textColor),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _tr(
                      'Deixe a IA transformar seu material em cards',
                      'Let AI turn your study materials into flashcards',
                      'Deja que la IA transforme tu material en tarjetas',
                    ),
                    style: TextStyle(
                      color: textColor,
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
                      color: surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: dark ? 0 : 0.07,
                          ),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          _tr(
                            'Escolha como deseja enviar seu material. A inteligência artificial vai analisar o conteúdo e criar flashcards para você.',
                            'Choose how to upload your material. AI will analyze the content and create flashcards for you.',
                            'Elige cómo enviar tu material. La inteligencia artificial analizará el contenido y creará tarjetas para ti.',
                          ),
                          style: TextStyle(
                            color: secondaryText,
                            fontSize: 17,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _importButton(
                          icon: Icons.camera_alt_outlined,
                          label: _tr(
                            'Abrir câmera',
                            'Open camera',
                            'Abrir cámara',
                          ),
                          onPressed: () => _pickImage(ImageSource.camera),
                          borderColor: dark ? lightPurple : purple,
                        ),
                        const SizedBox(height: 12),
                        _importButton(
                          icon: Icons.image_outlined,
                          label: _tr(
                            'Importar da galeria',
                            'Import from gallery',
                            'Importar de la galería',
                          ),
                          onPressed: () => _pickImage(ImageSource.gallery),
                          borderColor: dark ? lightPurple : purple,
                        ),
                        const SizedBox(height: 12),
                        _importButton(
                          icon: Icons.insert_drive_file_outlined,
                          label: _tr(
                            'Importar PDF',
                            'Import PDF',
                            'Importar PDF',
                          ),
                          onPressed: _pickPdf,
                          borderColor: dark ? lightPurple : purple,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _mainButton(
                    icon: Icons.note_add_outlined,
                    label: _tr(
                      'Criar card manualmente',
                      'Create card manually',
                      'Crear tarjeta manualmente',
                    ),
                    filled: true,
                    onPressed: () {
                      Navigator.pushNamed(context, '/create-manual-flashcard');
                    },
                  ),
                  const SizedBox(height: 12),
                  _mainButton(
                    icon: Icons.add,
                    label: _tr(
                      'Criar novo deck',
                      'Create new deck',
                      'Crear nuevo mazo',
                    ),
                    onPressed: () {
                      Navigator.pushNamed(context, '/create-deck');
                    },
                  ),
                  if (_loading || _picking) ...[
                    const SizedBox(height: 26),
                    const Center(
                      child: CircularProgressIndicator(color: purple),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        _tr(
                          _loading
                              ? 'Preparando material...'
                              : 'Abrindo arquivo...',
                          _loading
                              ? 'Preparing material...'
                              : 'Opening file...',
                          _loading
                              ? 'Preparando material...'
                              : 'Abriendo archivo...',
                        ),
                        style: TextStyle(color: secondaryText),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

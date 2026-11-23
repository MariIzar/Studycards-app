import 'dart:io';

import 'package:flutter/material.dart';

import 'language_controller.dart';

class ReviewImageScreen extends StatefulWidget {
  const ReviewImageScreen({super.key});

  @override
  State<ReviewImageScreen> createState() => _ReviewImageScreenState();
}

class _ReviewImageScreenState extends State<ReviewImageScreen> {
  static const Color primaryPurple = Color(0xFF6C4DFF);

  File? _imagem;
  String _materia = '';

  bool _inicializado = false;
  bool _verificando = true;
  bool _arquivoValido = false;

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
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_inicializado) {
      _inicializado = true;
      _receberImagem();
    }
  }

  Future<void> _receberImagem() async {
    final argumentos = ModalRoute.of(context)?.settings.arguments;

    File? imagem;
    String materia = '';

    if (argumentos is File) {
      imagem = argumentos;
    } else if (argumentos is String) {
      if (argumentos.trim().isNotEmpty) {
        imagem = File(argumentos);
      }
    } else if (argumentos is Map) {
      final arquivo = argumentos['arquivo'];

      if (arquivo is File) {
        imagem = arquivo;
      } else if (arquivo is String && arquivo.trim().isNotEmpty) {
        imagem = File(arquivo);
      }

      final caminho = argumentos['imagePath'] ?? argumentos['caminho'];

      if (imagem == null && caminho is String && caminho.trim().isNotEmpty) {
        imagem = File(caminho);
      }

      final materiaRecebida = argumentos['materia'];

      if (materiaRecebida is String) {
        materia = materiaRecebida;
      }
    }

    bool existe = false;

    if (imagem != null) {
      try {
        existe = await imagem.exists();
      } catch (e) {
        debugPrint('Erro ao verificar imagem: $e');
      }
    }

    if (!mounted) return;

    setState(() {
      _imagem = imagem;
      _materia = materia;
      _arquivoValido = existe;
      _verificando = false;
    });
  }

  Future<void> _usarImagem() async {
    if (_verificando || !_arquivoValido || _imagem == null) {
      return;
    }

    final imagem = _imagem!;

    try {
      final existe = await imagem.exists();

      if (!mounted) return;

      if (!existe) {
        setState(() {
          _arquivoValido = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _tr(
                'A imagem não está mais disponível. Tire outra foto.',
                'The image is no longer available. Take another photo.',
                'La imagen ya no está disponible. Toma otra foto.',
              ),
            ),
          ),
        );

        return;
      }

      Navigator.pushReplacementNamed(
        context,
        '/processing',
        arguments: {'arquivo': imagem, 'texto': '', 'materia': _materia},
      );
    } catch (e) {
      debugPrint('Erro ao abrir processamento: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _tr(
              'Não foi possível utilizar esta imagem.',
              'Could not use this image.',
              'No se pudo utilizar esta imagen.',
            ),
          ),
        ),
      );
    }
  }

  void _tirarNovamente() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LanguageController.locale,
      builder: (context, locale, child) {
        final dark = Theme.of(context).brightness == Brightness.dark;

        final background = dark
            ? const Color(0xFF141320)
            : const Color(0xFFF8F7FF);

        final surface = dark ? const Color(0xFF242333) : Colors.white;

        final previewBackground = dark
            ? const Color(0xFF242333)
            : const Color(0xFFEBEBF5);

        final text = dark ? Colors.white : const Color(0xFF191B31);

        final secondary = dark ? Colors.white60 : const Color(0xFF73798B);

        final border = dark ? const Color(0xFF454357) : const Color(0xFFE7E5F2);

        return Scaffold(
          backgroundColor: background,
          appBar: AppBar(
            backgroundColor: background,
            foregroundColor: text,
            elevation: 0,
            centerTitle: true,
            title: Text(
              _tr('Revisar imagem', 'Review image', 'Revisar imagen'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // PRÉ-VISUALIZAÇÃO
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: previewBackground,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: border),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _verificando
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: primaryPurple,
                              ),
                            )
                          : _arquivoValido && _imagem != null
                          ? InteractiveViewer(
                              minScale: 1,
                              maxScale: 4,
                              child: Center(
                                child: Image.file(
                                  _imagem!,
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return _buildPlaceholder(
                                      text,
                                      secondary,
                                      false,
                                    );
                                  },
                                ),
                              ),
                            )
                          : _buildPlaceholder(text, secondary, true),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    _tr(
                      'A imagem está boa?',
                      'Does the image look good?',
                      '¿La imagen se ve bien?',
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: text,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // TIRAR NOVAMENTE
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      backgroundColor: surface,
                      foregroundColor: text,
                      side: BorderSide(color: border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _tirarNovamente,
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: Text(
                      _tr('Tirar novamente', 'Retake photo', 'Tomar otra foto'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // USAR IMAGEM
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryPurple,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: primaryPurple.withValues(
                        alpha: 0.4,
                      ),
                      minimumSize: const Size.fromHeight(50),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _arquivoValido && !_verificando
                        ? _usarImagem
                        : null,
                    icon: const Icon(Icons.check),
                    label: Text(
                      _tr(
                        'Usar esta imagem',
                        'Use this image',
                        'Usar esta imagen',
                      ),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlaceholder(Color text, Color secondary, bool arquivoAusente) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              arquivoAusente
                  ? Icons.image_not_supported_outlined
                  : Icons.broken_image_outlined,
              size: 64,
              color: secondary,
            ),

            const SizedBox(height: 12),

            Text(
              arquivoAusente
                  ? _tr(
                      'Nenhuma imagem disponível.',
                      'No image available.',
                      'No hay ninguna imagen disponible.',
                    )
                  : _tr(
                      'Não foi possível exibir esta imagem.',
                      'Could not display this image.',
                      'No se pudo mostrar esta imagen.',
                    ),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: text,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

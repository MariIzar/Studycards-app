import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'language_controller.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final ImagePicker _picker = ImagePicker();

  bool _carregando = false;

  String _traduzir(String pt, String en, String es) {
    switch (LanguageController.locale.value.languageCode) {
      case 'en':
        return en;
      case 'es':
        return es;
      default:
        return pt;
    }
  }

  Future<void> _selecionarImagem(ImageSource origem) async {
    if (_carregando) return;

    setState(() {
      _carregando = true;
    });

    try {
      final XFile? imagem = await _picker.pickImage(
        source: origem,
        imageQuality: 85,
        maxWidth: 2048,
        maxHeight: 2048,
        requestFullMetadata: false,
      );

      if (!mounted || imagem == null) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => _PreviewImagemScreen(imagem: imagem),
        ),
      );
    } catch (erro) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _traduzir(
              'Não foi possível acessar a câmera ou galeria. Verifique as permissões do aplicativo.',
              'Could not access the camera or gallery. Check the app permissions.',
              'No se pudo acceder a la cámara o galería. Comprueba los permisos.',
            ),
          ),
        ),
      );

      debugPrint('Erro ao selecionar imagem: $erro');
    } finally {
      if (mounted) {
        setState(() {
          _carregando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LanguageController.locale,
      builder: (context, idioma, child) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        tooltip: _traduzir('Fechar', 'Close', 'Cerrar'),
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Icon(
                        Icons.camera_alt_outlined,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF17171B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.camera_alt_outlined,
                            size: 72,
                            color: Colors.white54,
                          ),
                          const SizedBox(height: 18),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              _traduzir(
                                'Toque no botão abaixo para abrir a câmera do celular.',
                                'Tap the button below to open your phone camera.',
                                'Toca el botón de abajo para abrir la cámara del teléfono.',
                              ),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    _traduzir(
                      'Fotografe suas anotações',
                      'Take a photo of your notes',
                      'Fotografía tus apuntes',
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 24),

                Padding(
                  padding: const EdgeInsets.only(
                    left: 32,
                    right: 32,
                    bottom: 32,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        tooltip: _traduzir(
                          'Abrir galeria',
                          'Open gallery',
                          'Abrir galería',
                        ),
                        onPressed: _carregando
                            ? null
                            : () => _selecionarImagem(ImageSource.gallery),
                        icon: const Icon(
                          Icons.photo_library_outlined,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),

                      GestureDetector(
                        onTap: _carregando
                            ? null
                            : () => _selecionarImagem(ImageSource.camera),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF8C7CFF),
                              width: 4,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 32,
                            backgroundColor: Colors.white,
                            child: _carregando
                                ? const SizedBox(
                                    width: 26,
                                    height: 26,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      color: Color(0xFF6C4DFF),
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      ),

                      const SizedBox(width: 48),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PreviewImagemScreen extends StatelessWidget {
  final XFile imagem;

  const _PreviewImagemScreen({required this.imagem});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LanguageController.locale,
      builder: (context, idioma, child) {
        String traduzir(String pt, String en, String es) {
          switch (idioma.languageCode) {
            case 'en':
              return en;
            case 'es':
              return es;
            default:
              return pt;
          }
        }

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: Text(
              traduzir('Revisar imagem', 'Review image', 'Revisar imagen'),
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: Image.file(
                      File(imagem.path),
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Text(
                          traduzir(
                            'Erro ao abrir imagem.',
                            'Error opening image.',
                            'Error al abrir la imagen.',
                          ),
                          style: const TextStyle(color: Colors.white),
                        );
                      },
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(52),
                          ),
                          child: Text(
                            traduzir('Tirar outra', 'Retake', 'Tomar otra'),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // Integração com a tela existente
                            // será feita em review_image.dart.
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  traduzir(
                                    'Imagem selecionada. Falta conectar ao processamento.',
                                    'Image selected. Processing integration is pending.',
                                    'Imagen seleccionada. Falta conectar el procesamiento.',
                                  ),
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6C4DFF),
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(52),
                          ),
                          child: Text(
                            traduzir('Continuar', 'Continue', 'Continuar'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

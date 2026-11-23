import 'dart:io';

import 'package:flutter/material.dart';

import 'language_controller.dart';
import 'services/ai_service.dart';

class ProcessingScreen extends StatefulWidget {
  const ProcessingScreen({super.key});

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> {
  static const Color purple = Color(0xFF7138F5);

  bool _iniciado = false;
  bool _processando = false;

  String? _erro;

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

    if (!_iniciado) {
      _iniciado = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _processar();
        }
      });
    }
  }

  String _mensagemErro(Object erro) {
    final mensagem = erro.toString().replaceFirst(
      RegExp(r'^Exception:\s*'),
      '',
    );

    final normalizada = mensagem.toLowerCase();

    if (normalizada.contains('socketexception') ||
        normalizada.contains('failed host lookup') ||
        normalizada.contains('network') ||
        normalizada.contains('connection refused') ||
        normalizada.contains('sem conexão')) {
      return _tr(
        'Não foi possível conectar ao serviço de IA. Verifique sua internet e tente novamente.',
        'Could not connect to the AI service. Check your internet connection and try again.',
        'No se pudo conectar al servicio de IA. Comprueba tu conexión a internet e inténtalo de nuevo.',
      );
    }

    if (normalizada.contains('timeout') ||
        normalizada.contains('tempo limite')) {
      return _tr(
        'O processamento demorou mais que o esperado. Tente novamente.',
        'Processing took longer than expected. Please try again.',
        'El procesamiento tardó más de lo esperado. Inténtalo de nuevo.',
      );
    }

    if (normalizada.contains('401') ||
        normalizada.contains('403') ||
        normalizada.contains('unauthorized') ||
        normalizada.contains('forbidden')) {
      return _tr(
        'O serviço de IA não autorizou a solicitação. Verifique a configuração do serviço.',
        'The AI service did not authorize the request. Check the service configuration.',
        'El servicio de IA no autorizó la solicitud. Comprueba su configuración.',
      );
    }

    if (normalizada.contains('429') ||
        normalizada.contains('rate limit') ||
        normalizada.contains('quota')) {
      return _tr(
        'O serviço de IA atingiu um limite de solicitações. Aguarde um pouco e tente novamente.',
        'The AI service has reached a request limit. Please wait and try again.',
        'El servicio de IA alcanzó un límite de solicitudes. Espera e inténtalo de nuevo.',
      );
    }

    if (normalizada.contains('file not found') ||
        normalizada.contains('no such file') ||
        normalizada.contains('arquivo não encontrado')) {
      return _tr(
        'O arquivo selecionado não foi encontrado. Volte e selecione o material novamente.',
        'The selected file could not be found. Go back and select the material again.',
        'No se encontró el archivo seleccionado. Vuelve y selecciona el material otra vez.',
      );
    }

    // Evita mostrar detalhes técnicos ou respostas
    // internas do serviço diretamente na interface.
    debugPrint('Falha ao gerar flashcards: $mensagem');

    return _tr(
      'Não foi possível gerar os flashcards. Verifique o material e tente novamente.',
      'Could not generate the flashcards. Check your material and try again.',
      'No se pudieron generar las tarjetas. Comprueba el material e inténtalo de nuevo.',
    );
  }

  Future<void> _processar() async {
    if (_processando || !mounted) return;

    final argumentos = ModalRoute.of(context)?.settings.arguments;

    if (argumentos is! Map) {
      setState(() {
        _erro = _tr(
          'Nenhum material foi recebido para processamento.',
          'No material was received for processing.',
          'No se recibió material para procesar.',
        );
      });
      return;
    }

    final arquivoValor = argumentos['arquivo'];
    final textoValor = argumentos['texto'];
    final materiaValor = argumentos['materia'];

    final File? arquivo = arquivoValor is File ? arquivoValor : null;

    final String texto = textoValor is String ? textoValor : '';

    final String materia = materiaValor is String ? materiaValor : '';

    if (arquivo == null && texto.trim().isEmpty) {
      setState(() {
        _erro = _tr(
          'Nenhum material foi selecionado.',
          'No material was selected.',
          'No se seleccionó ningún material.',
        );
      });
      return;
    }

    setState(() {
      _processando = true;
      _erro = null;
    });

    try {
      if (arquivo != null) {
        final existe = await arquivo.exists();

        if (!existe) {
          throw const FileSystemException('File not found');
        }
      }

      final result = await AiService.gerarFlashcards(
        arquivo: arquivo,
        texto: texto,
        materia: materia,
      );

      if (!mounted) return;

      final resultado = Map<String, dynamic>.from(result);

      resultado['localFilePath'] = arquivo?.path;

      Navigator.pushReplacementNamed(
        context,
        '/generated-flashcards',
        arguments: resultado,
      );
    } catch (e) {
      debugPrint('Erro no processamento: $e');

      if (!mounted) return;

      setState(() {
        _erro = _mensagemErro(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          _processando = false;
        });
      }
    }
  }

  void _voltar() {
    if (_processando) return;

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
        final theme = Theme.of(context);
        final colors = theme.colorScheme;

        final escuro = theme.brightness == Brightness.dark;

        final fundo = escuro
            ? const Color(0xFF141320)
            : const Color(0xFFF8F7FF);

        final texto = escuro ? Colors.white : const Color(0xFF191B31);

        final secundario = escuro ? Colors.white60 : const Color(0xFF73798B);

        return Scaffold(
          backgroundColor: fundo,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 21,
                  vertical: 28,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ÍCONE PRINCIPAL
                    Container(
                      width: 94,
                      height: 94,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF9A4CFF), Color(0xFF5920D7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: escuro ? colors.surface : Colors.white,
                          width: 5,
                        ),
                      ),
                      child: const Icon(
                        Icons.school_rounded,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // TÍTULO
                    Text(
                      _erro == null
                          ? _tr(
                              'Processando seu material...',
                              'Processing your material...',
                              'Procesando tu material...',
                            )
                          : _tr(
                              'Não foi possível processar',
                              'Processing failed',
                              'No se pudo procesar',
                            ),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: texto,
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 7),

                    // DESCRIÇÃO
                    Text(
                      _erro == null
                          ? _tr(
                              'A IA está analisando e criando seus flashcards.',
                              'AI is analyzing your material and creating flashcards.',
                              'La IA está analizando tu material y creando tarjetas de estudio.',
                            )
                          : _erro!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: secundario,
                        fontSize: 16,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 25),

                    if (_erro == null) ...[
                      // PROGRESSO INDETERMINADO:
                      // a API não fornece porcentagem real.
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          minHeight: 8,
                          backgroundColor: escuro
                              ? Colors.white12
                              : const Color(0xFFE7E5F0),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            purple,
                          ),
                        ),
                      ),

                      const SizedBox(height: 13),

                      Text(
                        _tr(
                          'Analisando o material e criando flashcards...',
                          'Analyzing material and creating flashcards...',
                          'Analizando el material y creando tarjetas...',
                        ),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: secundario, fontSize: 14),
                      ),
                    ] else ...[
                      // TENTAR NOVAMENTE
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: _processando ? null : _processar,
                          icon: const Icon(Icons.refresh_rounded),
                          label: Text(
                            _tr(
                              'Tentar novamente',
                              'Try again',
                              'Intentar de nuevo',
                            ),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: purple,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // VOLTAR
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton(
                          onPressed: _voltar,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: purple,
                            side: const BorderSide(color: purple),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            _tr(
                              'Voltar e selecionar outro material',
                              'Go back and select another material',
                              'Volver y seleccionar otro material',
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Mantido para compatibilidade com outras telas.
class CheckItem extends StatelessWidget {
  final String title;
  final bool isDone;

  const CheckItem({super.key, required this.title, required this.isDone});

  @override
  Widget build(BuildContext context) {
    final escuro = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: isDone
              ? const Color(0xFF7138F5)
              : (escuro ? Colors.white12 : Colors.black12),
          child: Icon(
            isDone ? Icons.check : Icons.circle_outlined,
            color: isDone ? Colors.white : Colors.grey,
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
        ),
      ],
    );
  }
}

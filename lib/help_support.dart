import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'language_controller.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const Color purple = Color(0xFF6C4DFF);

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

  Future<void> _sendEmail(
    BuildContext context, {
    required String subject,
    required String body,
  }) async {
    final emailController = TextEditingController();

    try {
      final recipient = await showDialog<String>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text(_tr('Enviar e-mail', 'Send email', 'Enviar correo')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _tr(
                    'Informe o endereço de suporte do StudyCards.',
                    'Enter the StudyCards support email address.',
                    'Introduce el correo de soporte de StudyCards.',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: _tr(
                      'E-mail de destino',
                      'Recipient email',
                      'Correo de destino',
                    ),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(_tr('Cancelar', 'Cancel', 'Cancelar')),
              ),
              FilledButton(
                onPressed: () {
                  final email = emailController.text.trim();

                  if (RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
                    Navigator.pop(dialogContext, email);
                  } else {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(
                        content: Text(
                          _tr(
                            'Informe um e-mail válido.',
                            'Enter a valid email.',
                            'Introduce un correo válido.',
                          ),
                        ),
                      ),
                    );
                  }
                },
                child: Text(_tr('Continuar', 'Continue', 'Continuar')),
              ),
            ],
          );
        },
      );

      if (recipient == null || !context.mounted) return;

      final uri = Uri(
        scheme: 'mailto',
        path: recipient,
        query: _encodeQueryParameters({'subject': subject, 'body': body}),
      );

      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

      if (!opened && context.mounted) {
        _showMessage(
          context,
          _tr(
            'Não foi possível abrir um aplicativo de e-mail.',
            'Could not open an email application.',
            'No se pudo abrir una aplicación de correo.',
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        _showMessage(
          context,
          _tr(
            'Erro ao abrir o e-mail.',
            'Error opening email.',
            'Error al abrir el correo.',
          ),
        );
      }
    } finally {
      emailController.dispose();
    }
  }

  String _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map(
          (entry) =>
              '${Uri.encodeComponent(entry.key)}=${Uri.encodeComponent(entry.value)}',
        )
        .join('&');
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _showHelpCenter(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: Text(
              _tr('Central de Ajuda', 'Help Center', 'Centro de ayuda'),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                _tr(
                  'Perguntas frequentes',
                  'Frequently asked questions',
                  'Preguntas frecuentes',
                ),
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _faq(
                _tr(
                  'Como criar um deck?',
                  'How do I create a deck?',
                  '¿Cómo creo un mazo?',
                ),
                _tr(
                  'Acesse a área de decks, escolha a opção de criar um novo deck e informe os dados solicitados.',
                  'Open the decks section, choose to create a new deck and enter the requested information.',
                  'Abre la sección de mazos, crea un nuevo mazo e introduce la información solicitada.',
                ),
              ),
              _faq(
                _tr(
                  'Como criar flashcards?',
                  'How do I create flashcards?',
                  '¿Cómo creo tarjetas?',
                ),
                _tr(
                  'Você pode criar flashcards manualmente ou utilizar os recursos de geração por inteligência artificial disponíveis no aplicativo.',
                  'You can create flashcards manually or use the AI generation features available in the app.',
                  'Puedes crear tarjetas manualmente o utilizar las funciones de generación con inteligencia artificial.',
                ),
              ),
              _faq(
                _tr(
                  'Como estudar meus flashcards?',
                  'How do I study my flashcards?',
                  '¿Cómo estudio mis tarjetas?',
                ),
                _tr(
                  'Abra um deck com flashcards e inicie uma sessão de estudo.',
                  'Open a deck containing flashcards and start a study session.',
                  'Abre un mazo con tarjetas e inicia una sesión de estudio.',
                ),
              ),
              _faq(
                _tr(
                  'Como recuperar minha senha?',
                  'How do I reset my password?',
                  '¿Cómo recupero mi contraseña?',
                ),
                _tr(
                  'Na tela de login, toque em Esqueci minha senha. Informe seu e-mail cadastrado para receber um link de redefinição.',
                  'On the login screen, tap Forgot password. Enter your registered email to receive a reset link.',
                  'En la pantalla de inicio de sesión, pulsa Olvidé mi contraseña. Introduce tu correo registrado para recibir un enlace.',
                ),
              ),
              _faq(
                _tr(
                  'Como alterar o idioma?',
                  'How do I change the language?',
                  '¿Cómo cambio el idioma?',
                ),
                _tr(
                  'Acesse as configurações e selecione português, inglês ou espanhol.',
                  'Open settings and select Portuguese, English or Spanish.',
                  'Abre la configuración y selecciona portugués, inglés o español.',
                ),
              ),
              _faq(
                _tr(
                  'Como ativar o modo escuro?',
                  'How do I enable dark mode?',
                  '¿Cómo activo el modo oscuro?',
                ),
                _tr(
                  'Acesse as configurações de aparência e selecione o tema escuro.',
                  'Open appearance settings and select dark mode.',
                  'Abre la configuración de apariencia y selecciona el modo oscuro.',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _faq(String question, String answer) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [Align(alignment: Alignment.centerLeft, child: Text(answer))],
      ),
    );
  }

  void _reportProblem(BuildContext context) {
    final descriptionController = TextEditingController();
    String selectedType = 'bug';

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text(
                _tr(
                  'Reportar um problema',
                  'Report a problem',
                  'Reportar un problema',
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _tr(
                        'Qual problema você encontrou?',
                        'What problem did you encounter?',
                        '¿Qué problema encontraste?',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedType,
                      decoration: InputDecoration(
                        labelText: _tr(
                          'Tipo de problema',
                          'Problem type',
                          'Tipo de problema',
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'bug',
                          child: Text(
                            _tr(
                              'Erro no aplicativo',
                              'App error',
                              'Error en la aplicación',
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'account',
                          child: Text(
                            _tr(
                              'Problema com a conta',
                              'Account problem',
                              'Problema con la cuenta',
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'ai',
                          child: Text(
                            _tr(
                              'Problema com a IA',
                              'AI problem',
                              'Problema con la IA',
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'other',
                          child: Text(_tr('Outro', 'Other', 'Otro')),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            selectedType = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      maxLines: 5,
                      maxLength: 1000,
                      decoration: InputDecoration(
                        labelText: _tr(
                          'Descrição',
                          'Description',
                          'Descripción',
                        ),
                        hintText: _tr(
                          'Descreva o que aconteceu...',
                          'Describe what happened...',
                          'Describe lo que ocurrió...',
                        ),
                        alignLabelWithHint: true,
                        border: const OutlineInputBorder(),
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
                FilledButton(
                  onPressed: () {
                    final description = descriptionController.text.trim();

                    if (description.isEmpty) {
                      _showMessage(
                        dialogContext,
                        _tr(
                          'Descreva o problema antes de continuar.',
                          'Describe the problem before continuing.',
                          'Describe el problema antes de continuar.',
                        ),
                      );
                      return;
                    }

                    final typeLabels = {
                      'bug': 'App error',
                      'account': 'Account problem',
                      'ai': 'AI problem',
                      'other': 'Other',
                    };

                    Navigator.pop(dialogContext);

                    _sendEmail(
                      context,
                      subject:
                          'StudyCards - Problem report: ${typeLabels[selectedType]}',
                      body:
                          'Problem type: ${typeLabels[selectedType]}\n\n'
                          'Description:\n$description\n\n'
                          'App: StudyCards',
                    );
                  },
                  child: Text(_tr('Enviar', 'Send', 'Enviar')),
                ),
              ],
            );
          },
        );
      },
    ).then((_) => descriptionController.dispose());
  }

  void _showDocument(
    BuildContext context, {
    required String title,
    required String content,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(title)),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: SelectableText(
              content,
              style: const TextStyle(fontSize: 15, height: 1.6),
            ),
          ),
        ),
      ),
    );
  }

  void _showLegalDocuments(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.description_outlined, color: purple),
                title: Text(
                  _tr('Termos de Uso', 'Terms of Use', 'Términos de uso'),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showDocument(
                    context,
                    title: _tr(
                      'Termos de Uso',
                      'Terms of Use',
                      'Términos de uso',
                    ),
                    content: _termsText(),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined, color: purple),
                title: Text(
                  _tr(
                    'Política de Privacidade',
                    'Privacy Policy',
                    'Política de privacidad',
                  ),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showDocument(
                    context,
                    title: _tr(
                      'Política de Privacidade',
                      'Privacy Policy',
                      'Política de privacidad',
                    ),
                    content: _privacyText(),
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  String _termsText() {
    return _tr(
      '''STUDYCARDS - TERMOS DE USO
RASCUNHO PARA REVISÃO

1. OBJETIVO
O StudyCards é um aplicativo voltado à organização de materiais de estudo, criação de flashcards e apoio à aprendizagem.

2. CONTAS
O usuário é responsável por manter suas credenciais de acesso protegidas e utilizar o aplicativo de forma adequada.

3. CONTEÚDO
O usuário é responsável pelos materiais inseridos no aplicativo e deve respeitar os direitos de terceiros.

4. INTELIGÊNCIA ARTIFICIAL
Os conteúdos gerados por inteligência artificial podem apresentar erros. Recomenda-se verificar as informações antes de utilizá-las nos estudos.

5. DISPONIBILIDADE
O aplicativo pode passar por atualizações, manutenção ou interrupções técnicas.

6. ALTERAÇÕES
Estes termos poderão ser atualizados conforme a evolução do serviço.

Este documento é um rascunho e deve ser revisado antes da publicação oficial.''',
      '''STUDYCARDS - TERMS OF USE
DRAFT FOR REVIEW

1. PURPOSE
StudyCards is an application for organizing study materials, creating flashcards and supporting learning.

2. ACCOUNTS
Users are responsible for protecting their login credentials and using the application appropriately.

3. CONTENT
Users are responsible for materials they upload and must respect third-party rights.

4. ARTIFICIAL INTELLIGENCE
AI-generated content may contain errors. Users should verify information before relying on it.

5. AVAILABILITY
The application may undergo updates, maintenance or technical interruptions.

6. CHANGES
These terms may be updated as the service evolves.

This document is a draft and must be reviewed before official publication.''',
      '''STUDYCARDS - TÉRMINOS DE USO
BORRADOR PARA REVISIÓN

1. OBJETIVO
StudyCards es una aplicación para organizar materiales de estudio, crear tarjetas y apoyar el aprendizaje.

2. CUENTAS
Los usuarios son responsables de proteger sus credenciales y utilizar la aplicación adecuadamente.

3. CONTENIDO
Los usuarios son responsables de los materiales que incorporan y deben respetar los derechos de terceros.

4. INTELIGENCIA ARTIFICIAL
El contenido generado por IA puede contener errores. Se recomienda verificar la información.

5. DISPONIBILIDAD
La aplicación puede experimentar actualizaciones, mantenimiento o interrupciones técnicas.

6. CAMBIOS
Estos términos pueden actualizarse conforme evolucione el servicio.

Este documento es un borrador y debe revisarse antes de su publicación oficial.''',
    );
  }

  String _privacyText() {
    return _tr(
      '''STUDYCARDS - POLÍTICA DE PRIVACIDADE
RASCUNHO PARA REVISÃO

1. FINALIDADE
O StudyCards utiliza informações necessárias para autenticação, gerenciamento de contas e funcionamento dos recursos de estudo.

2. DADOS
Dependendo das funcionalidades utilizadas, o aplicativo pode tratar informações de perfil, e-mail, decks, flashcards e materiais de estudo.

3. ARMAZENAMENTO
O aplicativo utiliza armazenamento local e serviços de autenticação e sincronização na nuvem.

4. INTELIGÊNCIA ARTIFICIAL
Materiais enviados para recursos de IA podem precisar ser processados por serviços externos. Os fornecedores e as condições desse tratamento devem ser identificados na versão definitiva.

5. SEGURANÇA
O projeto deve adotar medidas técnicas e organizacionais adequadas para proteger os dados.

6. DIREITOS DOS USUÁRIOS
Os procedimentos para acesso, correção e exclusão de dados devem ser definidos conforme a legislação aplicável, incluindo a LGPD.

7. CONTATO
O canal oficial de privacidade deverá ser informado na versão definitiva.

Este documento é provisório e não substitui uma política de privacidade revisada conforme as práticas reais do aplicativo.''',
      '''STUDYCARDS - PRIVACY POLICY
DRAFT FOR REVIEW

1. PURPOSE
StudyCards processes information needed for authentication, account management and study features.

2. DATA
Depending on the features used, the app may process profile information, email addresses, decks, flashcards and study materials.

3. STORAGE
The app uses local storage and cloud authentication and synchronization services.

4. ARTIFICIAL INTELLIGENCE
Materials submitted to AI features may be processed by external services. Providers and processing conditions must be identified in the final version.

5. SECURITY
The project should adopt appropriate technical and organizational safeguards.

6. USER RIGHTS
Procedures for accessing, correcting and deleting personal data must be defined under applicable law.

7. CONTACT
An official privacy contact must be provided in the final version.

This document is provisional and does not replace a privacy policy reviewed against the app's actual practices.''',
      '''STUDYCARDS - POLÍTICA DE PRIVACIDAD
BORRADOR PARA REVISIÓN

1. FINALIDAD
StudyCards utiliza información necesaria para la autenticación, gestión de cuentas y funciones de estudio.

2. DATOS
Según las funciones utilizadas, la aplicación puede tratar datos de perfil, correos electrónicos, mazos, tarjetas y materiales de estudio.

3. ALMACENAMIENTO
La aplicación utiliza almacenamiento local y servicios de autenticación y sincronización en la nube.

4. INTELIGENCIA ARTIFICIAL
Los materiales enviados a funciones de IA pueden ser procesados por servicios externos. Los proveedores y las condiciones deben identificarse en la versión definitiva.

5. SEGURIDAD
El proyecto debe adoptar medidas técnicas y organizativas adecuadas para proteger los datos.

6. DERECHOS
Los procedimientos de acceso, corrección y eliminación de datos deben definirse según la legislación aplicable.

7. CONTACTO
La versión definitiva deberá indicar un contacto oficial de privacidad.

Este documento es provisional y no sustituye una política revisada según las prácticas reales de la aplicación.''',
    );
  }

  Widget _buildHelpItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final colors = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
      leading: Icon(icon, color: purple, size: 25),
      title: Text(
        title,
        style: TextStyle(
          color: colors.onSurface,
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LanguageController.locale,
      builder: (context, locale, child) {
        final theme = Theme.of(context);
        final colors = theme.colorScheme;

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            foregroundColor: colors.onSurface,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            title: Text(
              _tr('Ajuda e suporte', 'Help and support', 'Ayuda y soporte'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _tr(
                      'Como podemos ajudar?',
                      'How can we help?',
                      '¿Cómo podemos ayudarte?',
                    ),
                    style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _tr(
                      'Encontre respostas ou entre em contato.',
                      'Find answers or get in touch.',
                      'Encuentra respuestas o ponte en contacto.',
                    ),
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: colors.outlineVariant),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildHelpItem(
                          context: context,
                          icon: Icons.chat_bubble_outline,
                          title: _tr(
                            'Central de Ajuda',
                            'Help Center',
                            'Centro de ayuda',
                          ),
                          onTap: () => _showHelpCenter(context),
                        ),
                        const Divider(height: 1),
                        _buildHelpItem(
                          context: context,
                          icon: Icons.mail_outline,
                          title: _tr(
                            'Fale Conosco por E-mail',
                            'Contact Us by Email',
                            'Contáctanos por correo',
                          ),
                          onTap: () => _sendEmail(
                            context,
                            subject: 'StudyCards - Support',
                            body: '',
                          ),
                        ),
                        const Divider(height: 1),
                        _buildHelpItem(
                          context: context,
                          icon: Icons.bug_report_outlined,
                          title: _tr(
                            'Reportar um Problema',
                            'Report a Problem',
                            'Reportar un problema',
                          ),
                          onTap: () => _reportProblem(context),
                        ),
                        const Divider(height: 1),
                        _buildHelpItem(
                          context: context,
                          icon: Icons.info_outline,
                          title: _tr(
                            'Termos de Uso e Privacidade',
                            'Terms of Use and Privacy',
                            'Términos de uso y privacidad',
                          ),
                          onTap: () => _showLegalDocuments(context),
                        ),
                      ],
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
}

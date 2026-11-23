import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

/// Cliente HTTP do StudyCards.
///
/// A chave da Gemini permanece somente no backend.
/// O aplicativo envia o token do Firebase Authentication
/// para que o servidor possa validar a identidade do usuário.
class AiService {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://studycards-ai-backend.onrender.com',
  );

  static Future<Map<String, dynamic>> gerarFlashcards({
    File? arquivo,
    String? texto,
    String? materia,
  }) async {
    final uri = Uri.parse('$baseUrl/api/materials/flashcards');

    final client = http.Client();

    try {
      print('[StudyCards] Backend configurado: $baseUrl');
      print('[StudyCards] Endpoint: $uri');
      print('[StudyCards] Iniciando geração de flashcards...');

      // =========================================
      // AUTENTICAÇÃO FIREBASE
      // =========================================

      final usuario = FirebaseAuth.instance.currentUser;

      if (usuario == null) {
        throw Exception(
          'Você precisa estar conectado para gerar flashcards com IA.',
        );
      }

      final token = await usuario.getIdToken();

      if (token == null || token.isEmpty) {
        throw Exception(
          'Não foi possível autenticar sua sessão. '
          'Faça login novamente.',
        );
      }

      print('[StudyCards] Token de autenticação obtido.');

      // =========================================
      // PREPARAR REQUISIÇÃO
      // =========================================

      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..fields['text'] = texto ?? ''
        ..fields['subject'] = materia ?? ''
        ..fields['count'] = '8';

      if (arquivo != null) {
        print('[StudyCards] Arquivo: ${arquivo.path}');

        request.files.add(
          await http.MultipartFile.fromPath('file', arquivo.path),
        );
      }

      // =========================================
      // ENVIAR PARA O BACKEND
      // =========================================

      print('[StudyCards] Enviando requisição ao backend...');

      final streamed = await client
          .send(request)
          .timeout(const Duration(minutes: 10));

      final response = await http.Response.fromStream(streamed);

      print('[StudyCards] Status HTTP: ${response.statusCode}');

      final resultado = _decode(response);
      final cards = resultado['cards'];

      if (cards is! List || cards.isEmpty) {
        throw Exception('A IA respondeu, mas não retornou flashcards.');
      }

      print('[StudyCards] ${cards.length} flashcards recebidos!');

      return resultado;
    } on TimeoutException catch (erro) {
      print('[StudyCards] TIMEOUT: $erro');

      throw Exception(
        'A geração demorou mais de 10 minutos. '
        'Tente novamente com um arquivo menor.',
      );
    } on SocketException catch (erro) {
      print('[StudyCards] ERRO DE REDE: $erro');
      print('[StudyCards] Endereço utilizado: $uri');

      throw Exception(
        'Não foi possível conectar ao backend. '
        'Verifique sua conexão com a internet.',
      );
    } on http.ClientException catch (erro) {
      print('[StudyCards] ERRO HTTP: $erro');

      throw Exception('Falha na comunicação com o backend: $erro');
    } on FirebaseAuthException catch (erro) {
      print('[StudyCards] ERRO FIREBASE: ${erro.code}');

      throw Exception(
        'Não foi possível autenticar sua sessão. '
        'Faça login novamente.',
      );
    } catch (erro, stackTrace) {
      print('[StudyCards] ERRO: $erro');
      print('[StudyCards] STACK TRACE: $stackTrace');
      rethrow;
    } finally {
      client.close();
    }
  }

  // =========================================
  // INTERPRETAR RESPOSTA DO SERVIDOR
  // =========================================

  static Map<String, dynamic> _decode(http.Response response) {
    Map<String, dynamic> body;

    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw Exception(
        'Resposta inválida do servidor '
        '(${response.statusCode}).',
      );
    }

    if (response.statusCode == 401) {
      throw Exception(
        'Sua sessão não foi autorizada. '
        'Faça login novamente.',
      );
    }

    if (response.statusCode == 403) {
      throw Exception('Você não tem permissão para utilizar a IA.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        body['error']?.toString() ?? 'Erro na API (${response.statusCode}).',
      );
    }

    return body;
  }
}

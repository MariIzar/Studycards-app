import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Cliente HTTP do Study Cards. A chave do Gemini nunca deve ficar no Flutter.
class AiService {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );

  static Future<Map<String, dynamic>> gerarFlashcards({
    File? arquivo,
    String? texto,
    String? materia,
  }) async {
    final uri = Uri.parse('$baseUrl/api/materials/flashcards');
    final request = http.MultipartRequest('POST', uri)
      ..fields['text'] = texto ?? ''
      ..fields['subject'] = materia ?? ''
      ..fields['count'] = '8';

    if (arquivo != null) {
      request.files.add(await http.MultipartFile.fromPath('file', arquivo.path));
    }

    final streamed = await request.send().timeout(const Duration(minutes: 3));
    final response = await http.Response.fromStream(streamed);
    return _decode(response);
  }

  static Map<String, dynamic> _decode(http.Response response) {
    Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('Resposta inválida do servidor (${response.statusCode}).');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(body['error']?.toString() ?? 'Erro na API (${response.statusCode}).');
    }
    return body;
  }
}

// routes/api/exercises/quick_word_game/generate_word.dart

import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:http/http.dart' as http;
import 'package:dotenv/dotenv.dart' show env, load;

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: 405); // Method Not Allowed
  }

  load();
  final geminiApiKey = env['GEMINI_API_KEY'] ?? '';

  if (geminiApiKey.isEmpty) {
    print('❌ ERRO: GEMINI_API_KEY não configurada no .env');
    return Response.json(
      statusCode: 500,
      body: {'error': 'Chave da API Gemini não configurada.'},
    );
  }

  try {
    // Prompt para gerar uma palavra para o jogo.
    // Você pode refinar este prompt para incluir sons específicos, etc.
    final prompt = '''
Gere uma única palavra simples em português, com 2 a 3 sílabas, para um exercício de pronúncia.
A palavra não deve ser um trava-língua nem uma frase.
Ex: "Casa", "Bola", "Dedo, etc".
Responda APENAS com a palavra. Nenhuma outra informação.
''';

    final response = await http.post(
      Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$geminiApiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final word = data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? 'Palavra';
      // Limpa a palavra de caracteres indesejados que a IA possa adicionar
      final cleanWord = word.trim().replaceAll(RegExp(r'[.,!?"]'), '');

      return Response.json(body: {'word': cleanWord});
    } else {
      print('❌ Erro na chamada ao Gemini para gerar palavra: ${response.statusCode} - ${response.body}');
      return Response.json(
        statusCode: 500,
        body: {'error': 'Erro ao gerar palavra da IA.'},
      );
    }
  } catch (e, stack) {
    print('❌ ERRO AO GERAR PALAVRA DO JOGO (catch externo): $e');
    print(stack);
    return Response.json(statusCode: 500, body: {'error': e.toString()});
  }
}
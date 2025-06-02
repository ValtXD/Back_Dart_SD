import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:http/http.dart' as http;
import 'package:funfono_backend/services/database_service.dart';

Future<Response> onRequest(RequestContext context) async {
  final db = context.read<DatabaseService>().connection;

  try {
    final body = await context.request.body();
    final data = jsonDecode(body);

    final userId = data['user_id']?.toString();
    final fraseOriginal = data['frase']?.toString();
    final falaUsuario = data['fala_usuario']?.toString();

    if (userId == null || fraseOriginal == null || falaUsuario == null) {
      return Response.json(
        statusCode: 400,
        body: {'error': 'Campos obrigatórios: user_id, frase, fala_usuario'},
      );
    }

    final acertou = normalize(fraseOriginal) == normalize(falaUsuario);

    // Prompt para a Gemini IA avaliar os erros e dicas
    final prompt = '''
Você é um fonoaudiólogo virtual. O usuário tentou falar a frase:

"$fraseOriginal"

Mas falou:

"$falaUsuario"

Liste as palavras que foram pronunciadas incorretamente, se houver, e dê dicas práticas para melhorar a pronúncia, de forma clara e breve.
''';

    final response = await http.post(
      Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=AIzaSyClP7PDzQR6AYg1hH7RZoNiZ-reoiQrNrs'),
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

    String? avaliacao;
    if (response.statusCode == 200) {
      final geminiData = jsonDecode(response.body);
      avaliacao = geminiData['candidates']?[0]?['content']?['parts']?[0]?['text'];
    }

    // Salvar resultado da tentativa no banco
    await db.query('''
      INSERT INTO speech_attempts (
        user_id, frase, acertou, erros, dicas
      ) VALUES (
        @userId, @frase, @acertou, @erros, @dicas
      )
    ''', substitutionValues: {
      'userId': userId,
      'frase': fraseOriginal,
      'acertou': acertou,
      'erros': acertou ? null : avaliacao,
      'dicas': acertou ? null : avaliacao,
    });

    return Response.json(body: {
      'acertou': acertou,
      'avaliacao': avaliacao ?? 'Não foi possível avaliar a fala.',
    });
  } catch (e, stack) {
    print('❌ ERRO AO AVALIAR FALA: $e');
    print(stack);
    return Response.json(
      statusCode: 500,
      body: {'error': 'Erro interno ao avaliar fala.'},
    );
  }
}

String normalize(String input) {
  final map = {
    'á': 'a',
    'à': 'a',
    'ã': 'a',
    'â': 'a',
    'é': 'e',
    'ê': 'e',
    'í': 'i',
    'î': 'i',
    'ó': 'o',
    'õ': 'o',
    'ô': 'o',
    'ú': 'u',
    'û': 'u',
    'ç': 'c',
  };

  return input
      .toLowerCase()
      .split('')
      .map((char) => map[char] ?? char)
      .join();
}

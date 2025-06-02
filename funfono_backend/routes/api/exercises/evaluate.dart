import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:http/http.dart' as http;
import 'package:funfono_backend/services/database_service.dart';

Future<Response> onRequest(RequestContext context) async {
  final db = context.read<DatabaseService>().connection;

  try {
    final body = await context.request.body();
    final data = jsonDecode(body);

    final userId = data['user_id'];
    final palavra = data['palavra'];
    final falaUsuario = data['fala_usuario'];
    final som = data['som'];

    if (userId == null || palavra == null || falaUsuario == null || som == null) {
      return Response.json(
        statusCode: 400,
        body: {'error': 'Campos obrigatórios: user_id, palavra, fala_usuario, som'},
      );
    }

    // Verifica se a fala está correta (ignora acento e caixa)
    final acertou = normalize(palavra) == normalize(falaUsuario);

    String? dicaGerada;

    if (!acertou) {
      final prompt = '''
Você é um fonoaudiólogo virtual. Dê uma dica de pronúncia curta e prática para ajudar a pessoa a pronunciar corretamente a palavra "$palavra" com base no som "$som".
Foque em orientação sobre como posicionar a boca, língua ou lábios. Use linguagem simples.
''';

      final geminiResponse = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=AIzaSyClP7PDzQR6AYg1hH7RZoNiZ-reoiQrNrs'),
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

      if (geminiResponse.statusCode == 200) {
        final geminiData = jsonDecode(geminiResponse.body);
        dicaGerada = geminiData['candidates']?[0]?['content']?['parts']?[0]?['text'];
      }
    }

    // Salvar tentativa no banco
    await db.query(
      '''
      INSERT INTO pronunciation_attempts (user_id, palavra, som, fala_usuario, correto, dica)
      VALUES (@userId, @palavra, @som, @falaUsuario, @correto, @dica)
      ''',
      substitutionValues: {
        'userId': userId,
        'palavra': palavra,
        'som': som,
        'falaUsuario': falaUsuario,
        'correto': acertou,
        'dica': dicaGerada,
      },
    );

    return Response.json(body: {
      'correto': acertou,
      'mensagem': acertou ? 'Parabéns! Você pronunciou corretamente.' : 'Vamos tentar de novo!',
      if (dicaGerada != null) 'dica': dicaGerada,
    });
  } catch (e, stack) {
    print('❌ ERRO AO AVALIAR PRONÚNCIA: $e');
    print(stack);
    return Response.json(statusCode: 500, body: {'error': e.toString()});
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

import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:http/http.dart' as http;

Future<Response> onRequest(RequestContext context) async {
  try {
    final body = await context.request.body();
    final data = jsonDecode(body);

    final fraseOriginal = data['frase'];
    final fraseFalada = data['fala_usuario'];

    if (fraseOriginal == null || fraseFalada == null) {
      return Response.json(statusCode: 400, body: {
        'error': 'Campos obrigatórios: frase, fala_usuario'
      });
    }

    final prompt = '''
Você é um fonoaudiólogo virtual. O usuário tentou falar a frase:

"$fraseOriginal"

Mas falou:

"$fraseFalada"

Avalie a fluência e articulação. Liste as palavras incorretas (se houver) e dê dicas práticas de como melhorar a pronúncia. Seja breve, direto e gentil.
''';

    final response = await http.post(
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

    final json = jsonDecode(response.body);
    final avaliacao = json['candidates']?[0]?['content']?['parts']?[0]?['text'];

    return Response.json(body: {
      'avaliacao': avaliacao ?? 'Não foi possível avaliar a fala.'
    });
  } catch (e) {
    return Response.json(statusCode: 500, body: {'error': e.toString()});
  }
}

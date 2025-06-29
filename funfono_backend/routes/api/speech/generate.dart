import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:http/http.dart' as http;

Future<Response> onRequest(RequestContext context) async {
  try {
    final prompt = '''
Crie uma frase curta para praticar articulação e fluência. Pode ser um trava-língua ou frase do cotidiana. Ex: "O rato roeu a roupa do rei de Roma".
Responda apenas com a frase.
''';

    final response = await http.post(
      Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=AIzaSyClP7PDzQR6AYg1hH7RZoNiZ-reoiQrNrs'),
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

    final data = jsonDecode(response.body);
    final frase = data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? 'Fale algo divertido!';

    return Response.json(body: {'frase': frase.trim()});
  } catch (e) {
    return Response.json(statusCode: 500, body: {'error': e.toString()});
  }
}

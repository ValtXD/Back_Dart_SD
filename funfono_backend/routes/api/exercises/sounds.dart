import 'package:dart_frog/dart_frog.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: 405); // method not allowed
  }

  try {
    final body = await context.request.json();

    final userPreferences = body['preferences'] ?? [];
    final pronunciationTargets = body['targets'] ?? [];

    final prompt = '''
Considere as preferências: ${userPreferences.join(', ')}.
E os sons: ${pronunciationTargets.join(', ')}.

Gere uma lista com até 10 palavras em formato JSON puro.

Siga EXATAMENTE esse modelo:
{
  "palavras": [
    {"palavra": "chácara", "som": "ch"},
    {"palavra": "folha", "som": "lh"}
  ]
}
Apenas responda o JSON. Nada antes ou depois.
''';

    final geminiResponse = await http.post(
      Uri.parse("https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=AIzaSyClP7PDzQR6AYg1hH7RZoNiZ-reoiQrNrs"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "contents": [
          {
            "parts": [{"text": prompt}]
          }
        ]
      }),
    );

    final decoded = jsonDecode(geminiResponse.body);
    final textContent = decoded['candidates']?[0]?['content']?['parts']?[0]?['text'];

    if (textContent == null) {
      return Response.json(statusCode: 500, body: {
        "error": "Sem conteúdo retornado pela Gemini."
      });
    }

    // Tenta encontrar o início do JSON puro
    final jsonStart = textContent.indexOf('{');
    final jsonEnd = textContent.lastIndexOf('}');
    if (jsonStart == -1 || jsonEnd == -1) {
      return Response.json(statusCode: 500, body: {
        "error": "Resposta da IA não contém JSON válido.",
        "raw": textContent,
      });
    }

    final cleanJson = textContent.substring(jsonStart, jsonEnd + 1);
    final parsed = jsonDecode(cleanJson);

    return Response.json(body: parsed);
  } catch (e, stack) {
    print('❌ ERRO AO CONSULTAR GEMINI: $e');
    print(stack);
    return Response.json(statusCode: 500, body: {'error': e.toString()});
  }
}

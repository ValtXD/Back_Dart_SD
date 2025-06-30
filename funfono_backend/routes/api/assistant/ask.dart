// routes/api/assistant/ask.dart

import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:http/http.dart' as http;
import 'package:dotenv/dotenv.dart' show env, load;

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: 405); // Method Not Allowed
  }

  load();
  final geminiApiKey = env['GEMINI_API_KEY'] ?? ''; // GEMINI_API_KEY está no .env

  if (geminiApiKey.isEmpty) {
    print('❌ ERRO: GEMINI_API_KEY não configurada no .env');
    return Response.json(
      statusCode: 500,
      body: {'error': 'Chave da API Gemini não configurada.'},
    );
  }

  try {
    final body = await context.request.json();
    final String userQuestion = body['question'] as String;

    final prompt = '''
Você é um assistente virtual especializado em fonoaudiologia e no aplicativo FunFono.
Seu objetivo é fornecer informações, dicas, curiosidades, opiniões e ajudar a tirar dúvidas SOMENTE sobre fonoaudiologia, saúde vocal, desenvolvimento da fala, tratamento fonoaudiológico, curiosidades da área e informações/funcionalidades do aplicativo FunFono.
Você NÃO deve responder a perguntas sobre outros assuntos (política, esportes, culinária, etc.) ou assuntos que não sejam diretamente relacionados à fonoaudiologia ou ao aplicativo FunFono.
Se a pergunta não for relevante, responda gentilmente que seu foco é apenas em fonoaudiologia e no aplicativo FunFono.

Pergunta do usuário: "$userQuestion"
''';

    final geminiResponse = await http.post(
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

    if (geminiResponse.statusCode == 200) {
      final geminiData = jsonDecode(geminiResponse.body);
      final botText = geminiData['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? 'Desculpe, não consegui processar sua pergunta.';
      
      // Opcional: Lógica extra para filtrar respostas se o prompt do Gemini não for 100% eficaz
      // Embora o prompt já instrua o Gemini a não responder, esta é uma camada de segurança.
      // Você pode refinar palavras-chave ou usar outro modelo para classificação.
      final lowerCaseQuestion = userQuestion.toLowerCase();
      final relevantKeywords = [
        'fonoaudiologia', 'fala', 'voz', 'linguagem', 'pronúncia', 'terapia',
        'audição', 'saúde vocal', 'dicção', 'funfono', 'aplicativo', 'exercício',
        'curiosidade', 'dica', 'opinião', 'ajuda', 'dúvida', 'tratamento',
        'fono', 'dislalia', 'gagueira', 'apraxia', 'disfagia', 'comunicação'
      ];
      
      bool isRelevant = false;
      for (var keyword in relevantKeywords) {
        if (lowerCaseQuestion.contains(keyword)) {
          isRelevant = true;
          break;
        }
      }

      if (!isRelevant && !botText.toLowerCase().contains('fonoaudiologia')) { // Se a pergunta não tem keyword e a resposta do bot não menciona fono
        return Response.json(body: {'response': 'Desculpe, meu foco é apenas em fonoaudiologia e no aplicativo FunFono. Posso ajudar com algo relacionado a esses temas?'});
      }


      return Response.json(body: {'response': botText});
    } else {
      print('❌ Erro na chamada ao Gemini para o bot: ${geminiResponse.statusCode} - ${geminiResponse.body}');
      return Response.json(
        statusCode: 500,
        body: {'error': 'Erro ao consultar a IA para o assistente.'},
      );
    }
  } catch (e, stack) {
    print('❌ ERRO NO ASSISTENTE BOT (catch externo): $e');
    print(stack);
    return Response.json(statusCode: 500, body: {'error': e.toString()});
  }
}
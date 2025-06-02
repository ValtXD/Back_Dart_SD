import 'package:dart_frog/dart_frog.dart';
import 'package:funfono_backend/models/questionnaire.dart';
import 'package:funfono_backend/repositories/questionnaire_repository.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: 405);
  }

  try {
    // Lê o JSON da requisição
    final body = await context.request.json();

    // Converte para o modelo Questionnaire
    final questionnaire = Questionnaire.fromJson(body);

    // Chama a função que gera o perfil simulado (mock)
    final result = await analyzeWithGemini(questionnaire);

    // Retorna a resposta em JSON
    return Response.json(body: result);
  } catch (e, stackTrace) {
    print('❌ ERRO NA ROTA /analyze: $e');
    print(stackTrace);
    return Response.json(
      statusCode: 500,
      body: {
        'error': 'Erro ao processar análise',
        'details': e.toString(),
      },
    );
  }
}

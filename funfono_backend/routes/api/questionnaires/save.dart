import 'package:dart_frog/dart_frog.dart';
import 'package:funfono_backend/models/questionnaire.dart';
import 'package:funfono_backend/repositories/questionnaire_repository.dart';
import 'package:funfono_backend/services/database_service.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: 405);
  }

  try {
    final body = await context.request.json();
    final questionnaire = Questionnaire.fromJson(body);
    final dbService = context.read<DatabaseService>();

    await saveQuestionnaire(questionnaire, dbService);

    return Response.json(body: {'message': 'Questionário salvo com sucesso ✅'});
  } catch (e, stack) {
    print('❌ ERRO NA ROTA /save: $e');
    print(stack);
    return Response.json(statusCode: 500, body: {'error': e.toString()});
  }
}

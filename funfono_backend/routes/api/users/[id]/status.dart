import 'package:dart_frog/dart_frog.dart';
import 'package:funfono_backend/services/database_service.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  try {
    final dbService = context.read<DatabaseService>();
    final conn = dbService.connection;

    final result = await conn.query(
      'SELECT EXISTS(SELECT 1 FROM questionnaires WHERE user_id = @id)',
      substitutionValues: {'id': id},
    );

    final hasQuestionnaire = result.first[0] as bool;

    return Response.json(body: {
      'user_id': id,
      'has_questionnaire': hasQuestionnaire,
    });
  } catch (e, stack) {
    print('❌ ERRO AO OBTER STATUS DO USUÁRIO: $e');
    print(stack);
    return Response.json(
      statusCode: 500,
      body: {'error': e.toString()},
    );
  }
}

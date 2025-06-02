import 'package:dart_frog/dart_frog.dart';
import 'package:funfono_backend/services/database_service.dart';

Future<Response> onRequest(RequestContext context) async {
  final db = context.read<DatabaseService>().connection;

  try {
    final body = await context.request.json();

    final userId = body['user_id'] as String;
    final palavra = body['palavra'] as String;
    final som = body['som'] as String;
    final correto = body['correto'] as bool;

    await db.query('''
      INSERT INTO pronunciation_attempts (user_id, palavra, som, correto)
      VALUES (@userId, @palavra, @som, @correto)
    ''', substitutionValues: {
      'userId': userId,
      'palavra': palavra,
      'som': som,
      'correto': correto,
    });

    return Response.json(body: {'message': 'Tentativa registrada com sucesso!'});
  } catch (e) {
    print('❌ ERRO AO REGISTRAR TENTATIVA: $e');
    return Response.json(statusCode: 500, body: {'error': 'Erro ao registrar tentativa'});
  }
}

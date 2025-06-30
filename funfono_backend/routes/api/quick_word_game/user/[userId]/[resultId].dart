// routes/api/exercises/quick_word_game/[userId]/[resultId].dart

import 'package:dart_frog/dart_frog.dart';
import 'package:funfono_backend/services/database_service.dart';
import 'package:postgres/postgres.dart';

Future<Response> onRequest(RequestContext context, String userId, String resultId) async {
  if (context.request.method != HttpMethod.delete) {
    return Response(statusCode: 405); // Method Not Allowed
  }

  final db = context.read<DatabaseService>().connection;
  final int? id = int.tryParse(resultId);

  if (id == null) {
    return Response.json(statusCode: 400, body: {'error': 'ID do resultado inválido.'});
  }

  try {
    final result = await db.execute(
      '''
      DELETE FROM quick_word_game_results
      WHERE id = @id AND user_id = @userId;
      ''',
      substitutionValues: {
        'id': id,
        'userId': userId,
      },
    );

    if (result > 0) {
      return Response.json(body: {'message': 'Resultado do jogo excluído com sucesso!'});
    } else {
      return Response.json(statusCode: 404, body: {'error': 'Resultado do jogo não encontrado ou não pertence a este usuário.'});
    }
  } on PostgreSQLException catch (e) {
    print('Erro no PostgreSQL ao excluir resultado do jogo: $e');
    return Response.json(statusCode: 500, body: {'error': 'Erro no banco de dados: ${e.message}'});
  } catch (e, stack) {
    print('❌ ERRO AO EXCLUIR RESULTADO DO JOGO: $e');
    print(stack);
    return Response.json(statusCode: 500, body: {'error': e.toString()});
  }
}
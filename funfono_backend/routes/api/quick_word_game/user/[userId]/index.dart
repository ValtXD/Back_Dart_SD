// routes/api/exercises/quick_word_game/[userId].dart

import 'package:dart_frog/dart_frog.dart';
import 'package:funfono_backend/models/game_result.dart';
import 'package:funfono_backend/services/database_service.dart';
import 'package:postgres/postgres.dart';

Future<Response> onRequest(RequestContext context, String userId) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: 405); // Method Not Allowed
  }

  final db = context.read<DatabaseService>().connection;

  try {
    final PostgreSQLResult results = await db.query(
      '''
      SELECT id, user_id, score, correct_words, incorrect_words, created_at
      FROM quick_word_game_results
      WHERE user_id = @userId
      ORDER BY created_at DESC;
      ''',
      substitutionValues: {'userId': userId},
    );

    final List<GameResult> gameResults = results.map((row) {
      return GameResult(
        id: row[0] as int,
        userId: row[1].toString(),
        score: row[2] as int,
        correctWords: (row[3] as List).cast<String>(), // Casting para List<String>
        incorrectWords: (row[4] as List).cast<String>(), // Casting para List<String>
        createdAt: row[5] as DateTime,
      );
    }).toList();

    return Response.json(body: {'gameResults': gameResults.map((r) => r.toJson()).toList()});
  } on PostgreSQLException catch (e) {
    print('Erro no PostgreSQL ao listar resultados do jogo: $e');
    return Response.json(statusCode: 500, body: {'error': 'Erro no banco de dados: ${e.message}'});
  } catch (e, stack) {
    print('❌ ERRO AO LISTAR RESULTADOS DO JOGO: $e');
    print(stack);
    return Response.json(statusCode: 500, body: {'error': e.toString()});
  }
}
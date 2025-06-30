// routes/api/exercises/quick_word_game/save_result.dart

import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:funfono_backend/models/game_result.dart';
import 'package:funfono_backend/services/database_service.dart';
import 'package:postgres/postgres.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: 405); // Method Not Allowed
  }

  final db = context.read<DatabaseService>().connection;

  try {
    final body = await context.request.json();
    final gameResult = GameResult.fromJson(body as Map<String, dynamic>);

    // Validação básica
    if (gameResult.userId.isEmpty || gameResult.score < 0) {
      return Response.json(
        statusCode: 400,
        body: {'error': 'Campos user_id e score são obrigatórios e score deve ser não-negativo.'},
      );
    }

    final result = await db.query(
      '''
      INSERT INTO quick_word_game_results (user_id, score, correct_words, incorrect_words)
      VALUES (@userId, @score, @correctWords, @incorrectWords)
      RETURNING id, created_at;
      ''',
      substitutionValues: {
        'userId': gameResult.userId,
        'score': gameResult.score,
        'correctWords': gameResult.correctWords,
        'incorrectWords': gameResult.incorrectWords,
      },
    );

    if (result.isNotEmpty) {
      final insertedId = result.first[0] as int;
      final createdAt = result.first[1] as DateTime;
      final savedGameResult = GameResult(
        id: insertedId,
        userId: gameResult.userId,
        score: gameResult.score,
        correctWords: gameResult.correctWords,
        incorrectWords: gameResult.incorrectWords,
        createdAt: createdAt,
      );
      return Response.json(body: {'message': 'Resultado do jogo salvo com sucesso!', 'gameResult': savedGameResult.toJson()});
    } else {
      return Response.json(statusCode: 500, body: {'error': 'Falha ao salvar resultado do jogo no banco de dados.'});
    }
  } on PostgreSQLException catch (e) {
    print('Erro no PostgreSQL ao salvar resultado do jogo: $e');
    return Response.json(statusCode: 500, body: {'error': 'Erro no banco de dados: ${e.message}'});
  } catch (e, stack) {
    print('❌ ERRO AO SALVAR RESULTADO DO JOGO: $e');
    print(stack);
    return Response.json(statusCode: 500, body: {'error': e.toString()});
  }
}
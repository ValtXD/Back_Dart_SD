// funfono_backend/routes/api/daily_words/save_attempt/index.dart

import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:funfono_backend/models/daily_word_attempt.dart'; // Import do modelo
import 'package:funfono_backend/services/database_service.dart';
import 'package:postgres/postgres.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: 405); // Method Not Allowed
  }

  final db = context.read<DatabaseService>().connection;
  if (db == null) {
    return Response.json(statusCode: 500, body: {'error': 'Database service not available.'});
  }

  try {
    final body = await context.request.json();
    final dailyAttempt = DailyWordAttempt.fromJson(body as Map<String, dynamic>);

    final result = await db.query(
      '''
      INSERT INTO daily_word_attempts (user_id, word, user_transcription, is_correct, tip, created_at)
      VALUES (@userId, @word, @userTranscription, @isCorrect, @tip, NOW())
      RETURNING id, created_at;
      ''',
      substitutionValues: {
        'userId': dailyAttempt.userId,
        'word': dailyAttempt.word,
        'userTranscription': dailyAttempt.userTranscription,
        'isCorrect': dailyAttempt.isCorrect,
        'tip': dailyAttempt.tip,
      },
    );

    if (result.isNotEmpty) {
      final insertedId = result.first[0] as int;
      final createdAt = result.first[1] as DateTime;
      final savedAttempt = DailyWordAttempt(
        id: insertedId,
        userId: dailyAttempt.userId,
        word: dailyAttempt.word,
        userTranscription: dailyAttempt.userTranscription,
        isCorrect: dailyAttempt.isCorrect,
        tip: dailyAttempt.tip,
        createdAt: createdAt,
      );
      return Response.json(body: {'message': 'Daily word attempt saved successfully!', 'attempt': savedAttempt.toJson()});
    } else {
      return Response.json(statusCode: 500, body: {'error': 'Failed to save daily word attempt.'});
    }
  } on FormatException {
    return Response.json(statusCode: 400, body: {'error': 'Invalid JSON format.'});
  } on PostgreSQLException catch (e) {
    print('PostgreSQL Error saving daily word attempt: $e');
    return Response.json(statusCode: 500, body: {'error': 'Database error: ${e.message}'});
  } catch (e, stack) {
    print('Error saving daily word attempt: $e');
    print(stack);
    return Response.json(statusCode: 500, body: {'error': 'Internal server error.'});
  }
}
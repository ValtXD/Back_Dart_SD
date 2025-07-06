// funfono_backend/routes/api/daily_words/history/[userId]/index.dart

import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:funfono_backend/models/daily_word_attempt.dart'; // Import do modelo
import 'package:funfono_backend/services/database_service.dart';
import 'package:postgres/postgres.dart';

Future<Response> onRequest(RequestContext context, String userId) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: 405); // Method Not Allowed
  }

  final db = context.read<DatabaseService>().connection;
  if (db == null) {
    return Response.json(statusCode: 500, body: {'error': 'Database service not available.'});
  }

  try {
    final PostgreSQLResult results = await db.query(
      '''
      SELECT id, user_id, word, user_transcription, is_correct, tip, created_at
      FROM daily_word_attempts
      WHERE user_id = @userId
      ORDER BY created_at DESC;
      ''',
      substitutionValues: {'userId': userId},
    );

    final List<DailyWordAttempt> history = results.map((row) {
      return DailyWordAttempt(
        id: row[0] as int,
        userId: row[1].toString(),
        word: row[2].toString(),
        userTranscription: row[3].toString(),
        isCorrect: row[4] as bool,
        tip: row[5].toString(),
        createdAt: row[6] as DateTime,
      );
    }).toList();

    return Response.json(body: {'history': history.map((a) => a.toJson()).toList()});
  } on PostgreSQLException catch (e) {
    print('PostgreSQL Error getting daily word history: $e');
    return Response.json(statusCode: 500, body: {'error': 'Database error: ${e.message}'});
  } catch (e, stack) {
    print('Error getting daily word history: $e');
    print(stack);
    return Response.json(statusCode: 500, body: {'error': 'Internal server error.'});
  }
}
// routes/api/reminders/index.dart

import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:funfono_backend/models/reminder.dart';
import 'package:funfono_backend/services/database_service.dart';
import 'package:postgres/postgres.dart';

Future<Response> onRequest(RequestContext context) async {
  final db = context.read<DatabaseService>().connection;

  if (context.request.method == HttpMethod.post) {
    try {
      final body = await context.request.json();
      final reminder = Reminder.fromJson(body as Map<String, dynamic>);

      // Validação básica
      if (reminder.userId.isEmpty || reminder.title.isEmpty || reminder.time.isEmpty) {
        return Response.json(
          statusCode: 400,
          body: {'error': 'Campos user_id, title e time são obrigatórios.'},
        );
      }
      if (reminder.dayOfWeek < 1 || reminder.dayOfWeek > 7) {
        return Response.json(
          statusCode: 400,
          body: {'error': 'day_of_week deve ser um número entre 1 (Segunda) e 7 (Domingo).'},
        );
      }

      final result = await db.query(
        '''
        INSERT INTO reminders (user_id, title, day_of_week, time)
        VALUES (@userId, @title, @dayOfWeek, @time)
        RETURNING id, created_at; -- Retorna o ID gerado e a data de criação
        ''',
        substitutionValues: {
          'userId': reminder.userId,
          'title': reminder.title,
          'dayOfWeek': reminder.dayOfWeek,
          'time': reminder.time,
        },
      );

      if (result.isNotEmpty) {
        final insertedId = result.first[0] as int;
        final createdAt = result.first[1] as DateTime;
        final savedReminder = Reminder(
          id: insertedId,
          userId: reminder.userId,
          title: reminder.title,
          dayOfWeek: reminder.dayOfWeek,
          time: reminder.time,
          createdAt: createdAt,
        );
        return Response.json(body: {'message': 'Lembrete salvo com sucesso!', 'reminder': savedReminder.toJson()});
      } else {
        return Response.json(statusCode: 500, body: {'error': 'Falha ao salvar lembrete no banco de dados.'});
      }
    } on PostgreSQLException catch (e) {
      print('Erro no PostgreSQL ao criar lembrete: $e');
      return Response.json(statusCode: 500, body: {'error': 'Erro no banco de dados: ${e.message}'});
    } catch (e, stack) {
      print('❌ ERRO AO CRIAR LEMBRETE: $e');
      print(stack);
      return Response.json(statusCode: 500, body: {'error': e.toString()});
    }
  } else if (context.request.method == HttpMethod.get) {
    // Implementar busca de lembretes se GET for para todos os lembretes ou para um ID específico
    // Por enquanto, esta rota GET não está detalhada aqui, mas será coberta em /api/reminders/:userId
    return Response(statusCode: 405); // Método não permitido para GET aqui, use /api/reminders/:userId
  }
  return Response(statusCode: 405);
}
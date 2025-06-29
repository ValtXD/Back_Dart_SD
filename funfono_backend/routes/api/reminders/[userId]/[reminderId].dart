// routes/api/reminders/[userId]/[reminderId].dart

import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:funfono_backend/models/reminder.dart';
import 'package:funfono_backend/services/database_service.dart';
import 'package:postgres/postgres.dart';

Future<Response> onRequest(RequestContext context, String userId, String reminderId) async {
  final db = context.read<DatabaseService>().connection;
  final int? id = int.tryParse(reminderId);

  if (id == null) {
    return Response.json(statusCode: 400, body: {'error': 'ID do lembrete inválido.'});
  }

  if (context.request.method == HttpMethod.put) {
    try {
      final body = await context.request.json();
      final updatedReminder = Reminder.fromJson(body as Map<String, dynamic>);

      // Validação básica
      if (updatedReminder.title.isEmpty || updatedReminder.time.isEmpty) {
        return Response.json(
          statusCode: 400,
          body: {'error': 'Campos title e time são obrigatórios.'},
        );
      }
      if (updatedReminder.dayOfWeek < 1 || updatedReminder.dayOfWeek > 7) {
        return Response.json(
          statusCode: 400,
          body: {'error': 'day_of_week deve ser um número entre 1 (Segunda) e 7 (Domingo).'},
        );
      }

      final result = await db.execute(
        '''
        UPDATE reminders
        SET title = @title, day_of_week = @dayOfWeek, time = @time
        WHERE id = @id AND user_id = @userId;
        ''',
        substitutionValues: {
          'id': id,
          'userId': userId,
          'title': updatedReminder.title,
          'dayOfWeek': updatedReminder.dayOfWeek,
          'time': updatedReminder.time,
        },
      );

      if (result > 0) {
        return Response.json(body: {'message': 'Lembrete atualizado com sucesso!'});
      } else {
        return Response.json(statusCode: 404, body: {'error': 'Lembrete não encontrado ou não pertence a este usuário.'});
      }
    } on PostgreSQLException catch (e) {
      print('Erro no PostgreSQL ao atualizar lembrete: $e');
      return Response.json(statusCode: 500, body: {'error': 'Erro no banco de dados: ${e.message}'});
    } catch (e, stack) {
      print('❌ ERRO AO ATUALIZAR LEMBRETE: $e');
      print(stack);
      return Response.json(statusCode: 500, body: {'error': e.toString()});
    }
  } else if (context.request.method == HttpMethod.delete) {
    try {
      final result = await db.execute(
        '''
        DELETE FROM reminders
        WHERE id = @id AND user_id = @userId;
        ''',
        substitutionValues: {
          'id': id,
          'userId': userId,
        },
      );

      if (result > 0) {
        return Response.json(body: {'message': 'Lembrete excluído com sucesso!'});
      } else {
        return Response.json(statusCode: 404, body: {'error': 'Lembrete não encontrado ou não pertence a este usuário.'});
      }
    } on PostgreSQLException catch (e) {
      print('Erro no PostgreSQL ao excluir lembrete: $e');
      return Response.json(statusCode: 500, body: {'error': 'Erro no banco de dados: ${e.message}'});
    } catch (e, stack) {
      print('❌ ERRO AO EXCLUIR LEMBRETE: $e');
      print(stack);
      return Response.json(statusCode: 500, body: {'error': e.toString()});
    }
  }
  return Response(statusCode: 405); // Método não permitido
}
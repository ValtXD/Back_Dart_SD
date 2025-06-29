// routes/api/reminders/[userId].dart

import 'package:dart_frog/dart_frog.dart';
import 'package:funfono_backend/models/reminder.dart';
import 'package:funfono_backend/services/database_service.dart';
import 'package:postgres/postgres.dart'; // Importado para PostgreSQLResult

Future<Response> onRequest(RequestContext context, String userId) async {
  final db = context.read<DatabaseService>().connection;

  if (context.request.method == HttpMethod.get) {
    try {
      final PostgreSQLResult results = await db.query(
        '''
        SELECT id, user_id, title, day_of_week, time, created_at
        FROM reminders
        WHERE user_id = @userId
        ORDER BY day_of_week ASC, time ASC;
        ''',
        substitutionValues: {'userId': userId},
      );

      final List<Reminder> reminders = results.map((row) {
        return Reminder(
          id: row[0] as int,
          userId: row[1].toString(),
          title: row[2] as String,
          dayOfWeek: row[3] as int,
          time: row[4] as String,
          createdAt: row[5] as DateTime,
        );
      }).toList();

      return Response.json(body: {'reminders': reminders.map((r) => r.toJson()).toList()});
    } on PostgreSQLException catch (e) {
      print('Erro no PostgreSQL ao listar lembretes: $e');
      return Response.json(statusCode: 500, body: {'error': 'Erro no banco de dados: ${e.message}'});
    } catch (e, stack) {
      print('❌ ERRO AO LISTAR LEMBRETE: $e');
      print(stack);
      return Response.json(statusCode: 500, body: {'error': e.toString()});
    }
  } else if (context.request.method == HttpMethod.put || context.request.method == HttpMethod.delete) {
    // Essas operações (PUT/DELETE) serão tratadas em uma rota com :reminderId
    return Response(statusCode: 405); // Método não permitido para PUT/DELETE aqui
  }
  return Response(statusCode: 405);
}
// routes/api/users/[id]/delete_account/index.dart

import 'package:dart_frog/dart_frog.dart';
import 'package:funfono_backend/services/database_service.dart';
import 'package:postgres/postgres.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.delete) {
    return Response(statusCode: 405); // Method Not Allowed
  }

  final db = context.read<DatabaseService>().connection;
  if (db == null) {
    return Response.json(statusCode: 500, body: {'error': 'Database service not available.'});
  }

  try {
    // ATENÇÃO: Em um aplicativo real, você deve:
    // 1. Validar a autenticação do usuário (ex: verificar token JWT).
    // 2. Opcionalmente, pedir a senha novamente para confirmar a exclusão.
    // 3. Implementar transações para garantir que todos os dados sejam excluídos atomicamente.

    // Exclusão de dados em tabelas relacionadas (ORDEM IMPORTA devido a chaves estrangeiras)
    // ADAPTADO: Usando 'pronunciation_attempts' como a tabela de tentativas de exercício
    await db.execute('DELETE FROM pronunciation_attempts WHERE user_id = @userId;', substitutionValues: {'userId': id});
    await db.execute('DELETE FROM speech_attempts WHERE user_id = @userId;', substitutionValues: {'userId': id}); // Se esta tabela existir
    await db.execute('DELETE FROM quick_word_game_results WHERE user_id = @userId;', substitutionValues: {'userId': id});
    await db.execute('DELETE FROM reminders WHERE user_id = @userId;', substitutionValues: {'userId': id});
    await db.execute('DELETE FROM questionnaires WHERE user_id = @userId;', substitutionValues: {'userId': id});
    // Adicione aqui DELETEs para quaisquer outras tabelas que referenciem o user_id

    // Por último, exclui o próprio usuário da tabela 'users'
    final result = await db.execute('DELETE FROM users WHERE id = @userId;', substitutionValues: {'userId': id});

    if (result > 0) {
      return Response.json(body: {'message': 'Conta do usuário excluída com sucesso!'});
    } else {
      return Response.json(statusCode: 404, body: {'error': 'Usuário não encontrado ou não foi possível excluí-lo.'});
    }
  } on PostgreSQLException catch (e) {
    print('PostgreSQL Error deleting user account: $e');
    // Para depuração, você pode verificar e logar qual tabela específica causou o erro.
    // No entanto, como você não quer mudar o BD, vamos apenas reportar o erro.
    return Response.json(statusCode: 500, body: {'error': 'Erro no banco de dados durante a exclusão: ${e.message}'});
  } catch (e) {
    print('Error deleting user account: $e');
    return Response.json(statusCode: 500, body: {'error': 'Internal server error.'});
  }
}
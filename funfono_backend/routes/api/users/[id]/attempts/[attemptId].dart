// routes/api/users/[id]/attempts/[attemptId].dart

import 'package:dart_frog/dart_frog.dart';
import 'package:funfono_backend/services/database_service.dart';
import 'package:uuid/uuid.dart'; // Mantido caso haja necessidade futura de parsear UUIDs de outro lugar
import 'package:postgres/postgres.dart'; // Importado para PostgreSQLResult

Future<Response> onRequest(RequestContext context, String userId, String attemptId) async {
  final dbService = context.read<DatabaseService>();
  final conn = dbService.connection;

  if (context.request.method == HttpMethod.delete) {
    try {
      final body = await context.request.json();
      final String type = body['type'] as String;

      int? id = int.tryParse(attemptId);
      if (id == null) {
        return Response.json(
          statusCode: 400,
          body: {'error': 'ID da tentativa inválido.'},
        );
      }

      int rowsAffected = 0;
      if (type == 'som') {
        rowsAffected = await conn.execute( // CORREÇÃO: Usando execute() para retornar int
          '''
          DELETE FROM pronunciation_attempts
          WHERE id = @id AND user_id = @userId;
          ''',
          substitutionValues: {
            'id': id,
            'userId': userId, // CORREÇÃO: Usando userId diretamente
          },
        );
      } else if (type == 'frase') {
        rowsAffected = await conn.execute( // CORREÇÃO: Usando execute() para retornar int
          '''
          DELETE FROM speech_attempts
          WHERE id = @id AND user_id = @userId;
          ''',
          substitutionValues: {
            'id': id,
            'userId': userId, // CORREÇÃO: Usando userId diretamente
          },
        );
      } else {
        return Response.json(
          statusCode: 400,
          body: {'error': 'Tipo de tentativa inválido. Use "som" ou "frase".'},
        );
      }

      if (rowsAffected > 0) {
        return Response.json(body: {'message': 'Tentativa excluída com sucesso!'});
      } else {
        return Response.json(
          statusCode: 404,
          body: {'error': 'Tentativa não encontrada ou não pertence a este usuário.'},
        );
      }
    } catch (e, stack) {
      print('❌ ERRO AO EXCLUIR TENTATIVA: $e');
      print(stack);
      return Response.json(
        statusCode: 500,
        body: {'error': 'Erro interno ao excluir tentativa.'},
      );
    }
  } else {
    return Response(statusCode: 405); // Método não permitido
  }
}
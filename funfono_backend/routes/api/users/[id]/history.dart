// routes/api/users/[id]/history.dart

import 'package:dart_frog/dart_frog.dart';
import 'package:funfono_backend/services/database_service.dart';
import 'package:uuid/uuid.dart'; // Mantido caso haja necessidade futura de parsear UUIDs de outro lugar
import 'package:postgres/postgres.dart'; // Importado para PostgreSQLResult

Future<Response> onRequest(RequestContext context, String userId) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: 405); // Method Not Allowed
  }

  final dbService = context.read<DatabaseService>();
  final conn = dbService.connection;

  try {
    // Obter histórico de pronunciation_attempts (exercícios de sons)
    final PostgreSQLResult pronunciationResults = await conn.query(
      '''
      SELECT id, user_id, palavra, correto, fala_usuario, dica, created_at
      FROM pronunciation_attempts
      WHERE user_id = @userId
      ORDER BY created_at DESC;
      ''',
      substitutionValues: {'userId': userId}, // CORREÇÃO: Usando userId diretamente
    );

    final List<Map<String, dynamic>> pronunciationHistory = pronunciationResults.map((row) {
      return {
        'id': row[0] as int,
        'user_id': row[1].toString(), // Convert UUID to String
        'original': row[2] as String, // palavra
        'correct': row[3] as bool,
        'transcribed': row[4] as String?, // fala_usuario (transcrição do AssemblyAI)
        'feedback': row[5] as String?, // dica (feedback do Gemini)
        'created_at': (row[6] as DateTime).toIso8601String(),
        'type': 'som',
      };
    }).toList();

    // Obter histórico de speech_attempts (exercícios de fala)
    final PostgreSQLResult speechResults = await conn.query(
      '''
      SELECT id, user_id, frase, acertou, erros, dicas, transcricao_usuario, created_at -- ADICIONADO transcricao_usuario
      FROM speech_attempts
      WHERE user_id = @userId
      ORDER BY created_at DESC;
      ''',
      substitutionValues: {'userId': userId}, // CORREÇÃO: Usando userId diretamente
    );

    final List<Map<String, dynamic>> speechHistory = speechResults.map((row) {
      return {
        'id': row[0] as int,
        'user_id': row[1].toString(), // Convert UUID to String
        'original': row[2] as String, // frase
        'correct': row[3] as bool, // acertou
        'feedback': row[4] as String?, // erros (pode ser o feedback do Gemini)
        // Se 'dicas' for o campo principal do feedback do Gemini, ajuste para row[5]
        // ou se 'erros' é o feedback principal, mantenha como row[4]
        'transcribed': row[6] as String?, // NOVO: busca transcricao_usuario
        'created_at': (row[7] as DateTime).toIso8601String(), // Ajuste o índice se adicionar mais colunas antes
        'type': 'frase',
      };
    }).toList();
    
    // Combine os dois históricos e ordene novamente por data
    final List<Map<String, dynamic>> combinedHistory = [
      ...pronunciationHistory,
      ...speechHistory,
    ];

    combinedHistory.sort((a, b) {
      final DateTime dateA = DateTime.parse(a['created_at'] as String);
      final DateTime dateB = DateTime.parse(b['created_at'] as String);
      return dateB.compareTo(dateA); // Ordem decrescente (mais recente primeiro)
    });

    return Response.json(body: {'history': combinedHistory});
  } catch (e, stack) {
    print('❌ ERRO AO OBTER HISTÓRICO DO USUÁRIO: $e');
    print(stack);
    return Response.json(
      statusCode: 500,
      body: {'error': e.toString(), 'details': stack.toString()},
    );
  }
}
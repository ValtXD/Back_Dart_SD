import 'package:dart_frog/dart_frog.dart';
import 'package:funfono_backend/services/database_service.dart';

Future<Response> onRequest(RequestContext context) async {
  final dbService = context.read<DatabaseService>();
  final conn = dbService.connection;

  try {
    final results = await conn.query('SELECT * FROM questionnaires');

    final questionnaires = results.map((row) {
      final map = row.toColumnMap();
      // Convertendo o DateTime para String
      map['created_at'] = map['created_at'].toString();
      return map;
    }).toList();

    return Response.json(body: {'questionnaires': questionnaires});
  } catch (e, stack) {
    print('❌ ERRO AO BUSCAR QUESTIONÁRIOS: $e');
    print(stack);
    return Response.json(
      statusCode: 500,
      body: {'error': e.toString()},
    );
  }
}

import 'package:dart_frog/dart_frog.dart';
import 'package:funfono_backend/services/database_service.dart';

Handler middleware(Handler handler) {
  return (context) async {
    final dbService = DatabaseService();
    await dbService.initialize();

    final updatedContext = context.provide<DatabaseService>(() => dbService);
    final response = await handler(updatedContext);

    await dbService.close();
    return response;
  };
}

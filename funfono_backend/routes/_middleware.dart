import 'package:dart_frog/dart_frog.dart';
import 'package:funfono_backend/services/database_service.dart';

final _dbService = DatabaseService();

Handler middleware(Handler handler) {
  return (context) async {
    // Inicializa o banco de dados uma única vez
    if (!_dbService.isInitialized) {
      await _dbService.initialize();
    }

    // Injeta a instância no contexto
    return handler(context.provide<DatabaseService>(() => _dbService));
  };
}

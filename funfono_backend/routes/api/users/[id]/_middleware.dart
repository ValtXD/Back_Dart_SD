// routes/api/users/[id]/_middleware.dart
import 'package:dart_frog/dart_frog.dart';
import 'package:funfono_backend/services/database_service.dart';

final _dbService = DatabaseService(); // Ou use context.read se já estiver configurado globalmente

Handler middleware(Handler handler) {
  return (context) async {
    // Inicializa o banco de dados uma única vez por processo
    if (!_dbService.isInitialized) {
      await _dbService.initialize();
    }
    // Fornece a instância do DatabaseService ao contexto
    return handler(context.provide<DatabaseService>(() => _dbService));
  };
}
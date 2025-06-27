// funfono_backend/routes/api/auth/_middleware.dart

import 'package:dart_frog/dart_frog.dart';
import 'package:funfono_backend/services/database_service.dart'; // Importe a partir do pacote

// Crie a instância do serviço DESTA FORMA, para que seja uma única instância global
// que é injetada.
final DatabaseService _dbService = DatabaseService();

Handler middleware(Handler handler) {
  return (context) async {
    // Inicializa o banco de dados uma única vez, antes de qualquer requisição.
    // Isso garante que a conexão esteja pronta.
    if (!_dbService.isInitialized) {
      await _dbService.initialize();
    }

    // Injeta a mesma instância do DatabaseService no contexto da requisição.
    // O tipo genérico é crucial aqui.
    return handler(
      context.provide<DatabaseService>(() => _dbService),
    );
  };
}
// routes/api/auth/login.dart

import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:crypto/crypto.dart';
// Certifique-se de que a importação do User model seja do pacote:
import 'package:funfono_backend/models/user.dart'; // <-- Mantenha esta linha
// E que as outras importações de serviços/repositórios não tragam um "User" diferente:
import 'package:funfono_backend/services/database_service.dart'; // <-- Certifique-se desta importação
import '../../../lib/repositories/auth_repository.dart';


Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: 405); // Method Not Allowed
  }

  try {
    final body = await context.request.json() as Map<String, dynamic>;
    final fullName = body['fullName'] as String?;
    final password = body['password'] as String?;

    if (fullName == null || password == null) {
      return Response.json(
        statusCode: 400, // Bad Request
        body: {'error': 'Nome de usuário e senha são obrigatórios.'},
      );
    }

    final dbService = context.read<DatabaseService>();
    final authRepo = AuthRepository(dbService.connection);

    // Hash da senha recebida para comparação com o hash armazenado no banco
    final hashedPassword = sha256.convert(utf8.encode(password)).toString();

    // Buscar usuário por nome completo
    // Aqui, o 'User' deve ser reconhecido consistentemente
    final User? user = await authRepo.findUserByFullName(fullName); // Não altere esta linha

    if (user != null && user.passwordHash == hashedPassword) {
      // Autenticação bem-sucedida
      return Response.json(
        body: {
          'user': {
            'id': user.id,
            'fullName': user.fullName,
            'email': user.email,
            'phone': user.phone,
            'isInTherapy': user.isInTherapy,
          }
        },
      );
    } else {
      // Credenciais inválidas
      return Response.json(
        statusCode: 401, // Unauthorized
        body: {'error': 'Nome de usuário ou senha inválidos.'},
      );
    }
  } catch (e, stackTrace) {
    print('❌ ERRO NA ROTA /auth/login: $e');
    print(stackTrace);
    return Response.json(
      statusCode: 500, // Internal Server Error
      body: {'error': 'Erro interno no servidor: ${e.toString()}'},
    );
  }
}
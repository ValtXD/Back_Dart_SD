import 'package:dart_frog/dart_frog.dart';
import 'package:dotenv/dotenv.dart';
import '../../../lib/repositories/auth_repository.dart';
import 'package:funfono_backend/services/database_service.dart'; // <-- Certifique-se desta importação
import 'dart:io';

Future<Response> onRequest(RequestContext context) async {
  try {
    print('Iniciando processamento da requisição...'); // Log 1
    
    if (context.request.method != HttpMethod.post) {
      print('Método não permitido: ${context.request.method}'); // Log 2
      return Response(statusCode: HttpStatus.methodNotAllowed);
    }

    print('Inicializando serviços de banco de dados...'); // Log 3
    final dbService = DatabaseService();
    await dbService.initialize();
    final authRepo = AuthRepository(dbService.connection);

    print('Lendo corpo da requisição...'); // Log 4
    final body = await context.request.json() as Map<String, dynamic>;
    print('Corpo recebido: $body'); // Log 5
    
    // Validação dos campos
    final fullName = body['fullName'] as String?;
    final email = body['email'] as String?;
    final password = body['password'] as String?;
    final phone = body['phone'] as String?;
    final isInTherapy = body['isInTherapy'] as bool?;

    if (fullName == null || email == null || password == null) {
      print('Campos obrigatórios faltando'); // Log 6
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': 'Campos obrigatórios faltando'},
      );
    }

    print('Registrando novo usuário...'); // Log 7
    final user = await authRepo.registerUser(
      fullName: fullName,
      email: email,
      password: password,
      phone: phone,
      isInTherapy: isInTherapy,
    );

    if (user == null) {
      print('Email já cadastrado: $email'); // Log 8
      return Response.json(
        statusCode: HttpStatus.conflict,
        body: {'error': 'Email já cadastrado'},
      );
    }

    print('Usuário registrado com sucesso: ${user.email}'); // Log 9
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
  } catch (e, stackTrace) {
    print('ERRO CRÍTICO: $e'); // Log 10
    print('STACK TRACE: $stackTrace'); // Log 11
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Erro interno no servidor: ${e.toString()}'},
    );
  }
}
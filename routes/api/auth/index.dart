import 'package:dart_frog/dart_frog.dart';
import '../../../models/user_model.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response.json(
      statusCode: 405,
      body: {'error': 'Use POST para cadastro'},
    );
  }
  return _handleRegister(context);
}

Future<Response> _handleRegister(RequestContext context) async {
  try {
    final body = await context.request.json() as Map<String, dynamic>;

    // Validação dos campos obrigatórios
    final errors = <String>[];
    
    if (body['fullName']?.toString().isEmpty ?? true) {
      errors.add('Nome completo é obrigatório');
    }
    if (body['email']?.toString().isEmpty ?? true) {
      errors.add('E-mail é obrigatório');
    }
    if (body['phone']?.toString().isEmpty ?? true) {
      errors.add('Telefone é obrigatório');
    }
    if (body['password']?.toString().isEmpty ?? true) {
      errors.add('Senha é obrigatória');
    }
    if (body['isInTherapy'] == null) {
      errors.add('Informe se está em terapia');
    }

    if (errors.isNotEmpty) {
      return Response.json(
        statusCode: 400,
        body: {'errors': errors},
      );
    }

    // Criação do usuário
    final user = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      fullName: body['fullName']!.toString(),
      email: body['email']!.toString(),
      phone: body['phone']!.toString(),
      passwordHash: User.hashPassword(body['password']!.toString()),
      isInTherapy: body['isInTherapy'].toString().toLowerCase() == 'true',
      createdAt: DateTime.now(),
    );

    return Response.json(
      statusCode: 201,
      body: {
        'success': true,
        'user': user.toJson(),
        'message': 'Cadastro realizado com sucesso!',
      },
    );

  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {'error': 'Erro interno: ${e.toString()}'},
    );
  }
}
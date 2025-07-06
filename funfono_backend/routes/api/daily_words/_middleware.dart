// funfono_backend/routes/api/daily_words/_middleware.dart

import 'package:dart_frog/dart_frog.dart';

Handler middleware(Handler handler) {
  return (context) async {
    // Exemplo: logar cada requisição para as rotas /api/daily_words
    print('Middleware: Acessando rota de Palavras Diárias: ${context.request.uri.path}');

    // Adicione lógica de autenticação aqui, se necessário.
    // final String? authHeader = context.request.headers['authorization'];
    // if (authHeader == null || !authHeader.startsWith('Bearer ')) {
    //   return Response.json(statusCode: 401, body: {'error': 'Unauthorized'});
    // }

    // Continua para o próximo handler na cadeia
    final response = await handler(context);
    return response;
  };
}
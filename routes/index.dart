import 'package:dart_frog/dart_frog.dart';

Response onRequest(RequestContext context) {
  return Response.json(
    body: {
      'message': 'Bem-vindo à API do FunFono',
      'endpoints': {
        '/api/forms': 'Formulário de avaliação',
        '/api/auth': 'Autenticação de usuário',
      },
    },
  );
}
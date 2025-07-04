// routes/api/feedback/send_feedback/index.dart

import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:dotenv/dotenv.dart' show env, load;

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: 405); // Method Not Allowed
  }

  load(); // Carrega variáveis de ambiente
  final smtpHost = env['SMTP_HOST'] ?? '';
  final smtpPort = int.tryParse(env['SMTP_PORT'] ?? '') ?? 587;
  final smtpUsername = env['SMTP_USERNAME'] ?? '';
  final smtpPassword = env['SMTP_PASSWORD'] ?? '';

  // Verifica se as credenciais SMTP estão configuradas
  if (smtpHost.isEmpty || smtpUsername.isEmpty || smtpPassword.isEmpty) {
    print('❌ ERRO: Credenciais SMTP não configuradas no .env para envio de feedback.');
    return Response.json(
      statusCode: 500,
      body: {'error': 'Credenciais de envio de e-mail não configuradas no servidor.'},
    );
  }

  try {
    final body = await context.request.json();
    final String feedbackText = body['feedback_text'] as String;
    final int rating = body['rating'] as int;

    final SmtpServer smtpServer = SmtpServer(
      smtpHost,
      port: smtpPort,
      username: smtpUsername,
      password: smtpPassword,
      ssl: smtpPort == 465, // Usa SSL se a porta for 465, STARTTLS para 587
      // REMOVIDO: O parâmetro 'ignoreBadCertificates' não é definido nesta versão do mailer.
      // A validação de certificado é tratada de forma padrão e segura.
    );

    final Message message = Message()
      ..from = Address(smtpUsername, 'FunFono App Feedback')
      ..recipients.add('aamon.ling00@gmail.com') // E-MAIL DE DESTINO DO FEEDBACK
      ..subject = 'Novo Feedback do App FunFono - Avaliação: $rating estrelas'
      ..text = 'Avaliação: $rating estrelas\n\nFeedback:\n$feedbackText';

    try {
      final SendReport report = await send(message, smtpServer);
      print('✅ Feedback enviado com sucesso! ${report.toString()}');
      return Response.json(body: {'message': 'Feedback enviado com sucesso!'});
    } on MailerException catch (e) {
      print('❌ Erro ao enviar feedback por e-mail: ${e.message}');
      for (var p in e.problems) {
        print('Problema: ${p.code}: ${p.msg}');
      }
      return Response.json(statusCode: 500, body: {'error': 'Falha ao enviar feedback por e-mail.'});
    }
  } on FormatException {
    return Response.json(statusCode: 400, body: {'error': 'Corpo da requisição JSON inválido.'});
  } catch (e, stack) {
    print('❌ ERRO GERAL AO PROCESSAR FEEDBACK: $e');
    print(stack);
    return Response.json(statusCode: 500, body: {'error': e.toString()});
  }
}
// routes/api/quick_word_game/evaluate_pronunciation/index.dart

import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:http/http.dart' as http;
import 'package:dotenv/dotenv.dart' show env, load;

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: 405); // Method Not Allowed
  }

  load();
  final assemblyAIApiKey = env['ASSEMBLYAI_API_KEY'] ?? '';

  if (assemblyAIApiKey.isEmpty) {
    return Response.json(
      statusCode: 500,
      body: {'error': 'AssemblyAI API key not configured'},
    );
  }

  try {
    final body = await context.request.json();
    final String word = body['palavra'] as String;
    final String userSpeechBase64 = body['fala_usuario_audio_base64'] as String;

    // Remove o prefixo data URI se existir
    final pureBase64 = userSpeechBase64.replaceFirst(
      RegExp(r'data:audio/\w+;base64,'), 
      ''
    );

    // 1. Primeiro faz o upload do áudio
    final uploadResponse = await http.post(
      Uri.parse('https://api.assemblyai.com/v2/upload'),
      headers: {
        'authorization': assemblyAIApiKey,
        'Content-Type': 'application/octet-stream',
      },
      body: base64Decode(pureBase64),
    );

    if (uploadResponse.statusCode != 200) {
      return Response.json(
        statusCode: uploadResponse.statusCode,
        body: {'error': 'Failed to upload audio', 'details': uploadResponse.body},
      );
    }

    final uploadData = jsonDecode(uploadResponse.body);
    final audioUrl = uploadData['upload_url'] as String;

    // 2. Solicita a transcrição com word boost
    final transcriptResponse = await http.post(
      Uri.parse('https://api.assemblyai.com/v2/transcript'),
      headers: {
        'authorization': assemblyAIApiKey,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'audio_url': audioUrl,
        'language_code': 'pt',
        'word_boost': [word],
        'boost_param': 'high',
      }),
    );

    if (transcriptResponse.statusCode != 200 && transcriptResponse.statusCode != 201) {
      return Response.json(
        statusCode: transcriptResponse.statusCode,
        body: {'error': 'Failed to create transcript', 'details': transcriptResponse.body},
      );
    }

    final transcriptData = jsonDecode(transcriptResponse.body);
    final transcriptId = transcriptData['id'] as String;

    // 3. Polling para verificar o status da transcrição
    Map<String, dynamic>? transcriptResult;
    String status = '';
    int attempts = 0;
    const maxAttempts = 30; // ~30 segundos de timeout

    while (status != 'completed' && attempts < maxAttempts) {
      await Future.delayed(const Duration(seconds: 1));
      attempts++;

      final statusResponse = await http.get(
        Uri.parse('https://api.assemblyai.com/v2/transcript/$transcriptId'),
        headers: {'authorization': assemblyAIApiKey},
      );

      if (statusResponse.statusCode != 200) {
        break;
      }

      transcriptResult = jsonDecode(statusResponse.body);
      status = transcriptResult?['status']?.toString() ?? '';

      if (status == 'error' || status == 'failed') {
        break;
      }
    }

    if (status != 'completed' || transcriptResult == null) {
      return Response.json(
        statusCode: 500,
        body: {'error': 'Transcription failed', 'status': status},
      );
    }

    final transcription = transcriptResult['text'] as String? ?? '';
    final isCorrect = transcription.toLowerCase().contains(word.toLowerCase());
    
    return Response.json(
      body: {
        'correto': isCorrect,
        'mensagem': isCorrect
            ? 'Pronúncia correta!'
            : 'Pronúncia incorreta. Tente novamente.',
        'transcricao': transcription,
        'palavra_esperada': word,
      },
    );
  } on FormatException {
    return Response.json(
      statusCode: 400,
      body: {'error': 'Invalid request body format'},
    );
  } catch (e, stackTrace) {
    print('Error: $e\n$stackTrace');
    return Response.json(
      statusCode: 500,
      body: {'error': 'Internal server error'},
    );
  }
}
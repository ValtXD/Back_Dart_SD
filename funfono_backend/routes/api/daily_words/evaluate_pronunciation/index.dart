// funfono_backend/routes/api/daily_words/evaluate_pronunciation/index.dart

import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:http/http.dart' as http;
import 'package:dotenv/dotenv.dart' show env, load;
import 'dart:math'; // Para usar min() no print de debug

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: 405); // Method Not Allowed
  }

  load();
  final assemblyAIApiKey = env['ASSEMBLYAI_API_KEY'] ?? '';

  if (assemblyAIApiKey.isEmpty) {
    print('❌ ERRO: ASSEMBLYAI_API_KEY não configurada no .env para avaliação de pronúncia de palavras diárias.');
    return Response.json(
      statusCode: 500,
      body: {'error': 'Chave da API AssemblyAI não configurada para avaliação.'},
    );
  }

  try {
    final body = await context.request.json();
    final String word = body['word'] as String;
    final String userSpeechBase64 = body['user_speech_base64'] as String;

    print('DEBUG BACKEND (eval_pron): Word: $word');
    print('DEBUG BACKEND (eval_pron): Raw Base64 Length (vindo do Flutter): ${userSpeechBase64.length}');
    if (userSpeechBase64.isNotEmpty) {
      print('DEBUG BACKEND (eval_pron): Raw Base64 start: ${userSpeechBase64.substring(0, min(userSpeechBase64.length, 50))}...');
    } else {
      print('DEBUG BACKEND (eval_pron): Raw Base64 está vazio.');
    }

    // CORREÇÃO AQUI: Usando o RegExp EXATO da sua versão funcional (evaluate_minigame.txt)
    final pureBase64 = userSpeechBase64.replaceFirst(
      RegExp(r'data:audio/\w+;base64,'), // Este regex foi validado no seu outro código
      ''
    );

    print('DEBUG BACKEND (eval_pron): Pure Base64 Length after cleaning: ${pureBase64.length}');

    if (pureBase64.isEmpty) {
      print('❌ ERRO BACKEND (eval_pron): Base64 do áudio vazio após limpeza de prefixo.');
      return Response.json(statusCode: 400, body: {'error': 'Áudio Base64 vazio ou inválido após limpeza.'});
    }

    List<int> audioBytes;
    try {
      audioBytes = base64Decode(pureBase64);
      print('DEBUG BACKEND (eval_pron): Base64 decodificado para ${audioBytes.length} bytes.');
    } catch (e) {
      print('❌ ERRO BACKEND (eval_pron): Falha ao decodificar Base64: $e');
      return Response.json(statusCode: 400, body: {'error': 'Áudio Base64 inválido para decodificação.'});
    }

    // 1. Fazer o upload do áudio para o AssemblyAI
    final uploadResponse = await http.post(
      Uri.parse('https://api.assemblyai.com/v2/upload'),
      headers: {
        'Authorization': assemblyAIApiKey,
        'Content-Type': 'application/octet-stream',
      },
      body: audioBytes,
    );

    if (uploadResponse.statusCode != 200) {
      print('❌ ERRO BACKEND (eval_pron): Erro no upload do áudio para AssemblyAI: ${uploadResponse.statusCode} - ${uploadResponse.body}');
      return Response.json(
        statusCode: uploadResponse.statusCode,
        body: {'error': 'Falha ao fazer upload do áudio', 'details': uploadResponse.body},
      );
    }

    final uploadData = jsonDecode(uploadResponse.body);
    final audioUrl = uploadData['upload_url'] as String;
    print('DEBUG BACKEND (eval_pron): Áudio uploaded com sucesso. URL: $audioUrl');

    // 2. Solicitar a transcrição usando a URL do áudio
    final transcriptResponse = await http.post(
      Uri.parse('https://api.assemblyai.com/v2/transcript'),
      headers: {
        'Authorization': assemblyAIApiKey,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'audio_url': audioUrl,
        'language_code': 'pt',
      }),
    );

    if (transcriptResponse.statusCode != 200 && transcriptResponse.statusCode != 201) {
      print('❌ ERRO BACKEND (eval_pron): Erro ao criar transcrição no AssemblyAI: ${transcriptResponse.statusCode} - ${transcriptResponse.body}');
      return Response.json(
        statusCode: transcriptResponse.statusCode,
        body: {'error': 'Falha ao criar transcrição', 'details': transcriptResponse.body},
      );
    }

    final transcriptData = jsonDecode(transcriptResponse.body);
    final transcriptId = transcriptData['id'] as String;
    print('DEBUG BACKEND (eval_pron): Transcrição iniciada. ID: $transcriptId');

    // 3. Polling para verificar o status da transcrição
    Map<String, dynamic>? transcriptResult;
    String status = '';
    int attempts = 0;
    const maxAttempts = 30; // ~30 segundos de timeout para polling

    while (status != 'completed' && attempts < maxAttempts) {
      await Future.delayed(const Duration(seconds: 1));
      attempts++;

      final statusResponse = await http.get(
        Uri.parse('https://api.assemblyai.com/v2/transcript/$transcriptId'),
        headers: {'authorization': assemblyAIApiKey},
      );

      if (statusResponse.statusCode != 200) {
        print('❌ ERRO BACKEND (eval_pron): Erro no polling de status da transcrição: ${statusResponse.statusCode} - ${statusResponse.body}');
        break;
      }

      transcriptResult = jsonDecode(statusResponse.body);
      status = transcriptResult?['status']?.toString() ?? '';

      if (status == 'error' || status == 'failed') {
        print('❌ ERRO BACKEND (eval_pron): Transcrição falhou com status: $status. Detalhes: ${transcriptResult?['error']}');
        break;
      }
    }

    if (status != 'completed' || transcriptResult == null) {
      print('❌ ERRO BACKEND (eval_pron): Transcrição não completou no tempo esperado ou com erro. Status final: $status');
      return Response.json(
        statusCode: 500,
        body: {'error': 'Transcrição falhou ou não completou', 'status': status, 'details': transcriptResult?['error']},
      );
    }

    final transcription = transcriptResult['text'] as String? ?? '';
    final isCorrect = transcription.toLowerCase().contains(word.toLowerCase());
    
    print('DEBUG BACKEND (eval_pron): Resultado final: Palavra: $word, Transcrição: $transcription, Correto: $isCorrect');

    return Response.json(
      body: {
        'correto': isCorrect,
        'mensagem': isCorrect
            ? 'Pronúncia correta!'
            : 'Pronúncia incorreta. Tente novamente.',
        'transcricao_servico_externo': transcription,
      },
    );
  } on FormatException {
    print('❌ ERRO BACKEND (eval_pron): Corpo da requisição JSON inválido.');
    return Response.json(
      statusCode: 400,
      body: {'error': 'Corpo da requisição JSON inválido'},
    );
  } catch (e, stackTrace) {
    print('Error: $e\n$stackTrace');
    return Response.json(
      statusCode: 500,
      body: {'error': 'Erro interno no servidor: ${e.toString()}'},
    );
  }
}
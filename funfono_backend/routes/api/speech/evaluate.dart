// routes/api/speech/evaluate_speech.dart

import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:http/http.dart' as http;
import 'package:funfono_backend/services/database_service.dart';
import 'package:funfono_backend/api/assemblyai_service.dart';
import 'package:dotenv/dotenv.dart' show env, load;

Future<Response> onRequest(RequestContext context) async {
  load();
  final assemblyAiApiKey = env['ASSEMBLYAI_API_KEY'] ?? '';

  if (assemblyAiApiKey.isEmpty) {
    print('❌ ERRO: ASSEMBLYAI_API_KEY não configurada no .env');
    return Response.json(
      statusCode: 500,
      body: {'error': 'Chave da API AssemblyAI não configurada.'},
    );
  }

  final assemblyAIService = AssemblyAIService(assemblyAiApiKey);

  final db = context.read<DatabaseService>().connection;
  try {
    final body = await context.request.body();
    final data = jsonDecode(body);

    final userId = data['user_id']?.toString();
    final fraseOriginal = data['frase']?.toString();
    final falaUsuarioAudioBase64 = data['fala_usuario_audio_base64']?.toString();

    if (userId == null || fraseOriginal == null || falaUsuarioAudioBase64 == null) {
      return Response.json(
        statusCode: 400,
        body: {'error': 'Campos obrigatórios: user_id, frase, fala_usuario_audio_base64'},
      );
    }

    String? transcricaoAssemblyAI;
    try {
      print('Chamando AssemblyAI para transcrever áudio da frase "$fraseOriginal"...');
      transcricaoAssemblyAI = await assemblyAIService.transcribeAudio(falaUsuarioAudioBase64);
      print('Transcrição do AssemblyAI para frase "$fraseOriginal": "$transcricaoAssemblyAI"');
    } catch (e) {
      print('Exceção ao chamar serviço AssemblyAI: $e');
    }

    String? mensagemGemini;
    bool acertouPeloGemini = false;

    final prompt = '''
Você é um fonoaudiólogo virtual.
O usuário tentou falar a frase:
"$fraseOriginal"
Mas o que um sistema de transcrição de alta precisão detectou foi:
"${transcricaoAssemblyAI?.isEmpty ?? true ? 'Não foi possível transcrever com clareza suficiente. Tente falar mais perto do microfone.'
: transcricaoAssemblyAI}"

Por favor, analise a transcrição em relação à frase original.
Retorne um JSON com duas chaves:
1. "correto": um booleano (true ou false) indicando se a pronúncia foi considerada correta.
2. "feedback": uma string com uma mensagem. Se correto, uma mensagem de parabéns.
Se incorreto, uma dica de pronúncia curta e prática focando em articulação e fluência para a frase.
Exemplo de retorno JSON:
{"correto": true, "feedback": "Parabéns! Pronunciou a frase corretamente."}
ou
{"correto": false, "feedback": "Para melhorar, fale mais devagar e articule cada palavra."}
''';
    final response = await http.post(
      Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=AIzaSyClP7PDzQR6AYg1hH7RZoNiZ-reoiQrNrs'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      try {
        final geminiData = jsonDecode(response.body);
        final geminiText = geminiData['candidates']?[0]?['content']?['parts']?[0]?['text'];

        if (geminiText != null && geminiText.isNotEmpty) {
          final jsonStart = geminiText.indexOf('{');
          final jsonEnd = geminiText.lastIndexOf('}');
          if (jsonStart != -1 && jsonEnd != -1 && jsonStart < jsonEnd) {
            final cleanJson = geminiText.substring(jsonStart, jsonEnd + 1);
            final parsedGeminiFeedback = jsonDecode(cleanJson);
            
            acertouPeloGemini = parsedGeminiFeedback['correto'] ?? false;
            mensagemGemini = parsedGeminiFeedback['feedback'] ?? 'Não foi possível obter feedback detalhado.';
          } else {
            mensagemGemini = geminiText;
            acertouPeloGemini = false;
          }
        } else {
          mensagemGemini = 'Gemini não retornou feedback.';
        }
      } catch (e, stack) {
        print('❌ Erro ao decodificar JSON do Gemini ou extrair feedback: $e');
        print(stack);
        mensagemGemini = 'Erro interno ao processar feedback da IA.';
      }
    } else {
      print('❌ Erro na chamada ao Gemini: ${response.statusCode} - ${response.body}');
      mensagemGemini = 'Erro ao consultar a IA para feedback.';
    }

    // Salvar resultado da tentativa no banco
    await db.query('''
      INSERT INTO speech_attempts (
        user_id, frase, acertou, erros, dicas, transcricao_usuario 
      ) VALUES (
        @userId, @frase, @acertou, @erros, @dicas, @transcricaoUsuario 
      )
    ''', substitutionValues: {
      'userId': userId,
      'frase': fraseOriginal,
      'acertou': acertouPeloGemini,
      'erros': acertouPeloGemini ? null : mensagemGemini,
      'dicas': acertouPeloGemini ? null : mensagemGemini,
      'transcricaoUsuario': transcricaoAssemblyAI, // SALVANDO A TRANSCRIÇÃO
    });
    return Response.json(body: {
      'acertou': acertouPeloGemini,
      'avaliacao': mensagemGemini,
      'transcricao_assemblyai': transcricaoAssemblyAI,
    });
  } catch (e, stack) {
    print('❌ ERRO AO AVALIAR FALA (catch externo): $e');
    print(stack);
    return Response.json(
      statusCode: 500,
      body: {'error': 'Erro interno ao avaliar fala.'},
    );
  }
}

String normalize(String input) {
  final map = {
    'á': 'a', 'à': 'a', 'ã': 'a', 'â': 'a',
    'é': 'e', 'ê': 'e',
    'í': 'i', 'î': 'i',
    'ó': 'o', 'õ': 'o', 'ô': 'o',
    'ú': 'u', 'û': 'u',
    'ç': 'c',
  };
  return input
      .toLowerCase()
      .split('')
      .map((char) => map[char] ?? char)
      .join();
}
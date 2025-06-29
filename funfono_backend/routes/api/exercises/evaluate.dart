// routes/api/exercises/evaluate.dart

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
    final palavra = data['palavra']?.toString();
    final som = data['som']?.toString();
    final falaUsuarioAudioBase64 = data['fala_usuario_audio_base64']?.toString();


    if (userId == null || palavra == null || falaUsuarioAudioBase64 == null || som == null) {
      return Response.json(
        statusCode: 400,
        body: {'error': 'Campos obrigatórios: user_id, palavra, som, fala_usuario_audio_base64'},
      );
    }

    String? transcricaoAssemblyAI;
    try {
      print('Chamando AssemblyAI para transcrever áudio da palavra "$palavra"...');
      transcricaoAssemblyAI = await assemblyAIService.transcribeAudio(falaUsuarioAudioBase64);
      print('Transcrição do AssemblyAI para "$palavra": "$transcricaoAssemblyAI"');
    } catch (e) {
      print('Exceção ao chamar serviço AssemblyAI: $e');
    }

    // REMOVIDA: A comparação direta 'final acertou = normalize(palavra) == normalize(transcricaoAssemblyAI ?? '');'
    // Agora o Gemini fará a avaliação de acerto/erro


    String? mensagemGemini; // Mensagem completa do Gemini (dica ou parabéns)
    bool acertouPeloGemini = false; // O valor booleano que o Gemini vai nos dar

    // Prompt atualizado para pedir JSON com acerto/erro e dica
    final prompt = '''
Você é um fonoaudiólogo virtual.
O usuário tentou pronunciar a palavra "$palavra" (som alvo: "$som").
A transcrição da fala do usuário feita por um sistema de alta precisão foi:
"${transcricaoAssemblyAI?.isEmpty ?? true ? 'Não foi possível transcrever com clareza suficiente. Tente falar mais perto do microfone.' : transcricaoAssemblyAI}"

Por favor, analise a transcrição em relação à palavra original e ao som alvo.
Retorne um JSON com duas chaves:
1. "correto": um booleano (true ou false) indicando se a pronúncia foi considerada correta.
2. "feedback": uma string com uma mensagem. Se correto, uma mensagem de parabéns. Se incorreto, uma dica de pronúncia curta e prática focando em orientação sobre como posicionar a boca, língua ou lábios para o som "$som".
Exemplo de retorno JSON:
{"correto": true, "feedback": "Parabéns! Pronunciou corretamente."}
ou
{"correto": false, "feedback": "Para pronunciar 'f', junte o lábio inferior aos dentes superiores e sopre o ar."}
''';

    final geminiResponse = await http.post(
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

    if (geminiResponse.statusCode == 200) {
      try {
        final geminiData = jsonDecode(geminiResponse.body);
        final geminiText = geminiData['candidates']?[0]?['content']?['parts']?[0]?['text'];

        if (geminiText != null && geminiText.isNotEmpty) {
          // Tenta extrair o JSON puro da resposta do Gemini
          final jsonStart = geminiText.indexOf('{');
          final jsonEnd = geminiText.lastIndexOf('}');
          if (jsonStart != -1 && jsonEnd != -1 && jsonStart < jsonEnd) {
            final cleanJson = geminiText.substring(jsonStart, jsonEnd + 1);
            final parsedGeminiFeedback = jsonDecode(cleanJson);
            
            acertouPeloGemini = parsedGeminiFeedback['correto'] ?? false;
            mensagemGemini = parsedGeminiFeedback['feedback'] ?? 'Não foi possível obter feedback detalhado.';
          } else {
            // Fallback se o Gemini não retornar JSON, mas apenas texto livre
            mensagemGemini = geminiText;
            acertouPeloGemini = false; // Considera incorreto se não tiver JSON estruturado
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
      print('❌ Erro na chamada ao Gemini: ${geminiResponse.statusCode} - ${geminiResponse.body}');
      mensagemGemini = 'Erro ao consultar a IA para feedback.';
    }

    // Salvar tentativa no banco
    await db.query(
      '''
      INSERT INTO pronunciation_attempts (user_id, palavra, som, fala_usuario, correto, dica)
      VALUES (@userId, @palavra, @som, @falaUsuario, @correto, @dica)
      ''',
      substitutionValues: {
        'userId': userId,
        'palavra': palavra,
        'som': som,
        'falaUsuario': transcricaoAssemblyAI, // Salva a transcrição do AssemblyAI
        'correto': acertouPeloGemini, // Usa o booleano do Gemini
        'dica': mensagemGemini, // Usa o feedback do Gemini como dica
      },
    );
    return Response.json(body: {
      'correto': acertouPeloGemini,
      'mensagem': mensagemGemini, // Envia o feedback do Gemini diretamente para o frontend
      'transcricao_assemblyai': transcricaoAssemblyAI,
    });
  } catch (e, stack) {
    print('❌ ERRO AO AVALIAR PRONÚNCIA (catch externo): $e');
    print(stack);
    return Response.json(statusCode: 500, body: {'error': e.toString()});
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
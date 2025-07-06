// funfono_backend/routes/api/daily_words/generate_word/index.dart

import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:http/http.dart' as http;
import 'package:dotenv/dotenv.dart' show load, env;
import 'package:funfono_backend/models/questionnaire.dart';
import 'package:funfono_backend/services/database_service.dart';
import 'package:postgres/postgres.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: 405); // Method Not Allowed
  }

  final String? userId = context.request.headers['user_id'];
  if (userId == null || userId.isEmpty) {
    return Response.json(statusCode: 400, body: {'error': 'User ID is required in headers.'});
  }

  load();
  final geminiApiKey = env['GEMINI_API_KEY'] ?? '';

  if (geminiApiKey.isEmpty) {
    print('❌ ERRO: GEMINI_API_KEY não configurada no .env para geração de palavras diárias.');
    return Response.json(
      statusCode: 500,
      body: {'error': 'Gemini API key not configured.'},
    );
  }

  final db = context.read<DatabaseService>().connection;
  if (db == null) {
    return Response.json(statusCode: 500, body: {'error': 'Database service not available.'});
  }

  try {
    // 1. Obter o questionário do usuário (o mais recente)
    Questionnaire? userQuestionnaire;
    try {
      final PostgreSQLResult qResult = await db.query(
        '''
        SELECT id, user_id, age, gender, respondent_type, speech_diagnosis, difficult_sounds,
               speech_therapy_history, favorite_foods, hobbies, preferred_movie_genres,
               occupation, music_preferences, daily_interactions, preferred_communication,
               improvement_goals, practice_frequency, created_at
        FROM questionnaires
        WHERE user_id = @userId
        ORDER BY created_at DESC
        LIMIT 1;
        ''',
        substitutionValues: {'userId': userId},
      );
      
      if (qResult.isNotEmpty) {
        final row = qResult.first;
        userQuestionnaire = Questionnaire(
          id: row[0]?.toString(),
          userId: row[1].toString(),
          age: row[2] as int? ?? 0,
          gender: row[3]?.toString() ?? 'Não informado',
          respondentType: row[4]?.toString() ?? 'Não informado',
          speechDiagnoses: (row[5] as List?)?.cast<String>() ?? [],
          difficultSounds: (row[6] as List?)?.cast<String>() ?? [],
          speechTherapyHistory: row[7]?.toString() ?? 'Não informado',
          favoriteFoods: (row[8] as List?)?.cast<String>() ?? [],
          hobbies: (row[9] as List?)?.cast<String>() ?? [],
          movieGenres: (row[10] as List?)?.cast<String>() ?? [],
          occupation: row[11]?.toString() ?? 'Não informado',
          musicTypes: (row[12] as List?)?.cast<String>() ?? [],
          communicationPeople: (row[13] as List?)?.cast<String>() ?? [],
          communicationPreference: row[14]?.toString() ?? 'Não informado',
          appExpectations: (row[15] as List?)?.cast<String>() ?? [],
          practiceFrequency: row[16]?.toString() ?? 'Não informado',
          createdAt: row[17] as DateTime?,
        );
      }
    } on PostgreSQLException catch (dbError) {
      print('❌ ERRO: Não foi possível obter questionário do usuário para geração de palavras: $dbError');
    } catch (e, stack) {
      print('❌ ERRO: Exceção geral ao obter questionário do usuário: $e\n$stack');
    }

    // 2. Construir o prompt para Gemini com base no questionário
    String personaDetails = '';
    if (userQuestionnaire != null) {
      personaDetails += ' O usuário tem ${userQuestionnaire.age ?? 'idade não informada'} anos, se identifica como ${userQuestionnaire.gender ?? 'não informado'}, e tem como objetivos de melhoria "${userQuestionnaire.appExpectations?.join(', ') ?? 'não informado'}".';
      
      if (userQuestionnaire.difficultSounds?.isNotEmpty == true) {
        personaDetails += ' Ele(a) tem dificuldade com sons como ${userQuestionnaire.difficultSounds!.join(', ')}.';
      }
      if (userQuestionnaire.hobbies?.isNotEmpty == true) {
        personaDetails += ' Seus hobbies incluem ${userQuestionnaire.hobbies!.join(', ')}.';
      }
      if (userQuestionnaire.favoriteFoods?.isNotEmpty == true) {
        personaDetails += ' Comidas favoritas: ${userQuestionnaire.favoriteFoods!.join(', ')}.';
      }
      if (userQuestionnaire.movieGenres?.isNotEmpty == true) {
        personaDetails += ' Gêneros de filmes preferidos: ${userQuestionnaire.movieGenres!.join(', ')}.';
      }
      if (userQuestionnaire.musicTypes?.isNotEmpty == true) {
        personaDetails += ' Estilos de música que ouve: ${userQuestionnaire.musicTypes!.join(', ')}.';
      }
    } else {
      personaDetails = ' O usuário não preencheu o questionário ou não foi encontrado.';
    }

    // 3. Obter as palavras praticadas pelo usuário HOJE para evitar repetição
    final today = DateTime.now().toUtc();
    final startOfDay = DateTime.utc(today.year, today.month, today.day);
    List<String> wordsPracticedToday = [];
    try {
      final PostgreSQLResult practicedResults = await db.query(
        '''
        SELECT word FROM daily_word_attempts
        WHERE user_id = @userId AND created_at >= @startOfDay;
        ''',
        substitutionValues: {'userId': userId, 'startOfDay': startOfDay},
      );
      if (practicedResults.isNotEmpty) {
        wordsPracticedToday = practicedResults.map((row) => row[0].toString()).toList();
      }
    } on PostgreSQLException catch (dbError) {
      print('❌ ERRO: Não foi possível obter palavras praticadas hoje: $dbError');
    } catch (e, stack) {
      print('❌ ERRO: Exceção geral ao obter palavras praticadas hoje: $e\n$stack');
    }

    // 4. Montar o prompt para Gemini
    final String prompt = '''
Gere 3 (três) palavras únicas e diferentes para um exercício de pronúncia diária em português.
As palavras devem ter 2 a 3 sílabas e ser adequadas para prática de fala.
Tente gerar palavras relacionadas aos seguintes detalhes do usuário: ${personaDetails}
As palavras geradas DEVE ser diferentes das seguintes palavras (praticadas hoje): ${wordsPracticedToday.join(', ')}.
Responda APENAS com as 3 palavras, uma por linha, sem numeração ou qualquer outra informação.
Exemplo:
Casa
Bola
Mesa
''';

    final response = await http.post(
      Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$geminiApiKey'),
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
      final data = jsonDecode(response.body);
      final rawText = data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';
      
      // CORRIGIDO: Cast explícito de rawText para String e filtro de empty
      final List<String> words = (rawText as String) // Cast explícito aqui
          .split('\n')
          .map((word) => (word as String).trim().replaceAll(RegExp(r'[.,!?"]'), '')) // Garante que 'word' é String
          .where((word) => word.isNotEmpty) // isNotEmpty agora funciona corretamente em String
          .toList();

      if (words.length == 3) {
        return Response.json(body: {'words': words});
      } else {
        print('❌ ERRO: Gemini não gerou 3 palavras esperadas. Resposta: $rawText');
        return Response.json(statusCode: 500, body: {'error': 'Falha na geração de palavras pela IA: Formato inesperado.'});
      }
    } else {
      print('❌ Erro na chamada ao Gemini para gerar palavras diárias: ${response.statusCode} - ${response.body}');
      return Response.json(
        statusCode: 500,
        body: {'error': 'Erro ao gerar palavras da IA.'},
      );
    }
  } on FormatException {
    return Response.json(statusCode: 400, body: {'error': 'Corpo da requisição JSON inválido.'});
  } on PostgreSQLException catch (e) {
    print('PostgreSQL Error getting user questionnaire for daily words: $e');
    return Response.json(statusCode: 500, body: {'error': 'Database error: ${e.message}'});
  } catch (e, stack) {
    print('❌ ERRO AO GERAR PALAVRAS DIÁRIAS (catch externo): $e');
    print(stack);
    return Response.json(statusCode: 500, body: {'error': e.toString()});
  }
}
// funfono_backend/lib/repositories/questionnaire_repository.dart

import 'package:uuid/uuid.dart';
import 'package:funfono_backend/models/questionnaire.dart';
import 'package:funfono_backend/services/database_service.dart';

final _uuid = Uuid();

Future<void> saveQuestionnaire(
  Questionnaire data,
  DatabaseService dbService,
) async {
  final db = dbService.connection;

  try {
    await db.query('''
      INSERT INTO questionnaires (
        id, user_id, age, gender, respondent_type, speech_diagnosis,
        difficult_sounds, speech_therapy_history, favorite_foods, hobbies,
        preferred_movie_genres, occupation, music_preferences,
        daily_interactions, preferred_communication, improvement_goals,
        practice_frequency
      ) VALUES (
        @id, @userId, @age, @gender, @respondentType, @speechDiagnosis,
        @difficultSounds, @speechTherapyHistory, @favoriteFoods, @hobbies,
        @preferredMovieGenres, @occupation, @musicPreferences,
        @dailyInteractions, @preferredCommunication, @improvementGoals,
        @practiceFrequency
      )
    ''', substitutionValues: {
      'id': _uuid.v4(),
      'userId': data.userId,
      'age': data.age,
      'gender': data.gender,
      'respondentType': data.respondentType,
      'speechDiagnosis': data.speechDiagnoses,
      'difficultSounds': data.difficultSounds, // Correção: era 'pronunciationDifficulties' antes
      'speechTherapyHistory': data.speechTherapyHistory,
      'favoriteFoods': data.favoriteFoods,
      'hobbies': data.hobbies,
      'preferredMovieGenres': data.movieGenres,
      'occupation': data.occupation,
      'musicPreferences': data.musicTypes, // Correção: era 'musicTypes' antes
      'dailyInteractions': data.communicationPeople,
      'preferredCommunication': data.communicationPreference,
      'improvementGoals': data.appExpectations,
      'practiceFrequency': data.practiceFrequency,
    });
  } catch (e, stack) {
    print('❌ ERRO AO SALVAR QUESTIONÁRIO: $e');
    print(stack);
    rethrow;
  }
}

Future<Map<String, dynamic>> analyzeWithGemini(Questionnaire data) async {
  // Este mock depende dos campos serem não-nulos ou tratados.
  return {
    'message': 'Perfil gerado com base nas preferências e dificuldades',
    'perfil': {
      'tipo_comunicador': data.communicationPreference,
      'sons_prioritarios': data.difficultSounds?.take(2).toList() ?? [], // Adicionado ?. e ?? []
      'interesses': [
        ...(data.hobbies ?? []), // Adicionado ?? []
        ...(data.favoriteFoods ?? []), // Adicionado ?? []
        ...(data.musicTypes ?? []), // Adicionado ?? []
      ],
    }
  };
}
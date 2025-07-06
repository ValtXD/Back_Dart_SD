// funfono_backend/lib/models/questionnaire.dart

import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart'; // Mantenha se você usa UUID para o ID

part 'questionnaire.g.dart';

@JsonSerializable()
class Questionnaire {
  final String? id; 

  @JsonKey(name: 'user_id')
  final String userId; // userId é String e não nulo

  // TODOS ESTES CAMPOS DEVEM SER NULÁVEIS (com '?')
  // para corresponder ao que pode ser enviado pelo frontend.
  final int? age; // Pode ser nulo
  final String? gender; // AQUI ESTÁ O CAMPO `gender`
  
  @JsonKey(name: 'respondent_type')
  final String? respondentType;

  @JsonKey(name: 'speech_diagnosis')
  final List<String>? speechDiagnoses; // Listas também podem ser nulas
  
  @JsonKey(name: 'difficult_sounds')
  final List<String>? difficultSounds;
  
  @JsonKey(name: 'speech_therapy_history')
  final String? speechTherapyHistory;

  @JsonKey(name: 'favorite_foods')
  final List<String>? favoriteFoods;
  
  final List<String>? hobbies;
  
  @JsonKey(name: 'preferred_movie_genres')
  final List<String>? movieGenres;
  
  final String? occupation;
  
  @JsonKey(name: 'music_preferences')
  final List<String>? musicTypes;
  
  @JsonKey(name: 'daily_interactions')
  final List<String>? communicationPeople;
  
  @JsonKey(name: 'preferred_communication')
  final String? communicationPreference;
  
  @JsonKey(name: 'improvement_goals')
  final List<String>? appExpectations;
  
  @JsonKey(name: 'practice_frequency')
  final String? practiceFrequency;

   @JsonKey(name: 'created_at')
  final DateTime? createdAt; 

  Questionnaire({
    this.id,
    required this.userId, // userId é o único campo obrigatório
    this.age,
    this.gender,
    this.respondentType,
    this.speechDiagnoses,
    this.difficultSounds,
    this.speechTherapyHistory,
    this.favoriteFoods,
    this.hobbies,
    this.movieGenres,
    this.occupation,
    this.musicTypes,
    this.communicationPeople,
    this.communicationPreference,
    this.appExpectations,
    this.practiceFrequency,
    this.createdAt,
  });

  factory Questionnaire.fromJson(Map<String, dynamic> json) => _$QuestionnaireFromJson(json);
  Map<String, dynamic> toJson() => _$QuestionnaireToJson(this);
}
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'questionnaire.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Questionnaire _$QuestionnaireFromJson(Map<String, dynamic> json) =>
    Questionnaire(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      age: (json['age'] as num?)?.toInt(),
      gender: json['gender'] as String?,
      respondentType: json['respondent_type'] as String?,
      speechDiagnoses: (json['speech_diagnosis'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      difficultSounds: (json['difficult_sounds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      speechTherapyHistory: json['speech_therapy_history'] as String?,
      favoriteFoods: (json['favorite_foods'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      hobbies:
          (json['hobbies'] as List<dynamic>?)?.map((e) => e as String).toList(),
      movieGenres: (json['preferred_movie_genres'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      occupation: json['occupation'] as String?,
      musicTypes: (json['music_preferences'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      communicationPeople: (json['daily_interactions'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      communicationPreference: json['preferred_communication'] as String?,
      appExpectations: (json['improvement_goals'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      practiceFrequency: json['practice_frequency'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$QuestionnaireToJson(Questionnaire instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'age': instance.age,
      'gender': instance.gender,
      'respondent_type': instance.respondentType,
      'speech_diagnosis': instance.speechDiagnoses,
      'difficult_sounds': instance.difficultSounds,
      'speech_therapy_history': instance.speechTherapyHistory,
      'favorite_foods': instance.favoriteFoods,
      'hobbies': instance.hobbies,
      'preferred_movie_genres': instance.movieGenres,
      'occupation': instance.occupation,
      'music_preferences': instance.musicTypes,
      'daily_interactions': instance.communicationPeople,
      'preferred_communication': instance.communicationPreference,
      'improvement_goals': instance.appExpectations,
      'practice_frequency': instance.practiceFrequency,
      'created_at': instance.createdAt?.toIso8601String(),
    };

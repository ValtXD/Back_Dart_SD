// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'questionnaire.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Questionnaire _$QuestionnaireFromJson(Map<String, dynamic> json) =>
    Questionnaire(
      userId: json['userId'] as String?,
      age: (json['age'] as num).toInt(),
      gender: json['gender'] as String,
      respondentType: json['respondentType'] as String,
      speechDiagnoses: (json['speechDiagnoses'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      pronunciationDifficulties:
          (json['pronunciationDifficulties'] as List<dynamic>)
              .map((e) => e as String)
              .toList(),
      speechTherapyHistory: json['speechTherapyHistory'] as String,
      favoriteFoods: (json['favoriteFoods'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      hobbies:
          (json['hobbies'] as List<dynamic>).map((e) => e as String).toList(),
      movieGenres: (json['movieGenres'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      occupation: json['occupation'] as String,
      musicTypes: (json['musicTypes'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      communicationPeople: (json['communicationPeople'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      communicationPreference: json['communicationPreference'] as String,
      appExpectations: (json['appExpectations'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      practiceFrequency: json['practiceFrequency'] as String,
    );

Map<String, dynamic> _$QuestionnaireToJson(Questionnaire instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'age': instance.age,
      'gender': instance.gender,
      'respondentType': instance.respondentType,
      'speechDiagnoses': instance.speechDiagnoses,
      'pronunciationDifficulties': instance.pronunciationDifficulties,
      'speechTherapyHistory': instance.speechTherapyHistory,
      'favoriteFoods': instance.favoriteFoods,
      'hobbies': instance.hobbies,
      'movieGenres': instance.movieGenres,
      'occupation': instance.occupation,
      'musicTypes': instance.musicTypes,
      'communicationPeople': instance.communicationPeople,
      'communicationPreference': instance.communicationPreference,
      'appExpectations': instance.appExpectations,
      'practiceFrequency': instance.practiceFrequency,
    };

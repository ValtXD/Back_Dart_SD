// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GameResult _$GameResultFromJson(Map<String, dynamic> json) => GameResult(
      id: (json['id'] as num?)?.toInt(),
      userId: json['user_id'] as String,
      score: (json['score'] as num).toInt(),
      correctWords: (json['correct_words'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      incorrectWords: (json['incorrect_words'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$GameResultToJson(GameResult instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'score': instance.score,
      'correct_words': instance.correctWords,
      'incorrect_words': instance.incorrectWords,
      'created_at': instance.createdAt?.toIso8601String(),
    };

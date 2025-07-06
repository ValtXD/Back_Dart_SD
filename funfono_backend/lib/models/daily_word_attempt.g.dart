// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_word_attempt.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DailyWordAttempt _$DailyWordAttemptFromJson(Map<String, dynamic> json) =>
    DailyWordAttempt(
      id: (json['id'] as num?)?.toInt(),
      userId: json['user_id'] as String,
      word: json['word'] as String,
      userTranscription: json['user_transcription'] as String,
      isCorrect: json['is_correct'] as bool,
      tip: json['tip'] as String,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$DailyWordAttemptToJson(DailyWordAttempt instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'word': instance.word,
      'user_transcription': instance.userTranscription,
      'is_correct': instance.isCorrect,
      'tip': instance.tip,
      'created_at': instance.createdAt?.toIso8601String(),
    };

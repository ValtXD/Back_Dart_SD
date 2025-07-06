// funfono_backend/lib/models/daily_word_attempt.dart

import 'package:json_annotation/json_annotation.dart';

part 'daily_word_attempt.g.dart';

@JsonSerializable()
class DailyWordAttempt {
  final int? id; // ID do banco de dados, pode ser nulo ao criar
  @JsonKey(name: 'user_id')
  final String userId;
  final String word;
  @JsonKey(name: 'user_transcription')
  final String userTranscription;
  @JsonKey(name: 'is_correct')
  final bool isCorrect;
  final String tip;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt; // Data da tentativa

  DailyWordAttempt({
    this.id,
    required this.userId,
    required this.word,
    required this.userTranscription,
    required this.isCorrect,
    required this.tip,
    this.createdAt,
  });

  factory DailyWordAttempt.fromJson(Map<String, dynamic> json) => _$DailyWordAttemptFromJson(json);
  Map<String, dynamic> toJson() => _$DailyWordAttemptToJson(this);
}
// lib/models/game_result.dart (Frontend e Backend)

import 'package:json_annotation/json_annotation.dart';

part 'game_result.g.dart';

@JsonSerializable()
class GameResult {
  final int? id; // ID do banco de dados, nulo ao criar
  @JsonKey(name: 'user_id')
  final String userId;
  final int score; // Pontuação total do jogo
  @JsonKey(name: 'correct_words')
  final List<String> correctWords; // Palavras acertadas
  @JsonKey(name: 'incorrect_words')
  final List<String> incorrectWords; // Palavras erradas
  @JsonKey(name: 'created_at')
  final DateTime? createdAt; // Data da criação do registro

  GameResult({
    this.id,
    required this.userId,
    required this.score,
    required this.correctWords,
    required this.incorrectWords,
    this.createdAt,
  });

  factory GameResult.fromJson(Map<String, dynamic> json) => _$GameResultFromJson(json);
  Map<String, dynamic> toJson() => _$GameResultToJson(this);
}
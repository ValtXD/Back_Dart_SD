// lib/models/reminder.dart (Backend)

import 'package:json_annotation/json_annotation.dart';

part 'reminder.g.dart';

@JsonSerializable()
class Reminder {
  final int? id; // ID do banco de dados, pode ser nulo ao criar
  @JsonKey(name: 'user_id')
  final String userId;
  final String title;
  @JsonKey(name: 'day_of_week')
  final int dayOfWeek; // 1=Segunda, 7=Domingo
  final String time; // Formato "HH:MM" (ex: "06:00")
  @JsonKey(name: 'created_at')
  final DateTime? createdAt; // Data de criação, preenchida pelo backend

  Reminder({
    this.id,
    required this.userId,
    required this.title,
    required this.dayOfWeek,
    required this.time,
    this.createdAt,
  });

  factory Reminder.fromJson(Map<String, dynamic> json) => _$ReminderFromJson(json);
  Map<String, dynamic> toJson() => _$ReminderToJson(this);
}
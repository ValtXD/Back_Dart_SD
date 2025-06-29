// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reminder.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Reminder _$ReminderFromJson(Map<String, dynamic> json) => Reminder(
      id: (json['id'] as num?)?.toInt(),
      userId: json['user_id'] as String,
      title: json['title'] as String,
      dayOfWeek: (json['day_of_week'] as num).toInt(),
      time: json['time'] as String,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$ReminderToJson(Reminder instance) => <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'title': instance.title,
      'day_of_week': instance.dayOfWeek,
      'time': instance.time,
      'created_at': instance.createdAt?.toIso8601String(),
    };

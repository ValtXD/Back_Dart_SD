import 'package:json_annotation/json_annotation.dart';

part 'questionnaire.g.dart';

@JsonSerializable()
class Questionnaire {
  final String? userId;
  final int age;
  final String gender;
  final String respondentType;
  final List<String> speechDiagnoses;
  final List<String> pronunciationDifficulties;
  final String speechTherapyHistory;
  final List<String> favoriteFoods;
  final List<String> hobbies;
  final List<String> movieGenres;
  final String occupation;
  final List<String> musicTypes;
  final List<String> communicationPeople;
  final String communicationPreference;
  final List<String> appExpectations;
  final String practiceFrequency;

  Questionnaire({
    this.userId,
    required this.age,
    required this.gender,
    required this.respondentType,
    required this.speechDiagnoses,
    required this.pronunciationDifficulties,
    required this.speechTherapyHistory,
    required this.favoriteFoods,
    required this.hobbies,
    required this.movieGenres,
    required this.occupation,
    required this.musicTypes,
    required this.communicationPeople,
    required this.communicationPreference,
    required this.appExpectations,
    required this.practiceFrequency,
  });

  factory Questionnaire.fromJson(Map<String, dynamic> json) =>
      _$QuestionnaireFromJson(json);

  Map<String, dynamic> toJson() => _$QuestionnaireToJson(this);
}

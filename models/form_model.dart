class FormQuestion {
  final String id;
  final String question;
  final List<String>? options;
  final bool isMultipleChoice;
  final String type;

  FormQuestion({
    required this.id,
    required this.question,
    this.options,
    this.isMultipleChoice = false,
    this.type = 'text',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'question': question,
        'options': options,
        'isMultipleChoice': isMultipleChoice,
        'type': type,
      };
}

class FormSection {
  final String id;
  final String title;
  final List<FormQuestion> questions;

  FormSection({
    required this.id,
    required this.title,
    required this.questions,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'questions': questions.map((q) => q.toJson()).toList(),
      };
}

class FormModel {
  final String id;
  final String title;
  final List<FormSection> sections;

  FormModel({
    required this.id,
    required this.title,
    required this.sections,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'sections': sections.map((s) => s.toJson()).toList(),
      };
}
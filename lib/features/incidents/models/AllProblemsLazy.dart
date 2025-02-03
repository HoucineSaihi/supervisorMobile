import 'package:supervisormobile/features/calendar/models/Problem.dart';

class AllProblemsLazy {
  List<Problem> problems;
  int totalRecords;

  AllProblemsLazy({
    required this.problems,
    required this.totalRecords,
  });

  factory AllProblemsLazy.fromJson(Map<String, dynamic> json) {
    return AllProblemsLazy(
      problems: (json['problems'] as List<dynamic>)
          .map((incident) => Problem.fromJson(incident))
          .toList(),
      totalRecords: json['totalRecords'] ?? 0,
    );
  }
}

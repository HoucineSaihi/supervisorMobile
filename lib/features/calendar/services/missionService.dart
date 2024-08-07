import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supervisormobile/features/calendar/models/missionModel.dart';
import 'package:supervisormobile/features/calendar/models/questionMissionModel.dart';
import 'package:supervisormobile/features/calendar/models/actionsModel.dart'; // Import the ActionM model

class MissionService {
  final String baseURL = "https://280f-41-62-141-60.ngrok-free.app";

  // API endpoints using baseURL
  late final String apiUrl;
  late final String missionDetailsUrl;
  late final String actionsUrl;

  MissionService() {
    apiUrl = 'https://14a0-102-157-194-217.ngrok-free.app/api/Missions/getMissionsForAreaManager';
    missionDetailsUrl = 'https://14a0-102-157-194-217.ngrok-free.app/api/Missions/missionAllQuestion';
    actionsUrl = 'https://14a0-102-157-194-217.ngrok-free.app/api/ActionMs?description=Tous&code=Tous&responsable=Tous&mail=Tous';
  }

  Future<List<Mission>> getPlanifiedMissions(List<int> userIds, List<int> boutiqueIds, DateTime planifiedAt) async {
    final String formattedDate = planifiedAt.toIso8601String();
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'userIds': userIds,
        'boutiqueIds': boutiqueIds,
        'planifiedAt': formattedDate,
      }),
    );

    if (response.statusCode == 200) {
      List<dynamic> body = json.decode(response.body);
      List<Mission> missions = body.map((dynamic item) => Mission.fromJson(item)).toList();
      return missions;
    } else {
      throw Exception('Failed to load missions');
    }
  }

  Future<Mission> getMissionDetails(int missionId) async {
    final response = await http.get(
      Uri.parse('$missionDetailsUrl/$missionId'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      return Mission.fromJson(body); // Assuming Mission.fromJson can handle a single mission object
    } else {
      throw Exception('Failed to load mission details');
    }
  }

  Future<QuestionMission> getQuestionDetails(int questionId) async {
    final response = await http.get(
      Uri.parse('https://14a0-102-157-194-217.ngrok-free.app/api/MissionQuestions/$questionId'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> json = jsonDecode(response.body);
      return QuestionMission.fromJson(json);
    } else {
      throw Exception('Failed to load question details');
    }
  }

  Future<List<ActionM>> getActions() async {
    final response = await http.get(
      Uri.parse(actionsUrl),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> body = json.decode(response.body);
      List<ActionM> actions = body.map((dynamic item) => ActionM.fromJson(item)).toList();
      return actions;
    } else {
      throw Exception('Failed to load actions');
    }
  }

  Future<void> updateMissionQuestion(int questionId, QuestionMission updatedQuestion) async {
    final String url = '$baseURL/api/MissionQuestions/$questionId';

    final response = await http.put(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(updatedQuestion.toJson()), // Convert updatedQuestion to JSON
    );

    if (response.statusCode == 204) {
      // Successfully updated
    } else {
      // Handle failure
      throw Exception('Failed to update mission question');
    }
  }

  Future<void> updateMission(int missionId, Mission updatedMission,int status) async {
    final String url = 'https://14a0-102-157-194-217.ngrok-free.app/api/Missions/$missionId';
    updatedMission.status = status;
    final response = await http.put(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(updatedMission.toJson()), // Convert updatedMission to JSON
    );

    if (response.statusCode == 204) {
      // Successfully updated
    } else {
      // Handle failure
      throw Exception('Failed to update mission');
    }
  }
}

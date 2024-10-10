import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:supervisormobile/features/calendar/models/boutiqueModel.dart';
import 'package:supervisormobile/features/calendar/models/choixReponseQuestion.dart';
import 'package:supervisormobile/features/calendar/models/missionModel.dart';
import 'package:supervisormobile/features/calendar/models/questionMissionModel.dart';
import 'package:supervisormobile/features/calendar/models/actionsModel.dart'; // Import the ActionM model
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'dart:html';
import 'dart:io' as io;

class MissionService {

  final _storage = FlutterSecureStorage();
  int _currentUserID = 0;

  Future<void> _loadAuthToken() async {
    // Retrieve the user ID from secure storage

    String? userIdString = await window.localStorage['currentUserId'];
    _currentUserID = userIdString != null ? int.tryParse(userIdString) ?? 0 : 0;

  }

  final String baseURL = '${dotenv.env['BASE_URL']}';

  // API endpoints using baseURL
  late final String apiUrl;
  late final String missionDetailsUrl;
  late final String actionsUrl;

  MissionService() {
    apiUrl = '${dotenv.env['BASE_URL']}/api/Missions/getMissionsForAreaManager';
    missionDetailsUrl = '${dotenv.env['BASE_URL']}/api/Missions/missionAllQuestion';
    actionsUrl = '${dotenv.env['BASE_URL']}/api/ActionMs?description=Tous&code=Tous&responsable=Tous&mail=Tous';
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
      Uri.parse('${dotenv.env['BASE_URL']}/api/MissionQuestions/$questionId'),
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
    final String url = '${dotenv.env['BASE_URL']}/api/MissionQuestions/$questionId';

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
    final String url = '${dotenv.env['BASE_URL']}/api/Missions/$missionId';
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

  Future<List<BoutiqueModel>> getBoutiques() async {

    String? userIdString = await window.localStorage['currentUserId'];
    _currentUserID = userIdString != null ? int.tryParse(userIdString) ?? 0 : 0;

    List<int> userIdArray = [];
    userIdArray.add(_currentUserID);

    final String boutiquesUrl = '${dotenv.env['BASE_URL']}/api/Boutiques/getBoutiquesByUserIDs';

    final response = await http.post(
      Uri.parse(boutiquesUrl),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(
        userIdArray, // Add the array to the body
      ),
    );

    if (response.statusCode == 200) {
      List<dynamic> body = json.decode(response.body);
      List<BoutiqueModel> boutiques = body.map((dynamic item) => BoutiqueModel.fromJson(item)).toList();
      return boutiques;
    } else {
      throw Exception('Failed to load boutiques');
    }
  }

  Future<List<Mission>> getAllNotPlanifiedMissions() async {
    String? userIdString = await window.localStorage['currentUserId'];
    _currentUserID = userIdString != null ? int.tryParse(userIdString) ?? 0 : 0;

    final String url = '${dotenv.env['BASE_URL']}/api/Missions/GetAllNotPlanifiedMissions/$_currentUserID'; // Static userID is 2

    final response = await http.get(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> body = json.decode(response.body);
      List<Mission> missions = body.map((dynamic item) => Mission.fromJson(item)).toList();
      return missions;
    } else {
      throw Exception('Failed to load missions');
    }
  }

  Future<void> addMission(Mission mission) async {
    final response = await http.post(
      Uri.parse('${dotenv.env['BASE_URL']}/api/Missions'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(mission.toJson()),
    );

    if (response.statusCode == 201) {
      // Mission added successfully
    } else {
      // Handle failure
      throw Exception('Failed to add mission');
    }
  }

  /* Future<String> uploadFile(File file) async {
    final Uri uri = Uri.parse('$baseURL/api/Files'); // Construct the URI for your file upload endpoint

    // Determine the MIME type based on the file extension
    final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
    final mimeTypeParts = mimeType.split('/');

    var request = http.MultipartRequest('POST', uri)
      ..headers['accept'] = ''
      ..headers['Content-Type'] = 'multipart/form-data'
      ..files.add(
        http.MultipartFile(
          'image', // Name of the file parameter in your API
          file.readAsBytes().asStream(),
          file.lengthSync(),
          filename: file.path.split('/').last,
          contentType: MediaType(mimeTypeParts[0], mimeTypeParts[1]),
        ),
      );

    final response = await request.send();

    if (response.statusCode == 200) {
      final responseString = await response.stream.bytesToString();
      final responseData = json.decode(responseString);
      return responseData['file']; // Extract the filename from the response
    } else {
      throw Exception('Failed to upload file');
    }
  } */

 /* Future<File> getImage(String filename) async {
    final Uri uri = Uri.parse('$baseURL/api/Files/getImage/$filename');

    final response = await http.get(uri, headers: {'accept': 'image/jpeg'});

    if (response.statusCode == 200) {
      final bytes = response.bodyBytes;

      // Create a temporary file to save the image
      final tempDir = await Directory.systemTemp.createTemp();
      final file = File('${tempDir.path}/$filename');

      // Write the image bytes to the file
      await file.writeAsBytes(bytes);

      return file;
    } else {
      throw Exception('Failed to retrieve image: ${response.reasonPhrase}');
    }
  } */

  Future<List<QuestionMission>> getQuestionsForSousMission(int sousMissionId) async {
    final String url = '${dotenv.env['BASE_URL']}/api/MissionQuestions?idSousMission=$sousMissionId';

    final response = await http.get(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> body = json.decode(response.body);
      List<QuestionMission> questions = body.map((dynamic item) => QuestionMission.fromJson(item)).toList();
      return questions;
    } else {
      throw Exception('Failed to load questions for sousMission');
    }
  }

  Future<List<ChoixReponseQuestion>> getAllChoixReponse(int modeleReponseID) async {

    final String url = '${dotenv.env['BASE_URL']}/api/ChoixReponseQuestion/$modeleReponseID';
    final response = await http.get(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );
    if (response.statusCode == 200) {
      List<dynamic> body = json.decode(response.body);
      List<ChoixReponseQuestion> allChoix = body.map((dynamic item) => ChoixReponseQuestion.fromJson(item)).toList();
      return allChoix;
    } else {
      throw Exception('Failed to load questions for sousMission');
    }
  }


  Future<String> uploadFile(Uint8List? imageData, String? fileName) async {
    final Uri uri = Uri.parse('${dotenv.env['BASE_URL']}/api/Files'); // Construct the URI for your file upload endpoint

    // Determine the MIME type based on the file extension or content
    final mimeType = lookupMimeType(fileName!) ?? 'application/octet-stream';
    final mimeTypeParts = mimeType.split('/');

    var request = http.MultipartRequest('POST', uri)
      ..headers['Content-Type'] = 'multipart/form-data'
      ..files.add(
        http.MultipartFile.fromBytes(
          'image', // Name of the file parameter in your API
          imageData!, // Use Uint8List directly
          filename: fileName,
          contentType: MediaType(mimeTypeParts[0], mimeTypeParts[1]),
        ),
      );

    final response = await request.send();

    if (response.statusCode == 200) {
      final responseString = await response.stream.bytesToString();
      final responseData = json.decode(responseString);
      return responseData['file']; // Extract the filename from the response
    } else {
      throw Exception('Failed to upload file');
    }
  }

  Future<Uint8List> getImage(String filename) async {
    final Uri uri = Uri.parse('${dotenv.env['BASE_URL']}/api/Files/getImage/$filename');

    final response = await http.get(uri, headers: {'accept': 'image/jpeg'});

    if (response.statusCode == 200) {
      final bytes = response.bodyBytes; // Get the image bytes directly
      return bytes; // Return the bytes as Uint8List
    } else {
      throw Exception('Failed to retrieve image: ${response.reasonPhrase}');
    }
  }




}








import 'dart:convert';
import 'dart:io';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:supervisormobile/features/calendar/models/boutiqueModel.dart';
import 'package:supervisormobile/features/calendar/models/choixReponseQuestion.dart';
import 'package:supervisormobile/features/calendar/models/missionModel.dart';
import 'package:supervisormobile/features/calendar/models/questionMissionModel.dart';
import 'package:supervisormobile/features/calendar/models/actionsModel.dart'; // Import the ActionM model
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

class MissionService {

  final _storage = FlutterSecureStorage();
  int _currentUserID = 0;

  Future<void> _loadAuthToken() async {
    // Retrieve the user ID from secure storage

    String? userIdString = await _storage.read(key: 'currentUserId');
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
  Future<void> deleteImage(String fileName) async {
    final Uri uri = Uri.parse('$baseURL/api/Files/deleteImage/$fileName');

    final response = await http.delete(
      uri,
      headers: {
        'accept': '*/*',
      },
    );

    if (response.statusCode != 200) {
      final responseBody = json.decode(response.body);
      throw Exception('Failed to delete image: ${responseBody['message']}');
    }
  }

  Future<String> downloadFile(String fileName) async {
    final Uri uri = Uri.parse('$baseURL/api/Files/download/$fileName');

    final response = await http.get(
      uri,
      headers: {
        'accept': 'application/octet-stream',
      },
    );

    if (response.statusCode == 200) {
      // Get the directory to save the file
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName';

      // Write the file bytes to the file
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      return filePath; // Return the file path for further use
    } else {
      final responseBody = json.decode(response.body);
      throw Exception('Failed to download file: ${responseBody['message']}');
    }
  }


  Future<void> deleteFile(String fileName) async {
    final Uri uri = Uri.parse('$baseURL/api/Files/deleteFile/$fileName');

    try {
      final response = await http.delete(
        uri,
        headers: {
          'accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        print('File deleted successfully: ${responseBody['message']}');
      } else {
        final responseBody = json.decode(response.body);
        throw Exception('Failed to delete file: ${responseBody['message']}');
      }
    } catch (e) {
      print('Error deleting file: $e');
      throw Exception('Error deleting file: $e');
    }
  }

  Future<String> uploadJointure(File file) async {
    final Uri uri = Uri.parse('$baseURL/api/Files/upload'); // Your file upload API URL

    // Determine the MIME type based on the file extension
    final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
    final mimeTypeParts = mimeType.split('/');

    var request = http.MultipartRequest('POST', uri)
      ..headers['accept'] = '*/*'
      ..headers['Content-Type'] = 'multipart/form-data'
      ..files.add(
        http.MultipartFile(
          'file', // API endpoint parameter name should be 'file'
          file.readAsBytes().asStream(),
          file.lengthSync(),
          filename: file.path.split('/').last,
          contentType: MediaType(mimeTypeParts[0], mimeTypeParts[1]),
        ),
      );

    final response = await request.send();

    if (response.statusCode == 200) {
      // Parse the response data
      final responseString = await response.stream.bytesToString();
      final responseData = json.decode(responseString);

      // Return the response as a map with file details
      return
        responseData['fileName'];

    } else {
      throw Exception('Failed to upload file');
    }
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

  Future<void> updateMissionQuestion(int questionId, QuestionMission updatedQuestion,BuildContext context) async {
    final String url = '${dotenv.env['BASE_URL']}/api/MissionQuestions/$questionId';

    try {
      final response = await http.put(
        Uri.parse(url),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(updatedQuestion.toJson()),
      );

      if (response.statusCode == 200) {
        // Successfully updated

      } else {
        // Parse the response body to get the message
        final responseBody = json.decode(response.body);
        final errorMessage = responseBody['message'] ?? 'An error occurred';

        // Optionally, you can throw an exception or return the message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
        throw Exception('Ecrire un commentaire.');
      }
    } catch (e) {
      // Handle any exceptions that occur
      print('Exception: $e');
      throw Exception('Failed to update the mission question');
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
    } else if (response.statusCode == 400 ) {
      // Handle failure
      throw Exception('Vous devez répondre a tous les questions.');
    } else {
      throw Exception('Une Erreur est survenue.');
    }
  }

  Future<List<BoutiqueModel>> getBoutiques() async {
    String? userIdString = await _storage.read(key: 'currentUserId');
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
    String? userIdString = await _storage.read(key: 'currentUserId');
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

  Future<void> addMission(Mission mission, BuildContext context) async {
    try {
      final response = await http.post(
        Uri.parse('${dotenv.env['BASE_URL']}/api/Missions'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(mission.toJson()),
      );

      if (response.statusCode == 200) {
        // Success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: AwesomeSnackbarContent(
              title: 'Success!',
              message: 'Mission ajoutée avec succès.',
              contentType: ContentType.success,
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
        );
      } else {
        // Parse the error message from the backend
        final responseBody = json.decode(response.body);
        final errorMessage = responseBody['message'] ?? 'Failed to add mission';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: AwesomeSnackbarContent(
              title: 'Erreur!',
              message: errorMessage,
              contentType: ContentType.failure,
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
        );

        // Optionally, you can throw an exception with the message
        throw Exception(errorMessage);
      }
    } catch (e) {


      throw Exception('An unexpected error occurred: $e');
    }
  }

  Future<String> uploadFile(File file) async {
    final Uri uri = Uri.parse('$baseURL/api/Files'); // Construct the URI for your file upload endpoint

    // Determine the MIME type based on the file extension
    final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
    final mimeTypeParts = mimeType.split('/');

    var request = http.MultipartRequest('POST', uri)
      ..headers['accept'] = '*/*'
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
  }

  Future<File> getImage(String filename) async {
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
  }

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




}

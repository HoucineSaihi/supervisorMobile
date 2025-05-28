import 'dart:convert';
import 'dart:io';
import 'dart:html' as html;

import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supervisormobile/features/calendar/models/boutiqueModel.dart';
import 'package:supervisormobile/features/calendar/models/choixReponseQuestion.dart';
import 'package:supervisormobile/features/calendar/models/missionModel.dart';
import 'package:supervisormobile/features/calendar/models/questionMissionModel.dart';
import 'package:supervisormobile/features/calendar/models/actionsModel.dart'; // Import the ActionM model
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:dio/dio.dart' as dio;

import 'dart:typed_data';

import 'package:supervisormobile/services/DioService.dart';

import '../../../dtos/questions/questionAnswerDto.dart';

class MissionService {

  final _storage = FlutterSecureStorage();
  int _currentUserID = 0;

  Future<void> _loadAuthToken() async {
    // Retrieve the user ID from secure storage

    String? userIdString = await _storage.read(key: 'currentUserId');
    _currentUserID = userIdString != null ? int.tryParse(userIdString) ?? 0 : 0;

  }


  static final dio.Dio _dio = DioService.dio;


  // API endpoints using baseURL
  late final String apiUrl;
  late final String missionDetailsUrl;
  late final String actionsUrl;

  MissionService() {
    apiUrl = '/Missions/getMissionsForAreaManager';
    missionDetailsUrl = '/Missions/missionAllQuestion';
    actionsUrl = '/ActionMs?description=Tous&code=Tous&responsable=Tous&mail=Tous';
  }
  Future<void> deleteImage(String fileName) async {
    try {
      final response = await _dio.delete(
        '/Files/deleteImage/$fileName', // ✅ Relative path
        options: dio.Options(
          headers: {
            'accept': '*/*',
          },
        ),
      );

      if (response.statusCode != 200) {
        final responseBody = response.data;
        throw Exception('Failed to delete image: ${responseBody['message']}');
      }
    } catch (e) {
      print('Error deleting image: $e');
      throw Exception('Error deleting image: $e');
    }
  }


  Future<String> downloadFile(String fileName) async {
    try {
      final response = await _dio.get(
        '/Files/download/$fileName', // ✅ Relative path
        options: dio.Options(
          responseType: dio.ResponseType.bytes, // ✅ Important: get bytes, not JSON
          headers: {
            'accept': 'application/octet-stream',
          },
        ),
      );

      if (response.statusCode == 200) {
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/$fileName';

        final file = File(filePath);
        await file.writeAsBytes(response.data); // ✅ response.data is already bytes

        return filePath; // Return saved file path
      } else {
        final responseBody = response.data;
        throw Exception('Failed to download file: ${responseBody['message']}');
      }
    } catch (e) {
      print('Error downloading file: $e');
      throw Exception('Error downloading file: $e');
    }
  }


  Future<Uint8List> getFileBytes(String fileName) async {
    try {
      final response = await _dio.get(
        '/Files/download/$fileName', // ✅ Relative path
        options: dio.Options(
          responseType: dio.ResponseType.bytes, // ✅ Important: receive raw bytes
          headers: {
            'Accept': 'application/octet-stream',
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data; // ✅ Already Uint8List
      } else {
        throw Exception('❌ Failed to fetch file bytes for $fileName. StatusCode: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching file bytes: $e');
      throw Exception('Error fetching file bytes: $e');
    }
  }

  Future<void> deleteFile(String fileName) async {
    try {
      final response = await _dio.delete(
        '/Files/deleteFile/$fileName', // ✅ Relative path
        options: dio.Options(
          headers: {
            'accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final responseBody = response.data;
        print('File deleted successfully: ${responseBody['message']}');
      } else {
        final responseBody = response.data;
        throw Exception('Failed to delete file: ${responseBody['message']}');
      }
    } catch (e) {
      print('Error deleting file: $e');
      throw Exception('Error deleting file: $e');
    }
  }

  //File upload for web
  Future<String> uploadJointureWeb(html.File file) async {
    try {
      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);
      await reader.onLoadEnd.first;

      if (reader.result == null) {
        throw Exception('Failed to read file data');
      }

      final fileBytes = reader.result as List<int>;

      final mimeType = lookupMimeType(file.name) ?? 'application/octet-stream';
      final mimeTypeParts = mimeType.split('/');

      final formData = dio.FormData.fromMap({
        'file': dio.MultipartFile.fromBytes(
          fileBytes,
          filename: file.name,
          contentType: MediaType(mimeTypeParts[0], mimeTypeParts[1]), // ✅ fixed
        ),
      });

      final response = await _dio.post(
        '/Files/upload',
        data: formData,
        options: dio.Options(
          headers: {
            'accept': '*/*',
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data['fileName'];
      } else {
        throw Exception('Failed to upload file. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error uploading file: $e');
      throw Exception('Error uploading file: $e');
    }
  }
  Future<String> uploadJointure(File file) async {
    try {
      final fileName = file.path.split('/').last;
      final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
      final mimeTypeParts = mimeType.split('/');

      final formData = dio.FormData.fromMap({
        'file': await dio.MultipartFile.fromFile(
          file.path,
          filename: fileName,
          contentType: MediaType(mimeTypeParts[0], mimeTypeParts[1]),
        ),
      });

      final response = await _dio.post(
        '/Files/upload',
        data: formData,
        options: dio.Options(
          headers: {
            'accept': '*/*',
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data['fileName'];
      } else {
        throw Exception('Failed to upload file. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error uploading jointure: $e');
      throw Exception('Error uploading jointure: $e');
    }
  }

  Future<List<Mission>> getPlanifiedMissions(
      List<int> userIds,
      List<int> boutiqueIds,
      DateTime planifiedAt,
      ) async {
    try {
      final String formattedDate = planifiedAt.toIso8601String();

      final response = await _dio.post(
        '/Missions/getMissionsForAreaManager', // ✅ use your actual relative path if known
        data: {
          'userIds': userIds,
          'boutiqueIds': boutiqueIds,
          'planifiedAt': formattedDate,
        },
        options: dio.Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        List<dynamic> body = response.data;
        return body.map((dynamic item) => Mission.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load missions. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching missions: $e');
      throw Exception('Error fetching missions: $e');
    }
  }


  Future<Mission> getMissionDetails(int missionId) async {
    try {
      final response = await _dio.get(
        '/Missions/$missionId', // ✅ Use relative path only
        options: dio.Options(
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
          },
        ),
      );

      if (response.statusCode == 200) {
        return Mission.fromJson(response.data); // ✅ Already parsed
      } else {
        throw Exception('Failed to load mission details. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching mission details: $e');
      throw Exception('Error fetching mission details: $e');
    }
  }


  Future<QuestionMission> getQuestionDetails(int questionId) async {
    try {
      final response = await _dio.get(
        '/MissionQuestions/$questionId', // ✅ Relative path
        options: dio.Options(
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
          },
        ),
      );

      if (response.statusCode == 200) {
        return QuestionMission.fromJson(response.data); // ✅ Already parsed by Dio
      } else {
        throw Exception('Failed to load question details. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching question details: $e');
      throw Exception('Error fetching question details: $e');
    }
  }


  Future<List<ActionM>> getActions() async {
    try {
      final response = await _dio.get(
        '/ActionMs?description=Tous&code=Tous&responsable=Tous&mail=Tous', // ✅ Make sure this is the correct relative path from your API
        options: dio.Options(
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
          },
        ),
      );

      if (response.statusCode == 200) {
        List<dynamic> body = response.data; // ✅ No need to jsonDecode manually
        return body.map((dynamic item) => ActionM.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load actions. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching actions: $e');
      throw Exception('Error fetching actions: $e');
    }
  }


  Future<void> updateMissionQuestion(int questionId, questionAnswerDto updatedQuestion, BuildContext context) async {
    try {
      final response = await _dio.put(
        '/MissionQuestions/$questionId', // ✅ Relative API path
        data: updatedQuestion.toJson(), // ✅ No need to manually jsonEncode
        options: dio.Options(
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
          },
        ),
      );

      if (response.statusCode == 200) {
        // Successfully updated
        print('✅ Mission question updated successfully.');
      } else {
        // If status != 200, handle error
        final responseBody = response.data;
        final errorMessage = responseBody['message'] ?? 'An error occurred';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
        throw Exception('Écrire un commentaire.');
      }
    } catch (e) {
      print('Exception: $e');
      throw Exception('Failed to update the mission question');
    }
  }


  Future<void> updateMission(int missionId, Mission updatedMission, int status) async {
    try {
      updatedMission.status = status; // ✅ Update status before sending

      final response = await _dio.put(
        '/Missions/$missionId', // ✅ Relative path
        data: updatedMission.toJson(),
        options: dio.Options(
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
          },
        ),
      );

      if (response.statusCode == 204) {
        // ✅ Successfully updated
        print('✅ Mission updated successfully.');
      } else if (response.statusCode == 400) {
        throw Exception('Vous devez répondre à toutes les questions.');
      } else {
        throw Exception('Une erreur est survenue.');
      }
    } catch (e) {
      print('Error updating mission: $e');
      throw Exception('Failed to update mission: $e');
    }
  }


  Future<List<BoutiqueModel>> getBoutiques() async {
    try {
      String? userIdString;
      int? userId;

      if (kIsWeb) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        userIdString = prefs.getString('currentUserId');
      } else {
        final _storage = FlutterSecureStorage();
        userIdString = await _storage.read(key: 'currentUserId');
      }

      if (userIdString != null) {
        userId = int.tryParse(userIdString);
        if (userId == null) {
          print('Failed to parse userIdString to int');
          throw Exception('Invalid user ID');
        }
      } else {
        print('userIdString is null');
        throw Exception('User ID not found');
      }

      final List<int> userIdArray = [userId];

      final response = await _dio.post(
        '/Boutiques/getBoutiquesByUserIDs', // ✅ Relative API path
        data: userIdArray, // ✅ Pass list directly
        options: dio.Options(
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
          },
        ),
      );

      if (response.statusCode == 200) {
        List<dynamic> body = response.data;
        return body.map((dynamic item) => BoutiqueModel.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load boutiques. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading boutiques: $e');
      throw Exception('Error loading boutiques: $e');
    }
  }

  Future<List<Mission>> getAllNotPlanifiedMissions() async {
    try {
      String? userIdString;
      int? userId;

      if (kIsWeb) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        userIdString = prefs.getString('currentUserId');
      } else {
        final _storage = FlutterSecureStorage();
        userIdString = await _storage.read(key: 'currentUserId');
      }

      if (userIdString != null) {
        userId = int.tryParse(userIdString);
        if (userId == null) {
          print('Failed to parse userIdString to int');
          throw Exception('Invalid user ID');
        }
      } else {
        print('userIdString is null');
        throw Exception('User ID not found');
      }

      final response = await _dio.get(
        '/Missions/GetAllNotPlanifiedMissions/$userId', // ✅ Relative API path
        options: dio.Options(
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
          },
        ),
      );

      if (response.statusCode == 200) {
        List<dynamic> body = response.data;
        return body.map((dynamic item) => Mission.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load missions. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading not planified missions: $e');
      throw Exception('Error loading not planified missions: $e');
    }
  }


  Future<void> addMission(Mission mission, BuildContext context) async {
    try {
      final response = await _dio.post(
        '/Missions', // ✅ Relative path
        data: mission.toJson(),
        options: dio.Options(
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
          },
        ),
      );

      if (response.statusCode == 200) {
        final responseBody = response.data;

        if (responseBody['success'] == true) {
          // ✅ Success Snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: AwesomeSnackbarContent(
                title: 'Succès!',
                message: responseBody['message'] ?? 'Mission ajoutée avec succès.',
                contentType: ContentType.success,
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
          );
        } else {
          // ❌ API indicated failure
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: AwesomeSnackbarContent(
                title: 'Erreur!',
                message: responseBody['message'] ?? 'Échec de l\'ajout de la mission.',
                contentType: ContentType.failure,
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
          );
        }
      } else {
        // ❌ Server error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: AwesomeSnackbarContent(
              title: 'Erreur!',
              message: 'Erreur serveur: ${response.statusCode}',
              contentType: ContentType.failure,
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
        );
      }
    } catch (e) {
      print('Unexpected error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: AwesomeSnackbarContent(
            title: 'Erreur!',
            message: 'Une erreur inattendue s\'est produite: $e',
            contentType: ContentType.failure,
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      );
    }
  }



  //image upload on web
  Future<String> uploadFileWeb(html.File file) async {
    try {
      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);
      await reader.onLoad.first;

      if (reader.result == null) {
        throw Exception('Failed to read file data.');
      }

      Uint8List fileBytes;
      if (reader.result is ByteBuffer) {
        fileBytes = Uint8List.view(reader.result as ByteBuffer);
      } else if (reader.result is Uint8List) {
        fileBytes = reader.result as Uint8List;
      } else {
        throw Exception('Unsupported file format: ${reader.result.runtimeType}');
      }

      final formData = dio.FormData.fromMap({
        'image': dio.MultipartFile.fromBytes(
          fileBytes,
          filename: file.name,
        ),
      });

      final response = await _dio.post(
        '/Files/webImageUpload', // ✅ Only relative path
        data: formData,
        options: dio.Options(
          headers: {
            'accept': '*/*',
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        return responseData['file']; // ✅ Correct!
      } else {
        throw Exception('❌ Upload failed with status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error uploading file (Web): $e');
      throw Exception('Error uploading file (Web): $e');
    }
  }


  Future<String> uploadFile(File file) async {
    try {
      final fileName = file.path.split('/').last;

      final fileBytes = await file.readAsBytes();

      final formData = dio.FormData.fromMap({
        'image': dio.MultipartFile.fromBytes(
          fileBytes,
          filename: fileName,
        ),
      });

      final response = await _dio.post(
        '/Files', // ✅ Only relative path
        data: formData,
        options: dio.Options(
          headers: {
            'accept': '*/*',
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        return responseData['file']; // ✅ Correct field returned
      } else {
        throw Exception('❌ Failed to upload file. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error uploading file: $e');
      throw Exception('Error uploading file: $e');
    }
  }

  Future<File> getImage(String filename) async {
    try {
      final response = await _dio.get(
        '/Files/getImage/$filename', // ✅ Only relative API path
        options: dio.Options(
          responseType: dio.ResponseType.bytes, // ✅ Important: receive raw bytes
          headers: {
            'accept': '*/*', // Accept all image types
          },
        ),
      );

      if (response.statusCode == 200) {
        final bytes = response.data as List<int>;

        // ✅ Create temporary file
        final tempDir = await Directory.systemTemp.createTemp('img_');
        final filePath = '${tempDir.path}/$filename';
        final file = File(filePath);

        await file.writeAsBytes(bytes, flush: true);

        print('✅ Image file saved to $filePath');
        return file;
      } else {
        final msg = '❌ Failed to retrieve image: ${response.statusCode}';
        print(msg);
        throw Exception(msg);
      }
    } catch (e) {
      print('Error retrieving image: $e');
      throw Exception('Error retrieving image: $e');
    }
  }

  Future<Uint8List?> getImageBytes(String filename) async {
    try {
      final response = await _dio.get(
        '/Files/getImage/$filename', // ✅ Relative path only
        options: dio.Options(
          responseType: dio.ResponseType.bytes, // ✅ Important for raw bytes
          headers: {
            'accept': '*/*', // Accept any image MIME type
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data as Uint8List;
      } else {
        print('❌ Failed to fetch image bytes: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Error fetching image bytes: $e');
      return null;
    }
  }

  Future<List<QuestionMission>> getQuestionsForSousMission(int sousMissionId) async {
    try {
      final response = await _dio.get(
        '/MissionQuestions',
        queryParameters: {
          'idSousMission': sousMissionId, // ✅ Properly send as query param
        },
        options: dio.Options(
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
          },
        ),
      );

      if (response.statusCode == 200) {
        List<dynamic> body = response.data;
        return body.map((item) => QuestionMission.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load questions for sousMission');
      }
    } catch (e) {
      print('❌ Error fetching questions for sousMission: $e');
      throw Exception('Error fetching questions for sousMission: $e');
    }
  }

  Future<List<ChoixReponseQuestion>> getAllChoixReponse(int modeleReponseID) async {
    try {
      final response = await _dio.get(
        '/ChoixReponseQuestion/$modeleReponseID', // ✅ Correct relative path
        options: dio.Options(
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
          },
        ),
      );

      if (response.statusCode == 200) {
        List<dynamic> body = response.data;
        return body.map((item) => ChoixReponseQuestion.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load choix reponse questions');
      }
    } catch (e) {
      print('❌ Error fetching choix reponse questions: $e');
      throw Exception('Error fetching choix reponse questions: $e');
    }
  }




}

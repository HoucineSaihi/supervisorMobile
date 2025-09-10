import 'dart:convert';
import 'dart:io';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supervisormobile/features/calendar/models/boutiqueModel.dart';
import 'package:supervisormobile/features/calendar/models/choixReponseQuestion.dart';
import 'package:supervisormobile/features/calendar/models/missionModel.dart';
import 'package:supervisormobile/features/calendar/models/missionResponseModel.dart';
import 'package:supervisormobile/features/calendar/models/paginationModel.dart';
import 'package:supervisormobile/features/calendar/models/questionMissionModel.dart';
import 'package:supervisormobile/features/calendar/models/actionsModel.dart'; // Import the ActionM model
import 'package:mime/mime.dart';
import 'package:supervisormobile/services/DioService.dart';

import '../../../dtos/questions/questionAnswerDto.dart';

class MissionService {
  final dio.Dio _dio = DioService.dio; // ✅ Correct way: reuse existing Dio instance

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
    apiUrl = '/Missions/getMissionsForAreaManager';
    missionDetailsUrl = '/Missions/missionAllQuestion';
    actionsUrl = '/ActionMs?description=Tous&code=Tous&responsable=Tous&mail=Tous';
  }
  Future<void> deleteImage(String fileName) async {
    try {
      final response = await _dio.delete('/Files/deleteImage/$fileName'); // ✅ use _dio

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
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName';

      final response = await _dio.get(
        '/Files/download/$fileName',
        options: dio.Options(
          responseType: dio.ResponseType.bytes,
          headers: {
            'accept': 'application/octet-stream',
          },
        ),
      );

      if (response.statusCode == 200) {
        final file = File(filePath);
        await file.writeAsBytes(response.data);
        return filePath;
      } else {
        final responseBody = response.data;
        throw Exception('Failed to download file: ${responseBody['message']}');
      }
    } catch (e) {
      print('Error downloading file: $e');
      throw Exception('Error downloading file: $e');
    }
  }



  Future<void> deleteFile(String fileName) async {
    try {
      final response = await _dio.delete(
        '/Files/deleteFile/$fileName', // ✅ Only relative path
        options: dio.Options(
          headers: {
            'accept': 'application/json', // ✅ Specify accept header
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



  Future<String> uploadJointure(File file) async {
    try {
      final formData = dio.FormData.fromMap({
        'file': await dio.MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
          // ✅ No contentType manually set!
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
        final responseData = response.data;
        return responseData['fileName'];
      } else {
        throw Exception('Failed to upload file. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error uploading file: $e');
      throw Exception('Error uploading file: $e');
    }
  }

  Future<MissionResponseModel> getPlanifiedMissions(
      List<int> userIds,
      List<int> boutiqueIds,
      DateTime planifiedAt, {
        int pageNumber = 1,
        int pageSize = 50,
        dio.CancelToken? cancelToken,
      }) async {
    try {
      final String formattedDate = planifiedAt.toIso8601String();

      print('🚀 MissionService: Fetching missions for date: $formattedDate');
      print('📋 MissionService: Request params - userIds: $userIds, boutiqueIds: $boutiqueIds, pageNumber: $pageNumber, pageSize: $pageSize');

      final response = await _dio.post(
        '/Missions/getMissionsForAreaManager', // ✅ use your actual relative path if known
        data: {
          'userIds': userIds,
          'boutiqueIds': boutiqueIds,
          'planifiedAt': formattedDate,
          'PageSize': pageSize,
          'PageNumber': pageNumber,
        },
        options: dio.Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
        cancelToken: cancelToken, // ✅ Add cancel token support
      );

      print('✅ MissionService: API call successful. Status: ${response.statusCode}');
      print('📄 MissionService: Raw response data: ${response.data}');

      if (response.statusCode == 200) {
        return MissionResponseModel.fromJson(response.data);
      } else {
        throw Exception('Failed to load missions. Status code: ${response.statusCode}');
      }
    } catch (e) {
      // Handle cancellation specifically
      if (e is dio.DioException && e.type == dio.DioExceptionType.cancel) {
        print('🚫 MissionService: Request was cancelled');
        throw Exception('Request was cancelled');
      }
      
      // Handle 404 error gracefully (no missions found)
      if (e is dio.DioException && e.response?.statusCode == 404) {
        print('📭 No missions found for the selected date');
        // Return empty MissionResponseModel
        return MissionResponseModel(
          data: [],
          pagination: PaginationModel(
            pageNumber: pageNumber,
            pageSize: pageSize,
            totalCount: 0,
            totalPages: 0,
            hasNextPage: false,
            hasPreviousPage: false,
            isFirstPage: true,
            isLastPage: true,
            currentPageSize: 0,
            remainingItems: 0,
          ),
        );
      }
      
      print('❌ MissionService: Error fetching missions: $e');
      throw Exception('Error fetching missions: $e');
    }
  }

  Future<MissionResponseModel> getPlanifiedMissionsWithPagination(
      List<int> userIds, List<int> boutiqueIds, DateTime planifiedAt, {int pageNumber = 1, int pageSize = 20}) async {
    try {
      final String formattedDate = planifiedAt.toIso8601String();

      print('🔍 MissionService.getPlanifiedMissionsWithPagination: Request parameters');
      print('📊 PageSize: $pageSize, PageNumber: $pageNumber');
      print('📄 UserIds: $userIds, BoutiqueIds: $boutiqueIds, Date: $formattedDate');

      final response = await _dio.post(
        apiUrl,
        data: {
          'userIds': userIds,
          'boutiqueIds': boutiqueIds,
          'planifiedAt': formattedDate,
          'PageSize': pageSize,
          'PageNumber': pageNumber,
        },
        options: dio.Options(
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
          },
        ),
      );

      print('✅ MissionService.getPlanifiedMissionsWithPagination: API call successful');
      print('📄 MissionService.getPlanifiedMissionsWithPagination: Raw response data: ${response.data}');

      if (response.statusCode == 200) {
        return MissionResponseModel.fromJson(response.data);
      } else {
        throw Exception('Failed to load missions. Status code: ${response.statusCode}');
      }
    } catch (e) {
      // Handle DioException specifically
      if (e is dio.DioException) {
        // Handle 404 error gracefully (no missions found)
        if (e.response?.statusCode == 404) {
          print('📭 No missions found for the selected date (pagination)');
          // Return empty MissionResponseModel
          return MissionResponseModel(
            data: [],
            pagination: PaginationModel(
              pageNumber: pageNumber,
              pageSize: pageSize,
              totalCount: 0,
              totalPages: 0,
              hasNextPage: false,
              hasPreviousPage: false,
              isFirstPage: true,
              isLastPage: true,
              currentPageSize: 0,
              remainingItems: 0,
            ),
          );
        }
        
        // Handle other Dio errors
        print('❌ Dio error fetching missions (pagination): ${e.message}');
        throw Exception('Error fetching missions: ${e.message}');
      }
      
      // Handle other errors
      print('❌ MissionService.getPlanifiedMissionsWithPagination: Error fetching missions: $e');
      throw Exception('Error fetching missions: $e');
    }
  }

  Future<Mission> getMissionDetails(int missionId) async {
    try {
      final response = await _dio.get(
        '$missionDetailsUrl/$missionId', // ✅ assuming missionDetailsUrl is a relative path or properly set
        options: dio.Options(
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
          },
        ),
      );

      if (response.statusCode == 200) {
        final body = response.data; // ✅ Already parsed
        print(body);
        return Mission.fromJson(body); // ✅ Directly create the Mission object
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
        '/MissionQuestions/$questionId', // ✅ Only relative path (no need to repeat BASE_URL manually)
        options: dio.Options(
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
          },
        ),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = response.data; // ✅ Already parsed by Dio
        return QuestionMission.fromJson(json);
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
        actionsUrl, // ✅ Assuming actionsUrl is correctly a relative path or handled properly
        options: dio.Options(
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
          },
        ),
      );

      if (response.statusCode == 200) {
        List<dynamic> body = response.data; // ✅ Already parsed automatically
        List<ActionM> actions = body.map((dynamic item) => ActionM.fromJson(item)).toList();
        return actions;
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
        '/MissionQuestions/$questionId', // ✅ Only relative path
        data: updatedQuestion.toJson(), // ✅ No need to jsonEncode manually
        options: dio.Options(
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
          },
        ),
      );

      if (response.statusCode == 200) {
        // ✅ Successfully updated
      } else {
        // ✅ Parse error message
        final responseBody = response.data;
        final errorMessage = responseBody['message'] ?? 'An error occurred';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      print('Exception: $e');
      throw Exception('Failed to update the mission question');
    }
  }

  Future<void> updateMission(int missionId, Mission updatedMission, int status) async {
    try {
      updatedMission.status = status; // ✅ Update the status field

      final response = await _dio.put(
        '/Missions/$missionId', // ✅ Only relative path
        data: updatedMission.toJson(), // ✅ Dio will handle JSON encoding
        options: dio.Options(
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
          },
        ),
      );

      if (response.statusCode == 204) {
        // ✅ Successfully updated
      } else if (response.statusCode == 400) {
        // ✅ Specific error handling
        throw Exception('Vous devez répondre à toutes les questions.');
      } else {
        throw Exception('Une erreur est survenue.');
      }
    } catch (e) {
      print('Exception: $e');
      throw Exception('Failed to update mission: $e');
    }
  }

  Future<List<BoutiqueModel>> getBoutiques() async {
    try {
      String? userIdString = await _storage.read(key: 'currentUserId');
      _currentUserID = userIdString != null ? int.tryParse(userIdString) ?? 0 : 0;

      List<int> userIdArray = [_currentUserID]; // ✅ simpler array creation

      final response = await _dio.post(
        '/Boutiques/getBoutiquesByUserIDs', // ✅ Only relative path
        data: userIdArray, // ✅ Dio automatically encodes this to JSON
        options: dio.Options(
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
          },
        ),
      );

      if (response.statusCode == 200) {
        List<dynamic> body = response.data; // ✅ Already parsed JSON
        List<BoutiqueModel> boutiques = body.map((dynamic item) => BoutiqueModel.fromJson(item)).toList();
        return boutiques;
      } else {
        throw Exception('Failed to load boutiques. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching boutiques: $e');
      throw Exception('Error fetching boutiques: $e');
    }
  }

  Future<List<Mission>> getAllNotPlanifiedMissions() async {
    try {
      String? userIdString = await _storage.read(key: 'currentUserId');
      _currentUserID = userIdString != null ? int.tryParse(userIdString) ?? 0 : 0;

      final response = await _dio.get(
        '/Missions/GetAllNotPlanifiedMissions/$_currentUserID', // ✅ Only relative path
        options: dio.Options(
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
          },
        ),
      );

      if (response.statusCode == 200) {
        List<dynamic> body = response.data; // ✅ Already parsed automatically
        List<Mission> missions = body.map((dynamic item) => Mission.fromJson(item)).toList();
        return missions;
      } else {
        throw Exception('Failed to load missions. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching missions: $e');
      throw Exception('Error fetching missions: $e');
    }
  }

  Future<void> addMission(Mission mission, BuildContext context) async {
    try {
      final response = await _dio.post(
        '/Missions', // ✅ Only relative path
        data: mission.toJson(), // ✅ No need to jsonEncode manually
        options: dio.Options(
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
          },
        ),
      );

      if (response.statusCode == 200) {
        final responseBody = response.data; // ✅ Already parsed JSON

        if (responseBody['success'] == true) {
          // ✅ Success
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
          // ❌ Failure (success == false)
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
        // ❌ Server returned error status
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
      // ❌ Catch unexpected errors
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


  Future<String> uploadFile(File file) async {
    try {
      final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
      final mimeTypeParts = mimeType.split('/');

      final formData = dio.FormData.fromMap({
        'image': await dio.MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
          // ✅ No need to specify contentType manually (Dio handles it)
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
        return responseData['file']; // ✅ Return the filename from response
      } else {
        throw Exception('Failed to upload file. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error uploading file: $e');
      throw Exception('Error uploading file: $e');
    }
  }

  Future<File> getImage(String filename) async {
    try {
      final response = await _dio.get(
        '/Files/getImage/$filename', // ✅ Only relative path
        options: dio.Options(
          responseType: dio.ResponseType.bytes, // ✅ Important: get the bytes directly
          headers: {
            'accept': 'image/jpeg', // ✅ Accepting images
          },
        ),
      );

      if (response.statusCode == 200) {
        final bytes = response.data; // ✅ Bytes are ready

        // Create a temporary directory and file
        final tempDir = await Directory.systemTemp.createTemp();
        final file = File('${tempDir.path}/$filename');

        // Write the bytes to the file
        await file.writeAsBytes(bytes);

        return file;
      } else {
        throw Exception('Failed to retrieve image: ${response.statusMessage}');
      }
    } catch (e) {
      print('Error fetching image: $e');
      throw Exception('Error fetching image: $e');
    }
  }

  Future<List<QuestionMission>> getQuestionsForSousMission(int sousMissionId) async {
    try {
      final response = await _dio.get(
        '/MissionQuestions', // ✅ Relative path only
        queryParameters: {
          'idSousMission': sousMissionId, // ✅ Clean way to add query parameters with Dio
        },
        options: dio.Options(
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
          },
        ),
      );

      if (response.statusCode == 200) {
        List<dynamic> body = response.data; // ✅ Already parsed JSON
        List<QuestionMission> questions = body.map((dynamic item) => QuestionMission.fromJson(item)).toList();
        return questions;
      } else {
        throw Exception('Failed to load questions for sousMission. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching questions: $e');
      throw Exception('Error fetching questions: $e');
    }
  }

  Future<List<ChoixReponseQuestion>> getAllChoixReponse(int modeleReponseID) async {
    try {
      final response = await _dio.get(
        '/ChoixReponseQuestion/$modeleReponseID', // ✅ Only relative path
        options: dio.Options(
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
          },
        ),
      );

      if (response.statusCode == 200) {
        List<dynamic> body = response.data; // ✅ Already parsed
        List<ChoixReponseQuestion> allChoix = body.map((dynamic item) => ChoixReponseQuestion.fromJson(item)).toList();
        return allChoix;
      } else {
        throw Exception('Failed to load choix reponse. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching choix reponse: $e');
      throw Exception('Error fetching choix reponse: $e');
    }
  }




}

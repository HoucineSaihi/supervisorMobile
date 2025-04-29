import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:supervisormobile/features/Profile/models/boutique_model.dart';
import 'package:supervisormobile/features/authentification/services/login_service.dart';
import 'package:supervisormobile/features/calendar/models/Problem.dart';
import 'package:supervisormobile/features/incidents/models/AllProblemsLazy.dart';
import 'package:supervisormobile/features/incidents/models/Coefficient.dart';
import 'package:dio/dio.dart' as dio;
import 'package:supervisormobile/services/DioService.dart';

class IncidentService {
  static final dio.Dio _dio = DioService.dio;


  final String _problemBaseUrl = '/Problem';
  final String _coefficientBaseUrl = '/Coefficient';
  final String _paramsBaseUrl = '/api/Parameters';




  final _storage = FlutterSecureStorage();
  int _currentUserID = 0;

  Future<List<Coefficient>> getAllCoefficients() async {
    try {
      final response = await _dio.get(
        '/Coefficient', // ✅ Only relative path, no base URL needed
      );

      if (response.statusCode == 200) {
        List<dynamic> jsonResponse = response.data; // ✅ No manual jsonDecode
        return jsonResponse.map((data) => Coefficient.fromJson(data)).toList();
      } else {
        throw Exception('Failed to load coefficients. Status code: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching coefficients: $error');
      throw Exception('An error occurred while fetching coefficients: $error');
    }
  }

  Future<void> _loadAuthToken() async {
    // Retrieve the user ID from secure storage
    String? userIdString = await _storage.read(key: 'currentUserId');
    _currentUserID = userIdString != null ? int.tryParse(userIdString) ?? 0 : 0;

  }

  Future<List<dynamic>> getAllowedStatus() async {
    try {
      final response = await _dio.get(
        '/Parameters/GetAllowedStatus', // ✅ Only relative path
      );

      if (response.statusCode == 200) {
        final List<dynamic> statuses = response.data; // ✅ No manual jsonDecode
        return statuses;
      } else {
        throw Exception('Failed to load allowed statuses. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching allowed statuses: $e');
      throw Exception('Error fetching allowed statuses: $e');
    }
  }





  Future<AllProblemsLazy> getFilteredProblems(
      int? boutiqueId,
      int? coefId,
      int? origin,
      int? statut,
      int? first,
      ) async {
    try {
      final SecureStorageService secureStorage = SecureStorageService();
      String? userIdString = await secureStorage.getLoginData().then((data) => data['currentUserId']);
      int? currentUserID = userIdString != null ? int.tryParse(userIdString) : null;

      final Map<String, dynamic> requestBody = {
        "requester_id": currentUserID,
        "boutique_id": boutiqueId,
        "coef_id": coefId,
        "origin": origin,
        "statut": statut,
        "first": first,
        "rows": 10,
      }..removeWhere((key, value) => value == null);

      print("Request Body: $requestBody");

      final response = await _dio.post(
        '/Problem/filtered', // ✅ Relative path only
        data: requestBody, // ✅ No need to jsonEncode
        options: dio.Options(
          headers: {"Content-Type": "application/json"},
        ),
      );

      print("API Response: ${response.data}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = response.data; // ✅ Already parsed

        if (responseData["problems"] is List && responseData["problems"].isNotEmpty) {
          print("First problem item: ${responseData["problems"].first}");
        } else {
          print("Problems list is empty or invalid.");
        }

        if (responseData["problems"] is List) {
          return AllProblemsLazy(
            problems: (responseData["problems"] as List<dynamic>)
                .map((incident) => Problem.fromJson(incident as Map<String, dynamic>))
                .toList(),
            totalRecords: responseData["totalRecords"] ?? 0,
          );
        } else {
          throw Exception("Invalid API response: 'problems' is not a list.");
        }
      } else {
        throw Exception("Failed to load filtered problems: ${response.statusCode}");
      }
    } catch (e) {
      print("Error occurred: $e");
      throw Exception("Error occurred: $e");
    }
  }






  Future<void> cloturerIncident(int questionId) async {
    try {
      final response = await _dio.put(
        '/Problem/updateClouture/$questionId', // ✅ Relative path
        options: dio.Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode != 204) {
        throw Exception('Failed to update clouture. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating clouture: $e');
      throw Exception('Error updating clouture: $e');
    }
  }




  // Fetch problem by ID
  Future<Problem?> getProblemById(int id) async {
    try {
      print('Making API call to: /Problem/$id');

      final response = await _dio.get(
        '/Problem/$id', // ✅ Relative path
      );

      if (response.statusCode == 200) {
        print('Response: ${response.data}');
        return Problem.fromJson(response.data); // ✅ No need to jsonDecode
      } else {
        print('Error: ${response.statusCode}');
        throw Exception('Failed to load problem. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching problem: $e');
      throw Exception('Failed to load problem: $e');
    }
  }




  Future<List<BoutiqueModel>> getBoutiques() async {
    try {
      final SecureStorageService secureStorage = SecureStorageService();

      // Fetch user ID from secure storage
      String? userIdString = await secureStorage.getLoginData().then((data) => data['currentUserId']);
      int currentUserID = userIdString != null ? int.tryParse(userIdString) ?? 0 : 0;

      List<int> userIdArray = [currentUserID];

      final response = await _dio.post(
        '/Boutiques/getBoutiquesByUserIDs', // ✅ Only relative path
        data: userIdArray, // ✅ Send data directly (Dio will handle JSON encoding)
        options: dio.Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        List<dynamic> body = response.data; // ✅ No need to manually decode
        return body.map((dynamic item) => BoutiqueModel.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load boutiques. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching boutiques: $e');
      throw Exception('Error fetching boutiques: $e');
    }
  }



  Future<Problem> addProblem(Problem problem) async {
    try {
      final response = await _dio.post(
        '/Problem', // ✅ Only relative path
        data: problem.toJson(), // ✅ No need to jsonEncode manually
        options: dio.Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 201) {
        print("gooooooooooood");
        return Problem.fromJson(response.data); // ✅ No need to decode manually
      } else {
        throw Exception(
            'Failed to add problem. Status code: ${response.statusCode}, Response: ${response.data}');
      }
    } catch (error) {
      print('Error adding problem: $error');
      throw Exception('An error occurred while adding the problem: $error');
    }
  }

}




import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:supervisormobile/features/Profile/models/boutique_model.dart';
import 'package:supervisormobile/features/calendar/models/Problem.dart';
import 'package:supervisormobile/features/incidents/models/AllProblemsLazy.dart';
import 'package:supervisormobile/features/incidents/models/Coefficient.dart';

import '../../../Interceptors/ClientIdInterceptor.dart';
import '../../../services/DioService.dart';
import '../../../utils/Helpers/secure_storage_data.dart';

class IncidentService {

  static final Dio dio =DioService.dio;// Adjust your base URL

  final String _problemBaseUrl = '/Problem';

  final String _coefficientBaseUrl = '/Coefficient';

  final String _paramsBaseUrl = '/Parameters';


  final _storage = FlutterSecureStorage();
  int _currentUserID = 0;

  Future<List<Coefficient>> getAllCoefficients() async {
    try {
      final response = await DioService.dio.get(_coefficientBaseUrl); // ✅ using Dio now

      if (response.statusCode == 200) {
        List<dynamic> jsonResponse = response.data; // ✅ No need to decode manually, Dio handles it
        return jsonResponse.map((data) => Coefficient.fromJson(data)).toList();
      } else {
        throw Exception('Failed to load coefficients. Status code: ${response.statusCode}');
      }
    } catch (error) {
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
      final response = await DioService.dio.get('$_paramsBaseUrl/GetAllowedStatus'); // ✅ Using Dio now

      if (response.statusCode == 200) {
        final List<dynamic> statuses = response.data; // ✅ No need to decode manually
        return statuses;
      } else {
        throw Exception('Failed to load allowed statuses. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
      rethrow; // Let the caller handle the error
    }
  }





  Future<AllProblemsLazy> getFilteredProblems(
      int? boutiqueId,
      int? coefId,
      int? origin,
      int? statut,
      int? first) async {

    String? userIdString = await _storage.read(key: 'currentUserId');
    int? currentUserID = userIdString != null ? int.tryParse(userIdString) : null;

    final Map<String, dynamic> requestBody = {
      "requester_id": currentUserID,
      "boutique_id": boutiqueId,
      "coef_id": coefId,
      "origin": origin,
      "statut": statut,
      "first": first,
      "rows": 10
    }..removeWhere((key, value) => value == null);

    print(requestBody);

    try {
      final response = await DioService.dio.post(
        '$_problemBaseUrl/filtered',
        data: requestBody, // ✅ No need to jsonEncode manually, Dio handles it
      );

      print("API Response: ${response.data}"); // Debugging line

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = response.data;

        // Debugging: Check first problem item
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
      final response = await DioService.dio.put(
        '$_problemBaseUrl/updateClouture/$questionId',
      );

      if (response.statusCode != 204) {
        throw Exception('Failed to update clouture');
      }
    } catch (e) {
      print('Error occurred while updating clouture: $e');
      throw Exception('Error occurred while updating clouture: $e');
    }
  }



  // Fetch problem by ID
  Future<Problem?> getProblemById(int id) async {
    try {
      final response = await DioService.dio.get('$_problemBaseUrl/$id');

      print('Making API call to: $_problemBaseUrl/$id');

      if (response.statusCode == 200) {
        print('Response: ${response.data}');
        return Problem.fromJson(response.data); // ✅ Dio auto-decodes JSON
      } else {
        print('Error: ${response.statusCode}');
        throw Exception('Failed to load problem');
      }
    } catch (e) {
      print('Error: $e');
      throw Exception('Failed to load problem: $e');
    }
  }



  Future<List<BoutiqueModel>> getBoutiques() async {
    String? userIdString = await _storage.read(key: 'currentUserId');
    _currentUserID = userIdString != null ? int.tryParse(userIdString) ?? 0 : 0;

    List<int> userIdArray = [_currentUserID]; // ✅ shorter way to initialize

    final String boutiquesUrl = '/Boutiques/getBoutiquesByUserIDs';

    try {
      final response = await DioService.dio.post(
        boutiquesUrl,
        data: userIdArray, // ✅ Directly send list, Dio will jsonEncode automatically
      );

      if (response.statusCode == 200) {
        List<dynamic> body = response.data; // ✅ No manual decoding needed
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

  Future<Problem> addProblem(Problem problem) async {
    try {
      final response = await DioService.dio.post(
        _problemBaseUrl,
        data: problem.toJson(), // ✅ No need to manually jsonEncode
      );

      if (response.statusCode == 201) {
        print("gooooooooooood");
        return Problem.fromJson(response.data); // ✅ response.data already parsed
      } else {
        throw Exception(
            'Failed to add problem. Status code: ${response.statusCode}, Response: ${response.data}');
      }
    } catch (error) {
      throw Exception('An error occurred while adding the problem: $error');
    }
  }
}




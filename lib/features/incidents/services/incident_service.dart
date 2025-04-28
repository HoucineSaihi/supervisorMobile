import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:supervisormobile/features/Profile/models/boutique_model.dart';
import 'package:supervisormobile/features/authentification/services/login_service.dart';
import 'package:supervisormobile/features/calendar/models/Problem.dart';
import 'package:supervisormobile/features/incidents/models/AllProblemsLazy.dart';
import 'package:supervisormobile/features/incidents/models/Coefficient.dart';

class IncidentService {

  static String get baseURL => "http://localhost:7000";

  final String _problemBaseUrl = '$baseURL/api/Problem';
  final String _coefficientBaseUrl = '$baseURL/api/Coefficient';
  final String _paramsBaseUrl = '$baseURL/api/Parameters';




  final _storage = FlutterSecureStorage();
  int _currentUserID = 0;

  Future<List<Coefficient>> getAllCoefficients() async {
    final uri = Uri.parse(_coefficientBaseUrl);

    try {
      // Making the GET request
      final response = await http.get(uri);

      // Check if the response is successful
      if (response.statusCode == 200) {
        List<dynamic> jsonResponse = json.decode(response.body);

        // Convert JSON to a list of Coefficient objects
        return jsonResponse.map((data) => Coefficient.fromJson(data)).toList();
      } else {
        throw Exception('Failed to load coefficients. Status code: ${response.statusCode}');
      }
    } catch (error) {
      // Handle network or other unexpected errors
      throw Exception('An error occurred while fetching coefficients: $error');
    }
  }

  Future<void> _loadAuthToken() async {
    // Retrieve the user ID from secure storage
    String? userIdString = await _storage.read(key: 'currentUserId');
    _currentUserID = userIdString != null ? int.tryParse(userIdString) ?? 0 : 0;

  }

  Future<List<dynamic>> getAllowedStatus() async {
    final Uri url = Uri.parse(_paramsBaseUrl+"/GetAllowedStatus"); // Replace with your actual API URL

    try {
      final response = await http.get(url);

      // Check if the request was successful
      if (response.statusCode == 200) {
        // Decode the JSON response
        final List<dynamic> statuses = json.decode(response.body);
        return statuses;
      } else {
        // Handle the error
        throw Exception('Failed to load allowed statuses');
      }
    } catch (e) {
      print('Error: $e');
      rethrow; // You can also handle the error gracefully here
    }
  }




  Future<AllProblemsLazy> getFilteredProblems(
      int? boutiqueId,
      int? coefId,
      int? origin,
      int? statut,
      int? first) async {

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

    try {
      final response = await http.post(
        Uri.parse("$_problemBaseUrl/filtered"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      );

      print("API Response: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

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
    // Constructing the URL for updating the clouture
    final uri = Uri.parse('$_problemBaseUrl/updateClouture/$questionId');

    // Making the PATCH request
    final response = await http.put(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to update clouture');
    }
  }



  // Fetch problem by ID
  Future<Problem?> getProblemById(int id) async {
    final url = Uri.parse('$_problemBaseUrl/$id');

    try {
      print('Making API call to: $url');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        print('Response: ${response.body}');
        return Problem.fromJson(json.decode(response.body));
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
    final SecureStorageService secureStorage = SecureStorageService();

    // Use the secure storage service to fetch the user ID
    String? userIdString = await secureStorage.getLoginData().then((data) => data['currentUserId']);
    int currentUserID = userIdString != null ? int.tryParse(userIdString) ?? 0 : 0;

    List<int> userIdArray = [currentUserID];

    final String boutiquesUrl = '${baseURL}/api/Boutiques/getBoutiquesByUserIDs';

    final response = await http.post(
      Uri.parse(boutiquesUrl),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(userIdArray),
    );

    if (response.statusCode == 200) {
      List<dynamic> body = json.decode(response.body);
      return body.map((dynamic item) => BoutiqueModel.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load boutiques');
    }
  }


  Future<Problem> addProblem(Problem problem) async {
    final uri = Uri.parse(_problemBaseUrl);

    try {
      // Make the POST request with the Problem object as JSON
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(problem.toJson()),
      );

      // Check for a successful response
      if (response.statusCode == 201) {
        // Parse the response to create a Problem object
        print("gooooooooooood");
        return Problem.fromJson(json.decode(response.body));
      } else {
        throw Exception(
            'Failed to add problem. Status code: ${response.statusCode}, Response: ${response.body}');
      }
    } catch (error) {
      throw Exception('An error occurred while adding the problem: $error');
    }
  }
}




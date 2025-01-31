import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:supervisormobile/features/Profile/models/boutique_model.dart';
import 'package:supervisormobile/features/calendar/models/Problem.dart';
import 'package:supervisormobile/features/incidents/models/Coefficient.dart';

class IncidentService {
  final String _problemBaseUrl = '${dotenv.env['BASE_URL']}/api/Problem';

  final String _coefficientBaseUrl = '${dotenv.env['BASE_URL']}/api/Coefficient';

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



  Future<List<dynamic>> getFilteredProblems(
    int? boutiqueId,
    int? coefId,
    int? cluster,
    int? origin,
    int? statut,
  ) async {
    // Retrieve current user ID from storage
    String? userIdString = await _storage.read(key: 'currentUserId');
    _currentUserID = userIdString != null ? int.tryParse(userIdString) ?? 0 : 0;



    // Build the full API URI
    final uri = Uri.parse("$_problemBaseUrl");
    print("Calling API: $uri");

    try {
      // Make the API call
      final response = await http.get(uri);


      if (response.statusCode == 200) {
        return jsonDecode(response.body); // Parse and return response
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




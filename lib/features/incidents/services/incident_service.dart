import 'dart:convert';
import 'package:http/http.dart' as http;

class IncidentService {
  final String _baseUrl = 'https://beb8-197-2-149-3.ngrok-free.app/api/MissionQuestions';

  Future<List<dynamic>> getAllRecommendationsByIdUserFiltered({
    String? mLibelle,
    String? smLibelle,
    String? qLibelle,
    int? actionId,
    String? btqLibelle,
    int? statusValidation,
    required int userId,
    DateTime? dateDb,
    DateTime? dateF,
    DateTime? dateClotDb,
    DateTime? dateClotF,
  }) async {
    // Constructing the query parameters
    final Map<String, String> queryParams = {};

    if (mLibelle != null) queryParams['mLibelle'] = mLibelle;
    if (smLibelle != null) queryParams['smLibelle'] = smLibelle;
    if (qLibelle != null) queryParams['qLibelle'] = qLibelle;
    if (actionId != null) queryParams['actionId'] = actionId.toString();
    if (btqLibelle != null) queryParams['btqLibelle'] = btqLibelle;
    if (statusValidation != null) queryParams['statusValidation'] = statusValidation.toString();
    queryParams['userId'] = userId.toString();
    if (dateDb != null) queryParams['dateDb'] = dateDb.toIso8601String();
    if (dateF != null) queryParams['dateF'] = dateF.toIso8601String();
    if (dateClotDb != null) queryParams['dateClotDb'] = dateClotDb.toIso8601String();
    if (dateClotF != null) queryParams['dateClotF'] = dateClotF.toIso8601String();

    // Constructing the full URL with query parameters
    final uri = Uri.parse('$_baseUrl/GetAllRecomndationsByIdUserFiltered')
        .replace(queryParameters: queryParams);

    // Making the GET request
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      List<dynamic> jsonResponse = json.decode(response.body);
      return jsonResponse;
    } else {
      throw Exception('Failed to load recommendations');
    }
  }

  Future<void> cloturerIncident(int questionId) async {
    // Constructing the URL for updating the clouture
    final uri = Uri.parse('$_baseUrl/updateClouture/$questionId');

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
}




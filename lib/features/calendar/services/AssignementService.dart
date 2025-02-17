import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../models/UserChecklistAssignment.dart';

class Assignementservice {

  final _storage = FlutterSecureStorage();
  final String baseURL = '${dotenv.env['BASE_URL']}';
  late final String apiUrl;
  Assignementservice() {
    apiUrl = '${dotenv.env['BASE_URL']}/api/ChecklistAssignements';

  }

  Future<List<UserChecklistAssignment>> getAssignmentsByUserId() async {
    // Get userId from storage
    String? userIdString = await _storage.read(key: 'currentUserId');
    int? userId = userIdString != null ? int.tryParse(userIdString) ?? 0 : 0;

    // Make API call
    final response = await http.get(Uri.parse('$apiUrl/get_assignements_by_user_id/$userId'));

    if (response.statusCode == 200) {
      // Parse the JSON response into List<UserChecklistAssignment>
      List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => UserChecklistAssignment.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load assignments');
    }
  }

}
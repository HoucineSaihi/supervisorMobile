import 'package:supervisormobile/features/calendar/models/Problem.dart';
import 'package:supervisormobile/features/calendar/models/paginationModel.dart';

class IncidentResponseModel {
  final List<Problem> data;
  final PaginationModel pagination;

  IncidentResponseModel({
    required this.data,
    required this.pagination,
  });

  factory IncidentResponseModel.fromJson(Map<String, dynamic> json) {
    try {
      print('🔍 IncidentResponseModel.fromJson: Starting to parse response');
      if (json['data'] == null) {
        throw Exception('Response data field is null or missing');
      }
      if (json['pagination'] == null) {
        throw Exception('Response pagination field is null or missing');
      }
      print('📊 IncidentResponseModel.fromJson: Found ${(json['data'] as List).length} incidents');

      return IncidentResponseModel(
        data: (json['data'] as List<dynamic>)
            .map((item) => Problem.fromJson(item))
            .toList(),
        pagination: PaginationModel.fromJson(json['pagination']),
      );
    } catch (e) {
      print('❌ IncidentResponseModel.fromJson: Error parsing response: $e');
      print('📄 IncidentResponseModel.fromJson: JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data.map((incident) => incident.toJson()).toList(),
      'pagination': pagination.toJson(),
    };
  }
}

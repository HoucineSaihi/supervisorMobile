import 'package:supervisormobile/features/calendar/models/missionModel.dart';
import 'package:supervisormobile/features/calendar/models/paginationModel.dart';

class MissionResponseModel {
  final List<Mission> data;
  final PaginationModel pagination;

  MissionResponseModel({
    required this.data,
    required this.pagination,
  });

  factory MissionResponseModel.fromJson(Map<String, dynamic> json) {
    try {
      print('🔍 MissionResponseModel.fromJson: Starting to parse response');
      if (json['data'] == null) {
        throw Exception('Response data field is null or missing');
      }
      if (json['pagination'] == null) {
        throw Exception('Response pagination field is null or missing');
      }
      print('📊 MissionResponseModel.fromJson: Found ${(json['data'] as List).length} missions');

      return MissionResponseModel(
        data: (json['data'] as List<dynamic>)
            .map((item) => Mission.fromJson(item))
            .toList(),
        pagination: PaginationModel.fromJson(json['pagination']),
      );
    } catch (e) {
      print('❌ MissionResponseModel.fromJson: Error parsing response: $e');
      print('📄 MissionResponseModel.fromJson: JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data.map((mission) => mission.toJson()).toList(),
      'pagination': pagination.toJson(),
    };
  }
}

import 'package:flutter/material.dart';
import 'package:supervisormobile/features/calendar/models/missionModel.dart';
import 'package:supervisormobile/features/calendar/screens/widgets/missionDetails.dart';

class MissionDetailsScreen extends StatelessWidget {
  final Mission mission;

  const MissionDetailsScreen({Key? key, required this.mission}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mission Details'),
      ),
      body: MissionDetailsWidget(missionId: mission.id),
    );
  }
}

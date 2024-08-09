import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart'; // Import Iconsax for the icons

import 'package:supervisormobile/features/calendar/models/missionModel.dart';
import 'package:supervisormobile/features/calendar/models/questionMissionModel.dart';
import 'package:supervisormobile/features/calendar/screens/widgets/questionResponse.dart';
import 'package:supervisormobile/features/calendar/services/missionService.dart';
import 'package:supervisormobile/features/calendar/screens/widgets/mission_question.dart';
import 'package:supervisormobile/utils/constants/colors.dart';

class MissionDetailsWidget extends StatefulWidget {
  final int missionId;
  final int mode; // Add mode attribute

  const MissionDetailsWidget({Key? key, required this.missionId, required this.mode}) : super(key: key);

  @override
  _MissionDetailsWidgetState createState() => _MissionDetailsWidgetState();
}

class _MissionDetailsWidgetState extends State<MissionDetailsWidget> {
  late Future<Mission> _missionFuture;

  @override
  void initState() {
    super.initState();
    _missionFuture = MissionService().getMissionDetails(widget.missionId);
  }

  double _calculateAnsweredPercentage(List<QuestionMission>? questions) {
    if (questions == null || questions.isEmpty) return 0;
    int answeredCount = questions.where((q) => q.reponse != null).length;
    return (answeredCount / questions.length) * 100;
  }

  double _calculateYesPercentage(List<QuestionMission>? questions) {
    if (questions == null || questions.isEmpty) return 0;
    int yesCount = questions.where((q) => q.reponse == 'Oui').length;
    return (yesCount / questions.length) * 100;
  }

  double _calculateNoPercentage(List<QuestionMission>? questions) {
    if (questions == null || questions.isEmpty) return 0;
    int noCount = questions.where((q) => q.reponse == 'Non').length;
    return (noCount / questions.length) * 100;
  }

  bool _allSousMissionsAnswered(Mission mission) {
    final sousMissions = mission.sousMissions ?? [];
    return sousMissions.every((sousMission) {
      final allQuestions = sousMission.missionQuestions ?? [];
      final answeredPercentage = _calculateAnsweredPercentage(allQuestions);
      return answeredPercentage == 100;
    });
  }

  Future<void> _handleValidation(Mission mission) async {
    final MissionService _missionService = MissionService(); // Initialize the MissionService
    try {
      await _missionService.updateMission(mission.id, mission, 6); // 6 is the status for validation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mission validated successfully.')),
      );
      Navigator.of(context).pop(); // Close the screen or navigate back
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to validate mission: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.mode == 0
          ? AppBar(
        title: Text('Detail de la mission '),
        leading: IconButton(
          icon: Icon(Iconsax.arrow_left), // Back arrow icon
          onPressed: () {
            Navigator.pop(context); // Navigate back
          },
        ),
      )
          : null,
      body: FutureBuilder<Mission>(
        future: _missionFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return Center(child: Text('No data found'));
          }

          final mission = snapshot.data!;
          final allSousMissionsAnswered = _allSousMissionsAnswered(mission);

          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Mission: ${mission.libelle ?? 'No Title'}',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          if (widget.mode == 1) // Show icon based on mode
                            Icon(
                              allSousMissionsAnswered ? Iconsax.tick_circle : Iconsax.close_circle,
                              color: allSousMissionsAnswered ? Colors.green : Colors.red,
                              size: 30,
                            ),
                        ],
                      ),
                      SizedBox(height: 16),
                      ...?mission.sousMissions?.map((sousMission) {
                        final allQuestions = sousMission.missionQuestions ?? [];
                        final answeredPercentage = _calculateAnsweredPercentage(allQuestions);
                        final yesPercentage = _calculateYesPercentage(allQuestions);
                        final noPercentage = _calculateNoPercentage(allQuestions);

                        return Card(
                          elevation: 4.0,
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => QuestionsListWidget(
                                    questions: allQuestions,
                                    onResponseSelected: (questionId, response) {
                                      // Handle the response selection
                                    },
                                    mode: widget.mode,
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Categorie: ${sousMission.libelle ?? 'No Title'}',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      if (widget.mode == 1) // Show icons based on mode
                                        if (answeredPercentage == 100)
                                          Icon(
                                            Iconsax.tick_circle,
                                            color: Colors.green,
                                            size: 30,
                                          )
                                        else
                                          Icon(
                                            Iconsax.close_circle,
                                            color: Colors.red,
                                            size: 30,
                                          ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  if (widget.mode == 1) ...[ // Show statistics based on mode
                                    Divider(),
                                    SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Iconsax.tick_square,
                                              color: Colors.green,
                                              size: 20,
                                            ),
                                            SizedBox(width: 4),
                                            Text('${yesPercentage.toStringAsFixed(1)}%'),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Icon(
                                              Iconsax.close_square,
                                              color: Colors.red,
                                              size: 20,
                                            ),
                                            SizedBox(width: 4),
                                            Text('${noPercentage.toStringAsFixed(1)}%'),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Icon(
                                              Iconsax.star,
                                              color: Colors.blue,
                                              size: 20,
                                            ),
                                            SizedBox(width: 4),
                                            Text('${answeredPercentage.toStringAsFixed(1)}%'),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                if (widget.mode == 1) ...[
                  // Ensure that only one status is shown at a time
                  if (mission.status == 1) ...[
                    ElevatedButton(
                      onPressed: () => _handleValidation(mission),
                      child: Text('Valider'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 50),
                      ),
                    ),
                  ] else if (mission.status == 3) ...[
                    Container(
                      padding: EdgeInsets.all(8), // Add padding to avoid clipping
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Iconsax.clock,
                            color: Colors.orange,
                            size: 24,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Reporté',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange),
                          ),
                        ],
                      ),
                    ),
                  ] else if (mission.status == 5) ...[
                    Container(
                      padding: EdgeInsets.all(8), // Add padding to avoid clipping
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Iconsax.close_circle,
                            color: Colors.red,
                            size: 24,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Annulé',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ] else if (mission.status == 6) ...[
                    Container(
                      padding: EdgeInsets.all(8), // Add padding to avoid clipping
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Iconsax.tick_circle,
                            color: Colors.green,
                            size: 24,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Terminé',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ],
            ),
          );
        },
      ),
    );
  }


}

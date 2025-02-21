import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart'; // Import Iconsax for the icons
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';

import 'package:supervisormobile/features/calendar/models/questionMissionModel.dart';
import 'package:supervisormobile/features/calendar/screens/widgets/questionResponse.dart';
import 'package:supervisormobile/features/calendar/services/missionService.dart';
import 'package:supervisormobile/features/calendar/screens/widgets/mission_question.dart';
import 'package:supervisormobile/utils/constants/colors.dart';

import '../../models/CategoryQuestions.dart';
import '../../models/Mission.dart';

class MissionDetailsWidget extends StatefulWidget {
  final int missionId;
  final int mode;
  final int status;// Add mode attribute

  const MissionDetailsWidget(
      {Key? key, required this.missionId, required this.mode,required this.status})
      : super(key: key);

  @override
  _MissionDetailsWidgetState createState() => _MissionDetailsWidgetState();
}

class _MissionDetailsWidgetState extends State<MissionDetailsWidget> {
  late Future<Mission> _missionFuture;
  late double missionConformity;
  @override
  void initState() {
    super.initState();
    _missionFuture = MissionService().getMissionDetails(widget.missionId);

  }

  double _calculateAnsweredPercentage(List<CategoryQuestions>? questions) {
   /* if (questions == null || questions.isEmpty) return 0;
    int answeredCount = questions.where((q) => q.reponseID != null).length;
    return (answeredCount / questions.length) * 100;*/
    return 0;
  }

  int _calculateYesPercentage(List<QuestionMission>? questions) {
    /*if (questions == null || questions.isEmpty) return 0;
    int yesCount = questions.length;
    return  questions.length;*/
    return 0;
  }

  double _calculateNoPercentage(List<QuestionMission>? questions) {
   /* if (questions == null || questions.isEmpty) return 0;
    int noCount = questions.where((q) => q.choixReponseQuestion?.incident == true).length;
    return (noCount / questions.length) * 100;*/
    return 0 ;
  }

  bool _allSousMissionsAnswered(Mission mission) {
   /* final sousMissions = mission.checklist.sousMissions ?? [];
    return sousMissions.every((sousMission) {
      final allQuestions = sousMission.missionQuestions ?? [];
      final answeredPercentage = _calculateAnsweredPercentage(allQuestions);
      return answeredPercentage == 100;
    });*/
    return false;
  }

  Future<void> _handleValidation(Mission mission) async {
    final MissionService _missionService = MissionService(); // Initialize the MissionService

    try {
      await _missionService.updateMission(mission.id, mission, 6); // 6 is the status for validation

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: AwesomeSnackbarContent(
            title: 'Success',
            message: 'Mission validated successfully.',
            contentType: ContentType.success,
          ),
          backgroundColor: Colors.transparent,
          behavior: SnackBarBehavior.floating,
          elevation: 0,
        ),
      );

      Navigator.pop(context, true); // Navigate back
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: AwesomeSnackbarContent(
            title: 'Error',
            message: e.toString(),
            contentType: ContentType.failure,
          ),
          backgroundColor: Colors.transparent,
          behavior: SnackBarBehavior.floating,
          elevation: 0,
        ),
      );
    }
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _missionFuture =  MissionService().getMissionDetails(widget.missionId);

    });
  }
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Detail de la mission '),
          leading: IconButton(
            icon: Icon(Iconsax.arrow_left), // Back arrow icon
            onPressed: () {
              Navigator.pop(context,true); // Navigate back
            },
          ),
        ),
        body: LiquidPullToRefresh(
          onRefresh: _handleRefresh,
          springAnimationDurationInMilliseconds: 300, // Speed up the animation
          height: 60.0, // Adjust the height as needed
          color: TColors.primary,
          child: FutureBuilder<Mission>(
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
              final conformity = mission.tauxConformite;
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
                                  'Mission: ${mission.checklist?.libelle ?? 'No Title'}',
                                  style: TextStyle(
                                      fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ),
                              if (widget.mode == 1) // Show icon based on mode
                                Text('TC : ${(conformity ?? 0).toStringAsFixed(2)} %'),
                            ],
                          ),
                          SizedBox(height: 16),
                          ...?mission.checklist?.sousMissions?.map((sousMission) {
                            final allQuestions =
                                sousMission.missionQuestions ?? [];
                            final answeredPercentage =
                            _calculateAnsweredPercentage(allQuestions);
                            final yesPercentage = 3 ;
                           // _calculateYesPercentage(allQuestions);
                            final noPercentage = 4;
                            //_calculateNoPercentage(allQuestions);

                            return Card(
                              elevation: 4.0,
                              child: InkWell(
                                onTap: () async {
                                  final shouldRefresh = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => QuestionsListWidget(
                                        questions: allQuestions,
                                        onResponseSelected:
                                            (questionId, response) {
                                          // Handle the response selection
                                        },
                                        mode: widget.mode,
                                        sousMissionID: sousMission.id!,
                                        modelResponseID: mission.modelReponseQuestionId!,
                                        status:widget.status,
                                        missionID: widget.missionId,
                                      ),
                                    ),
                                  );
                                  if (shouldRefresh == true) {
                                    _missionFuture = MissionService()
                                        .getMissionDetails(widget.missionId);
                                    setState(() {});
                                  }
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
                                          if (widget.mode ==
                                              1) // Show icons based on mode
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
                                      if (widget.mode == 1) ...[
                                        // Show statistics based on mode
                                        Divider(),
                                        SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  Iconsax.archive,
                                                  color: Colors.green,
                                                  size: 20,
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                    '${yesPercentage}'),
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
                                                Text(
                                                    '${noPercentage.toStringAsFixed(1)}%'),
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
                                                Text(
                                                    '${answeredPercentage.toStringAsFixed(1)}%'),
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
                      ]else if (mission.status == 2) ...[
                        ElevatedButton(
                          onPressed: () => _handleValidation(mission),
                          child: Text('Valider'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(double.infinity, 50),
                          ),
                        ),
                      ] else if (mission.status == 3) ...[
                        Container(
                          padding: EdgeInsets.all(8),
                          // Add padding to avoid clipping
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
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange),
                              ),
                            ],
                          ),
                        ),
                      ] else if (mission.status == 5) ...[
                        Container(
                          padding: EdgeInsets.all(8),
                          // Add padding to avoid clipping
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
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ] else if (mission.status == 6) ...[
                        Container(
                          padding: EdgeInsets.all(8),
                          // Add padding to avoid clipping
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
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green),
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
        ),
      ),
    );
  }
}

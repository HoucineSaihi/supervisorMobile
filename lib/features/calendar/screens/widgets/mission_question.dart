import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:supervisormobile/features/calendar/models/questionMissionModel.dart';
import 'package:supervisormobile/features/calendar/screens/widgets/edit_question_response.dart';
import 'package:supervisormobile/features/calendar/screens/widgets/questionResponse.dart';
import 'package:supervisormobile/features/calendar/services/missionService.dart';
import 'package:supervisormobile/utils/constants/colors.dart';

class QuestionsListWidget extends StatefulWidget {
  final List<QuestionMission> questions;
  final Function(int questionId, String response) onResponseSelected;
  final int mode; // Add this line to accept mode
  final int sousMissionID;
  final int modelResponseID;

  const QuestionsListWidget({
    Key? key,
    required this.questions,
    required this.onResponseSelected,
    required this.mode,
    required this.sousMissionID,
    required this.modelResponseID
  }) : super(key: key);

  @override
  _QuestionsListWidgetState createState() => _QuestionsListWidgetState();
}

class _QuestionsListWidgetState extends State<QuestionsListWidget> {
  late List<QuestionMission> _questions;

  @override
  void initState() {
    super.initState();
    _questions = widget.questions;
  }

  int _getColorFromHex(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF" + hexColor; // Add opacity if missing
    }
    return int.parse(hexColor, radix: 16);
  }

  IconData _getIconForValue(bool valeur) {
    // Choose an icon based on the value (for severity)
    if(valeur == true){
      return Icons.warning; // High value = success

    }else{
      return Icons.check;
    }
  }

  Future<void> _fetchQuestions() async {
    try {
      List<QuestionMission> fetchedQuestions = await MissionService().getQuestionsForSousMission(widget.sousMissionID);
      setState(() {
        _questions = fetchedQuestions; // Update the state variable with the fetched questions
      });
    } catch (e) {
      // Handle errors here
      print('Error fetching questions: $e');
    }
  }

  Future<void> _handleRefresh() async {
    setState(() async {
      await _fetchQuestions();

    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Liste des questions'),
          leading: IconButton(
            icon: Icon(Iconsax.arrow_left), // Back arrow icon
            onPressed: () {
              if (widget.mode == 1) {
                Navigator.pop(context, true); // Navigate back
              } else {
                Navigator.pop(context); // Navigate back
              }
            },
          ),
        ),
        body: LiquidPullToRefresh(
          onRefresh: _handleRefresh,
          springAnimationDurationInMilliseconds: 300, // Speed up the animation
          height: 60.0, // Adjust the height as needed
          color: TColors.primary, // Customize the color as needed
          child: ListView.builder(
            itemCount: _questions.length,
            itemBuilder: (context, index) {
              final question = _questions[index];
              final isResponseYes = question.reponse == 'Oui';
              final isResponseNo = question.reponse == 'Non';

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0), // Space between questions
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Display question description in a row and take the whole width
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Q: ${question.description ?? 'No Description'}',
                            style: TextStyle(fontSize: 18), // Slightly larger font size
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12), // Space between question and buttons
                    // Display buttons below the question based on mode
                    if (widget.mode == 1) ...[
                      // Check if there is a response
                      if (question.reponseID == null) ...[
                        // Show a single button named "Repondre"
                        SizedBox(
                          height: 32, // Smaller height for the button
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              final shouldRefresh = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => QuestionResponseWidget(
                                    questionId: question.id ?? 0,
                                    modelResponseID: widget.modelResponseID,
                                  ),
                                ),
                              );
                              if (shouldRefresh == true) {
                                // Handle refresh logic if necessary
                                _handleRefresh();
                              }
                            },
                            child: Text('Repondre'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue, // Modern color for the button
                              padding: EdgeInsets.symmetric(horizontal: 16.0),
                            ),
                          ),
                        ),
                      ] else ...[
                        // If response exists, show libelle and valeur from ChoixReponseQuestion
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.5),
                                spreadRadius: 2,
                                blurRadius: 4,
                                offset: Offset(0, 2), // Changes position of shadow
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _getIconForValue(question.choixReponseQuestion?.incident ?? false), // Icon based on value
                                color: Color(_getColorFromHex(question.choixReponseQuestion?.color ?? '#000000')), // Color from ChoixReponseQuestion
                                size: 24.0,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      question.choixReponseQuestion?.libelle ?? 'N/A',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(_getColorFromHex(question.choixReponseQuestion?.color ?? '#000000')), // Color from ChoixReponseQuestion
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Valeur: ${question.choixReponseQuestion?.valeur ?? 0}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              /*ElevatedButton.icon(
                                onPressed: () async {
                                  final shouldRefresh = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EditQuestionResponse(
                                        questionId: question.id ?? 0,
                                      ),
                                    ),
                                  );
                                  if (shouldRefresh == true) {
                                    _handleRefresh();
                                  }
                                },
                                icon: Icon(
                                  Icons.edit,
                                  color: Colors.white,
                                ),
                                label: Text(''),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueAccent,
                                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                                ),
                              ),*/    //Bouton de modification
                            ],
                          ),
                        ),
                      ],
                    ]

                    ,

                    if (widget.mode == 0) ...[
                      // Handle case when mode is 0 (No buttons displayed)
                      if (question.reponse != null) ...[
                        // Button spans full width if response is not null
                        SizedBox(
                          height: 32, // Smaller height for buttons
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final shouldRefresh = Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditQuestionResponse(
                                    questionId: question.id ?? 0,
                                  ),
                                ),
                              );
                              if (shouldRefresh == true) {
                                _handleRefresh();
                              }
                            },
                            icon: Icon(
                              question.reponse == 'Oui'
                                  ? Icons.check
                                  : Icons.cancel,
                              color: Colors.white,
                            ),
                            label: Text(question.reponse ?? 'Response'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isResponseYes ? Colors.green : Colors.red,
                              padding: EdgeInsets.symmetric(horizontal: 16.0), // Adjust padding as needed
                            ),
                          ),
                        ),
                      ],
                    ],
                    SizedBox(height: 30), // Space between each question
                    Divider(), // Horizontal line between questions
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

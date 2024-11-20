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
  final int status;

  const QuestionsListWidget({
    Key? key,
    required this.questions,
    required this.onResponseSelected,
    required this.mode,
    required this.sousMissionID,
    required this.status
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
          actions: [
            IconButton(
              icon: Icon(Iconsax.refresh), // Replace with the reload icon you are using
              onPressed: () {
                // Your function to reload or refresh
                _handleRefresh();
              },
            ),
          ],


        ),
        body:  // Customize the color as needed
        ListView.builder(
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
                          'Q: ${question.description ?? 'Aucune Description'}',
                          style: TextStyle(fontSize: 18), // Slightly larger font size
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12), // Space between question and buttons
                  // Display buttons below the question based on mode
                  if (widget.mode == 1) ...[
                    if (question.reponse == null) ...[
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 32, // Smaller height for buttons
                              child: ElevatedButton.icon(
                                onPressed: () async {

                                  if(widget.status != 1 && widget.status != 2 ) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Checklist validée, vous ne pouvez pas changer votre réponse.')));
                                  }else {
                                    final shouldRefresh = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => QuestionResponseWidget(
                                          questionId: question.id ?? 0,
                                          response: "Non",
                                        ),
                                      ),
                                    );
                                    if (shouldRefresh == true) {
                                      // Handle refresh logic if necessary
                                      _handleRefresh();
                                    }
                                  }

                                },
                                icon: Icon(Icons.cancel, color: Colors.white),
                                label: Text('Non'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  padding: EdgeInsets.symmetric(horizontal: 8.0), // Smaller padding
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12), // Space between "Non" and "Oui" buttons
                          Expanded(
                            child: SizedBox(
                              height: 32, // Smaller height for buttons
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  if(widget.status != 1 && widget.status != 2 ) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Checklist validée, vous ne pouvez pas changer votre réponse.')));
                                  }else {
                                    final shouldRefresh = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => QuestionResponseWidget(
                                          questionId: question.id ?? 0,
                                          response: "Oui",
                                        ),
                                      ),
                                    );
                                    if (shouldRefresh == true) {
                                      // Handle refresh logic if necessary
                                      _handleRefresh();
                                    }
                                  }

                                },
                                icon: Icon(Icons.check, color: Colors.white),
                                label: Text('Oui'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  padding: EdgeInsets.symmetric(horizontal: 8.0), // Smaller padding
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      // Button spans full width if response is not null
                      SizedBox(
                        height: 32, // Smaller height for buttons
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            if(widget.status != 1 && widget.status != 2 ) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Checklist validée, vous ne pouvez pas changer votre réponse.')));
                            }else {
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
                            }

                          },
                          icon: Icon(
                            question.reponse == 'Oui'
                                ? Icons.check
                                : Icons.cancel,
                            color: Colors.white,
                          ),
                          label: Text(question.reponse ?? 'Réponse'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isResponseYes ? Colors.green : Colors.red,
                            padding: EdgeInsets.symmetric(horizontal: 16.0), // Adjust padding as needed
                          ),
                        ),
                      ),
                    ],
                  ],
                  if (widget.mode == 0) ...[
                    // Handle case when mode is 0 (No buttons displayed)
                    if (question.reponse != null) ...[
                      // Button spans full width if response is not null
                      SizedBox(
                        height: 32, // Smaller height for buttons
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async { /*
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
                              } */
                          },
                          icon: Icon(
                            question.reponse == 'Oui'
                                ? Icons.check
                                : Icons.cancel,
                            color: Colors.white,
                          ),
                          label: Text(question.reponse ?? 'Réponse'),
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
    );
  }
}
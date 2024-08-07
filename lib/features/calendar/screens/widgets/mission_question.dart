import 'package:flutter/material.dart';
import 'package:supervisormobile/features/calendar/models/questionMissionModel.dart';
import 'package:supervisormobile/features/calendar/screens/widgets/edit_question_response.dart';
import 'package:supervisormobile/features/calendar/screens/widgets/questionResponse.dart';

class QuestionsListWidget extends StatelessWidget {
  final List<QuestionMission> questions;
  final Function(int questionId, String response) onResponseSelected;

  const QuestionsListWidget({
    Key? key,
    required this.questions,
    required this.onResponseSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Questions List')),
      body: ListView.builder(
        itemCount: questions.length,
        itemBuilder: (context, index) {
          final question = questions[index];
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
                // Display buttons below the question
                if (question.reponse == null) ...[
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 32, // Smaller height for buttons
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => QuestionResponseWidget(
                                    questionId: question.id ?? 0,
                                    response: "Non",
                                  ),
                                ),
                              );
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
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => QuestionResponseWidget(
                                    questionId: question.id ?? 0,
                                    response: "Oui",
                                  ),
                                ),
                              );
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
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditQuestionResponse(
                              questionId: question.id ?? 0,
                            ),
                          ),
                        );
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
                SizedBox(height: 30), // Space between each question
                Divider(), // Horizontal line between questions
              ],
            ),
          );
        },
      ),
    );
  }
}

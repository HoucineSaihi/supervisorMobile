import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:supervisormobile/features/calendar/models/questionMissionModel.dart';
import 'package:supervisormobile/features/calendar/models/actionsModel.dart';
import 'package:supervisormobile/features/calendar/screens/widgets/questionResponse.dart';
import 'package:supervisormobile/features/calendar/services/missionService.dart';

class EditQuestionResponse extends StatefulWidget {
  final int questionId;

  const EditQuestionResponse({Key? key, required this.questionId})
      : super(key: key);

  @override
  _EditQuestionResponseState createState() => _EditQuestionResponseState();
}

class _EditQuestionResponseState extends State<EditQuestionResponse> {
  late Future<QuestionMission> _questionFuture;
  late Future<List<ActionM>> _actionsFuture;
  final TextEditingController _commentController = TextEditingController();
  ActionM? _selectedAction;
  bool _isEditingComment = false;
  bool _isEditingResponse = false;
  bool _isActionDropdownVisible = false;

  @override
  void initState() {
    super.initState();
    _questionFuture = MissionService().getQuestionDetails(widget.questionId);
    _actionsFuture = MissionService().getActions();
  }

  void _toggleActionDropdown() {
    setState(() {
      _isActionDropdownVisible = !_isActionDropdownVisible;
    });
  }

  void _toggleCommentEdit() {
    setState(() {
      _isEditingComment = !_isEditingComment;
      if (_isEditingComment) {
        // Load existing comment into the TextField when editing starts
        _commentController.text = ''; // Optionally set to current comment
      } else {
        // Clear the TextField when hiding the editor
        _commentController.clear();
      }
    });
  }

  void _showResponseEditDialog(String currentResponse) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Edit Response'),
              IconButton(
                icon: Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Current Response: $currentResponse'),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => QuestionResponseWidget(
                            questionId: widget.questionId ?? 0,
                            response: "Oui",
                          ),
                        ),
                      ); // Pass 'Oui' when button is pressed
                    },
                    child: Text('Oui'),
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => QuestionResponseWidget(
                            questionId: widget.questionId ?? 0,
                            response: "Non",
                          ),
                        ),
                      ); // Pass 'Non' when button is pressed
                    },
                    child: Text('Non'),
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    ).then((result) {
      // Handle the result from the dialog
      if (result != null) {
        setState(() {
          _isEditingResponse = false;
          // Update the response based on the result
          // You may need to update this part according to how you want to handle the response update
          // For example:
          // _updateResponse(result);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Modifier reponse '),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: FutureBuilder<QuestionMission>(
              future: _questionFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData) {
                  return Center(child: Text('No data found'));
                }

                final question = snapshot.data!;
                final currentAction = question.actions;
                final newActionDescription = _selectedAction?.description ?? '';

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Description:',
                          style: TextStyle(fontWeight: FontWeight.bold,fontSize:18.0 ),
                        ),
                        SizedBox(height: 4),
                        Text('${question.description ?? 'No Description'}',style:TextStyle(fontSize:16.0 )),
                      ],
                    ),
                    SizedBox(height: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Réponse:',
                                    style: TextStyle(fontWeight: FontWeight.bold,fontSize:18.0 ),
                                  ),
                                  SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text('${question.reponse ?? 'No Response'}',style:TextStyle(fontSize:16.0,
                                          color: question.reponse == 'Oui'
                                              ? Colors.green
                                              : Colors.red,)),
                                      ),
                                      IconButton(
                                        icon: Icon(Iconsax.edit),
                                        onPressed: () => _showResponseEditDialog(question.reponse ?? ''),
                                      ),
                                    ],
                                  ),
                                ],

                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Commentaire:',
                                    style: TextStyle(fontWeight: FontWeight.bold,fontSize:18.0 ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '${question.commentaire ?? 'Aucun commentaire'}',
                                    overflow: TextOverflow.visible,
                                    softWrap: true,
                style:TextStyle(fontSize:16.0 )
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(Iconsax.edit),
                              onPressed: _toggleCommentEdit,
                            ),
                          ],
                        ),
                        if (_isEditingComment)
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    TextField(
                                      controller: _commentController..text = question.commentaire ?? '',
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(),
                                        hintText: 'Edit comment',
                                      ),
                                      maxLines: 4,
                                      autofocus: true,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Action:',
                                    style: TextStyle(fontWeight: FontWeight.bold,fontSize:18.0 ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '${currentAction?.description ?? 'Aucune action'}',
                                    overflow: TextOverflow.ellipsis,
                                      style:TextStyle(fontSize:16.0 )
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(Iconsax.edit),
                              onPressed: _toggleActionDropdown,
                            ),
                          ],
                        ),
                        if (_isActionDropdownVisible)
                          FutureBuilder<List<ActionM>>(
                            future: _actionsFuture,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return Center(child: CircularProgressIndicator());
                              } else if (snapshot.hasError) {
                                return Center(
                                    child: Text('Error: ${snapshot.error}'));
                              } else if (!snapshot.hasData ||
                                  snapshot.data!.isEmpty) {
                                return Center(
                                    child: Text('No actions available'));
                              }

                              final actions = snapshot.data!;
                              return Container(
                                margin: EdgeInsets.only(top: 8.0),
                                padding: EdgeInsets.all(8.0),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Action sélectionnée:',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold),
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                '${newActionDescription.isNotEmpty ? newActionDescription : (currentAction?.description ?? 'No Action Description')}',
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    CustomDropdown<ActionM>.search(
                                      key: UniqueKey(),
                                      items: actions,
                                      onChanged: (selectedValue) {
                                        setState(() {
                                          _selectedAction = selectedValue;
                                        });
                                      },
                                      hintText: 'Select Action',
                                      searchHintText: 'Search Actions',
                                      noResultFoundText: 'No actions found',
                                      validator: (value) {
                                        if (value == null) {
                                          return 'Please select an action';
                                        }
                                        return null;
                                      },
                                      maxlines: 1,
                                      decoration: CustomDropdownDecoration(
                                        expandedFillColor: Colors.grey,
                                        expandedBorder:
                                        Border.all(color: Colors.white),
                                        expandedShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.5),
                                            spreadRadius: 1,
                                            blurRadius: 5,
                                            offset: Offset(0, 3),
                                          ),
                                        ],
                                        hintStyle: TextStyle(color: Colors.black),
                                        headerStyle:
                                        TextStyle(color: Colors.black),
                                        noResultFoundStyle:
                                        TextStyle(color: Colors.black),
                                        errorStyle:
                                        TextStyle(color: Colors.black),
                                        listItemStyle:
                                        TextStyle(color: Colors.black),
                                        searchFieldDecoration:
                                        SearchFieldDecoration(
                                          textStyle:
                                          TextStyle(color: Colors.black),
                                          hintStyle:
                                          TextStyle(color: Colors.black),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                    SizedBox(height: 40),
                    Container(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final comment = _commentController.text;
                          final question = await _questionFuture;
                          final updatedQuestion = QuestionMission(
                            id: question.id,
                            description: question.description,
                            sousMissionId: question.sousMissionId,
                            reponse: question.reponse,
                            clouture: question.clouture,
                            actionId: _selectedAction?.id,
                            actions: question.actions,
                            commentaire: comment,
                            fileName: question.fileName,
                          );

                          await MissionService().updateMissionQuestion(
                              question.id, updatedQuestion);
                        },
                        child: Text('Enregistrer les modifications'),
                      ),
                    ),
                  ],

                );
              },

            ),
          ),
        ));
  }
}

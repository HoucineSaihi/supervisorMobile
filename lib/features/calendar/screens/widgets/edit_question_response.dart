import 'dart:io';

import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:easy_image_viewer/easy_image_viewer.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:supervisormobile/features/calendar/models/questionMissionModel.dart';
import 'package:supervisormobile/features/calendar/models/actionsModel.dart';
import 'package:supervisormobile/features/calendar/screens/widgets/questionResponse.dart';
import 'package:supervisormobile/features/calendar/services/missionService.dart';
import 'package:flutter_image_slideshow/flutter_image_slideshow.dart';

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
  bool _isImageEnlarged = false;

  File? _imageFile;
  List<File> _images = [];

  @override
  void initState() {
    super.initState();
    _questionFuture = MissionService().getQuestionDetails(widget.questionId);
    _actionsFuture = MissionService().getActions();

    _questionFuture.then((questionDetails) {
      if (questionDetails.fileName != null && questionDetails.fileName!.isNotEmpty) {
        _fetchImage(questionDetails.fileName!);
      }
    }).catchError((error) {
      print('Failed to fetch question details: $error');
    });
  }

  Future<void> _fetchImage(String filename) async {
    try {
      final file = await MissionService().getImage(filename);
      setState(() {
        _imageFile = file;
        _images.add(file); // Add to the image list for slideshow
      });
    } catch (e) {
      print('Failed to fetch image: $e');
      setState(() {
        _imageFile = null;
      });
    }
  }

  void _showImageViewer(int index) {
    final imageProvider = Image.file(_images[index]).image;
    showImageViewer(context, imageProvider, onViewerDismissed: () {
      print("dismissed");
    });
  }


  void _toggleImageSize() {
    setState(() {
      _isImageEnlarged = !_isImageEnlarged;
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
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0),
                      ),
                      SizedBox(height: 4),
                      Text('${question.description ?? 'No Description'}', style: TextStyle(fontSize: 16.0)),
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
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0),
                                ),
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${question.reponse ?? 'No Response'}',
                                        style: TextStyle(
                                          fontSize: 16.0,
                                          color: question.reponse == 'Oui'
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(Iconsax.edit),
                                      onPressed: () => _showResponseEditDialog(question.reponse ?? '',question.id),
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
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '${question.commentaire ?? 'Aucun commentaire'}',
                                  overflow: TextOverflow.visible,
                                  softWrap: true,
                                  style: TextStyle(fontSize: 16.0),
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
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '${currentAction?.description ?? 'Aucune action'}',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 16.0),
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
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return Center(child: CircularProgressIndicator());
                            } else if (snapshot.hasError) {
                              return Center(child: Text('Error: ${snapshot.error}'));
                            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return Center(child: Text('No actions available'));
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
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Action sélectionnée:',
                                              style: TextStyle(fontWeight: FontWeight.bold),
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
                                      expandedBorder: Border.all(color: Colors.white),
                                      expandedShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.5),
                                          spreadRadius: 3,
                                          blurRadius: 7,
                                          offset: Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                  SizedBox(height: 20),
                  if (_images.isNotEmpty) ...[
                    ImageSlideshow(
                      width: double.infinity,
                      height: _isImageEnlarged ? 500 : 300,
                      initialPage: 0,
                      indicatorColor: Colors.blue,
                      indicatorBackgroundColor: Colors.grey,
                      onPageChanged: (value) {
                        print('Page changed: $value');
                      },
                      isLoop: true,
                      children: _images.map((image) {
                        return GestureDetector(
                          onTap: () => _showImageViewer(_images.indexOf(image)),
                          child: Image.file(
                            image,
                            fit: BoxFit.cover,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      // Save comment and action response logic
                      if (_isEditingComment) {
                        // Save comment
                      }
                      // Save action and response
                    },
                    child: Text('Enregistrer'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 50), // Full width and fixed height
                    ),
                  )

                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _showResponseEditDialog(String currentResponse, int questionId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Choisir réponse'), // Updated title
          content: Text(
            currentResponse, // Display the current response
            style: TextStyle(fontSize: 18), // Optional styling for the text
          ),
          actions: [
            // Row for the buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Non Button
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => QuestionResponseWidget(
                            questionId: questionId,
                            response: 'Non',
                          ),
                        ),
                      );
                    },
                    child: Text('Non'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red, // Red background color
                    ),
                  ),
                ),
                SizedBox(width: 8), // Space between buttons
                // Oui Button
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => QuestionResponseWidget(
                            questionId: questionId,
                            response: 'Oui',
                          ),
                        ),
                      );
                    },
                    child: Text('Oui'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green, // Green background color
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8), // Space below buttons
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }




  void _toggleCommentEdit() {
    setState(() {
      _isEditingComment = !_isEditingComment;
    });
  }

  void _toggleActionDropdown() {
    setState(() {
      _isActionDropdownVisible = !_isActionDropdownVisible;
    });
  }
}


import 'dart:io';

import 'package:flutter/material.dart';
import 'package:animated_custom_dropdown/custom_dropdown.dart'; // Import the package
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart'; // Import image picker
import 'package:supervisormobile/features/calendar/models/questionMissionModel.dart';
import 'package:supervisormobile/features/calendar/models/actionsModel.dart';
import 'package:supervisormobile/features/calendar/services/missionService.dart';

class QuestionResponseWidget extends StatefulWidget {
  final int questionId;
  final String response;

  const QuestionResponseWidget({
    Key? key,
    required this.questionId,
    required this.response,
  }) : super(key: key);

  @override
  _QuestionResponseWidgetState createState() => _QuestionResponseWidgetState();
}

class _QuestionResponseWidgetState extends State<QuestionResponseWidget> {
  late Future<QuestionMission> _questionFuture;
  late Future<List<ActionM>> _actionsFuture;
  final TextEditingController _commentController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String? _selectedAction;
  bool _showAdditionalWidgets = false;
  List<ActionM> _actions = [];
  final ImagePicker _picker = ImagePicker();
  List<XFile>? _imageFiles;

  @override
  void initState() {
    super.initState();
    _questionFuture = MissionService().getQuestionDetails(widget.questionId);
    _actionsFuture = MissionService().getActions();
    _actionsFuture.then((actions) {
      setState(() {
        _actions = actions;
      });
    });
  }

  void _submitForm() async {
    if (widget.response == 'Non') {
      if (_formKey.currentState!.validate()) {
        _formKey.currentState!.save();

        // Ensure there is a file to upload
        if (_imageFiles != null && _imageFiles!.isNotEmpty) {
          try {
            // Upload the first selected file
            final firstFile = _imageFiles!.first;
            final fileName = await MissionService().uploadFile(File(firstFile.path));

            // Create the updated QuestionMission object
            final updatedQuestion = QuestionMission(
              id: widget.questionId,
              description: "", // Optionally update description if needed
              reponse: widget.response,
              commentaire: _commentController.text,
              clouture: null, // Update clouture if needed
              actionId: _actions.firstWhere((action) => action.id.toString() == _selectedAction).id,
              fileName: fileName, // Set the filename returned from the upload
            );

            // Call the service method to update the question
            await MissionService().updateMissionQuestion(updatedQuestion.id, updatedQuestion);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Question updated successfully')));
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to upload file')));
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No file selected')));
        }
      }
    } else {
      final updatedQuestion = QuestionMission(
        id: widget.questionId,
        description: "", // Optionally update description if needed
        reponse: widget.response,
        commentaire: _commentController.text,
        clouture: null, // Update clouture if needed
        fileName: '', // Optionally update fileName if needed
      );

      // Call the service method to update the question
      try {
        await MissionService().updateMissionQuestion(updatedQuestion.id, updatedQuestion);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Question updated successfully')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update question')));
      }
    }
  }



  void _onActionChanged(ActionM? newValue) {
    setState(() {
      _selectedAction = newValue?.id.toString();
      _showAdditionalWidgets = newValue?.description == 'non';
    });
  }

  Future<void> _pickImages() async {
    final List<XFile>? selectedImages = await _picker.pickMultiImage();
    setState(() {
      _imageFiles = selectedImages;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final TextStyle textStyle = TextStyle(color: isDarkMode ? Colors.black : Colors.black);

    return Scaffold(
      appBar: AppBar(
        title: Text('Repondre au question'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FutureBuilder<QuestionMission>(
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

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Question: ${question.description ?? 'No Description'}",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Réponse: ${widget.response == 'Non' ? 'Non' : 'Oui'}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: widget.response == 'Oui'
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                      SizedBox(height: 16),

                      if (widget.response == 'Non')
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

                            return CustomDropdown<ActionM>.search(
                              hintText: 'Select Action',
                              items: actions,
                              excludeSelected: false,
                              onChanged: _onActionChanged,
                              decoration: CustomDropdownDecoration(
                                expandedFillColor: Colors.grey,
                                expandedBorder: Border.all(color: Colors.white),
                                expandedShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.5),
                                    spreadRadius: 1,
                                    blurRadius: 5,
                                    offset: Offset(0, 3), // changes position of shadow
                                  ),
                                ],
                                hintStyle: textStyle,
                                headerStyle: textStyle,
                                noResultFoundStyle: textStyle,
                                errorStyle: textStyle,
                                listItemStyle: textStyle,
                                searchFieldDecoration: SearchFieldDecoration(
                                  textStyle: TextStyle(color: Colors.black),
                                  hintStyle: TextStyle(color: Colors.black),
                                ),
                              ),
                              validator: (value) {
                                if (value == null) {
                                  return 'Please select an action';
                                }
                                return null;
                              },
                            );
                          },
                        ),
                      SizedBox(height: 16),
                      Text('Commentaire', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: _commentController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Commentaire',
                        ),
                        maxLines: 4,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a comment';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      Text('Joindre des images', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _pickImages,
                        icon: Icon(Iconsax.add, size: 24), // Replace with the correct icon from iconsax
                        label: Text('Image'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: Size(double.infinity, 48), // Full width and fixed height
                          side: BorderSide(color: Colors.black), // Outline color
                        ),
                      ),
                      SizedBox(height: 16),
                      if (_imageFiles != null && _imageFiles!.isNotEmpty)
                        Text(
                          'Selected Images:',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      SizedBox(height: 8),
                      _imageFiles != null
                          ? Container(
                        height: 120, // Adjust height as needed
                        child: GridView.builder(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3, // Number of columns
                            crossAxisSpacing: 4.0,
                            mainAxisSpacing: 4.0,
                          ),
                          itemCount: _imageFiles!.length,
                          itemBuilder: (context, index) {
                            return Image.file(
                              File(_imageFiles![index].path),
                              fit: BoxFit.cover,
                            );
                          },
                        ),
                      )
                          : SizedBox.shrink(),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _submitForm,
                        child: Text(
                          'Valider',
                          style: TextStyle(fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(double.infinity, 48), // Full width and fixed height
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

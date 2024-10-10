import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:easy_image_viewer/easy_image_viewer.dart';
import 'package:flutter/material.dart';
import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:flutter_image_slideshow/flutter_image_slideshow.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supervisormobile/features/calendar/models/choixReponseQuestion.dart';
import 'package:supervisormobile/features/calendar/models/questionMissionModel.dart';
import 'package:supervisormobile/features/calendar/models/actionsModel.dart';
import 'package:supervisormobile/features/calendar/screens/widgets/captureImageScreen.dart';
import 'package:supervisormobile/features/calendar/services/missionService.dart';
import 'package:path_provider/path_provider.dart'; // For accessing the temp directory

class QuestionResponseWidget extends StatefulWidget {
  final int questionId;
  final int modelResponseID;

  const QuestionResponseWidget(
      {Key? key, required this.questionId, required this.modelResponseID})
      : super(key: key);

  @override
  _QuestionResponseWidgetState createState() => _QuestionResponseWidgetState();
}

class _QuestionResponseWidgetState extends State<QuestionResponseWidget> {
  late Future<QuestionMission> _questionFuture;
  late Future<List<ActionM>> _actionsFuture;
  late Future<List<ChoixReponseQuestion>> _listChoixReponse;
  final TextEditingController _commentController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  ActionM? _selectedAction;
  int? selectedResponseID;
  bool _showAdditionalWidgets = false;
  List<ActionM> _actions = [];
  final ImagePicker _picker = ImagePicker();
  List<XFile>? _imageFiles;

  @override
  void initState() {
    super.initState();
    _questionFuture = MissionService().getQuestionDetails(widget.questionId);
    _actionsFuture = MissionService().getActions();
    _listChoixReponse =
        MissionService().getAllChoixReponse(widget.modelResponseID);
    setState(() {});
  }

  void _submitForm() async {
    if (selectedResponseID != null) {
      String? fileName;

      // Check if there are image files and upload the first one if it exists
      if (_imageFiles != null && _imageFiles!.isNotEmpty) {
        try {
          final firstFile = _imageFiles!.first;
          fileName = await MissionService().uploadFile(File(firstFile.path));
          print("\n File Name ----------------------------------------------- \n" + fileName);
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to upload file')),
          );
          return; // Stop execution if file upload fails
        }
      }

      // Create the updated question object
      final updatedQuestion = QuestionMission(
        id: widget.questionId,
        description: "", // Or some default value
        commentaire: _commentController.text,
        clouture: null,
        actionId: _selectedAction?.id,
        fileName: fileName, // Add fileName if available, otherwise null
        reponseID: selectedResponseID,
      );

      print("-----------------------------------Valeur JSON \n");
      print(updatedQuestion.actionId);
      print(updatedQuestion.reponseID);
      print(updatedQuestion.fileName);

      try {
        await MissionService().updateMissionQuestion(updatedQuestion.id, updatedQuestion);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Question updated successfully')),
        );
        Navigator.pop(context, true); // Navigate back
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update question')),
        );
      }
    }
    else{
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Séléctionner une réponse.')),
      );
    }
  }


  void _onActionChanged(ActionM? newValue) {
    setState(() {
      _selectedAction = newValue;
    });
  }

  Future<void> _pickImages() async {
    final List<XFile>? selectedImages = await _picker.pickMultiImage();
    if (selectedImages != null) {
      setState(() {
        _imageFiles = selectedImages;
      });
    }
  }

  void _showImageViewer(int index) {
    if (_imageFiles != null && _imageFiles!.isNotEmpty) {
      final imageProvider = FileImage(File(_imageFiles![index].path));
      showImageViewer(
        context,
        imageProvider,
        immersive: false,
        onViewerDismissed: () {
          print("Image viewer dismissed");
        },
      );
    }
  }

  void _openCamera() async {
    // Navigate to CaptureImageScreen and await result
    final Uint8List? imageBytes = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CaptureImageScreen(),
      ),
    );

    if (imageBytes != null) {
      try {
        // Get the temporary directory
        final directory = await getTemporaryDirectory();
        final filePath =
            '${directory.path}/temp_image_${DateTime.now().millisecondsSinceEpoch}.png';

        // Write the Uint8List to the file
        final file = File(filePath);
        await file.writeAsBytes(imageBytes);

        // Save the image to the gallery
        final result = await ImageGallerySaver.saveImage(imageBytes);

        if (result != null && result['isSuccess'] == true) {
          print('Image saved to gallery successfully');
        } else {
          print('Failed to save image to gallery');
        }

        // Create an XFile from the file path
        final XFile imageFile = XFile(filePath);

        // Ensure the widget is still mounted before calling setState
        if (mounted) {
          setState(() {
            // Add the newly picked image to the existing list
            _imageFiles = [imageFile];
          });
        }
      } catch (e) {
        print('Error saving image to file: $e');
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _imageFiles!.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final TextStyle textStyle =
    TextStyle(color: isDarkMode ? Colors.black : Colors.black);

    return SafeArea(
        child: Scaffold(
          appBar: AppBar(
            title: Text('Répondre au question'),
            leading: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.pop(context, true); // Navigate back
              },
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(8.0),
            child: SingleChildScrollView(
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
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 16),
                            // Dropdown for selecting response
                            FutureBuilder<List<ChoixReponseQuestion>>(
                              future: _listChoixReponse,
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
                                      child: Text('No choices available'));
                                }

                                final choices = snapshot.data!;

                                return DropdownButtonFormField<
                                    ChoixReponseQuestion>(
                                  hint: Text('Select Response'),
                                  items: choices.map((ChoixReponseQuestion choice) {
                                    return DropdownMenuItem<ChoixReponseQuestion>(
                                      value: choice,
                                      child: Text(
                                          '${choice.libelle ?? 'No Label'} = ${choice.valeur ?? 'No Value'}'), // Show libelle and valeur
                                    );
                                  }).toList(),
                                  onChanged: (ChoixReponseQuestion? newValue) {
                                    setState(() {
                                      selectedResponseID = newValue?.id; // Assuming `id` is the identifier for the response
                                    });
                                  },
                                  validator: (value) {
                                    if (value == null) {
                                      return 'Please select a response';
                                    }
                                    return null;
                                  },
                                );
                              },
                            ),
                            SizedBox(height: 16),
                            // Actions Dropdown (if applicable)

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

                                // Add the "None" option at the start of the list
                                final noneAction = ActionM(id: 0, description: 'Aucune action');
                                final allActions = [noneAction, ...actions];

                                return CustomDropdown<ActionM>.search(
                                  hintText: 'Select Action',
                                  items: allActions,
                                  excludeSelected: false,
                                  onChanged: (value) {
                                    // Handle the "None" option when selected
                                    if (value?.id == -1) {
                                      _selectedAction = null;  // Deselect logic
                                    } else {
                                      _onActionChanged(value);
                                    }
                                  },
                                  decoration: CustomDropdownDecoration(
                                    expandedFillColor: Colors.grey,
                                    expandedBorder: Border.all(color: Colors.white),
                                    expandedShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.5),
                                        spreadRadius: 1,
                                        blurRadius: 5,
                                        offset: Offset(0, 3),
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
                                    if (value == null || value.id == -1) {
                                      return 'Please select an action';
                                    }
                                    return null;
                                  },
                                );
                              },
                            ),
                              SizedBox(height: 16.0),
                            _selectedAction != null
                                ? Row(
                              children: [
                                Flexible( // Use Flexible to allow the Text to wrap
                                  child: Text(
                                    'Action: ${_selectedAction?.description ?? ''}',
                                    softWrap: true, // Allows text to break into multiple lines
                                    overflow: TextOverflow.visible, // Makes sure the overflow is handled
                                  ),
                                ),
                              ],
                            )
                                : SizedBox.shrink(),// Returns an empty widget when _selectedAction is null


                            SizedBox(height: 16),
                            Text('Commentaire',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
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
                            Text('Joindre des images',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                            SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: _pickImages,
                              icon: Icon(Icons.add, size: 24),
                              label: Text('Image'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: Size(double.infinity, 48),
                              ),
                            ),
                            SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: _openCamera,
                              icon: Icon(Icons.camera_alt, size: 24),
                              label: Text('Ouvrir Camera'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: Size(double.infinity, 48),
                              ),
                            ),
                            SizedBox(height: 16),

                            if (_imageFiles != null && _imageFiles!.isNotEmpty) ...[
                              ImageSlideshow(
                                width: double.infinity,
                                height: 300,
                                initialPage: 0,
                                indicatorColor: Colors.blue,
                                indicatorBackgroundColor: Colors.grey,
                                onPageChanged: (value) {
                                  print('Page changed: $value');
                                },
                                isLoop: true,
                                children: _imageFiles!.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final imageFile = entry.value;

                                  return Stack(
                                    children: [
                                      Container(
                                        margin:
                                        EdgeInsets.symmetric(horizontal: 8.0),
                                        child: GestureDetector(
                                          onTap: () => _showImageViewer(index),
                                          child: Image.file(
                                            File(imageFile.path),
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        right: 8,
                                        top: 8,
                                        child: IconButton(
                                          icon: Icon(Iconsax.trash,
                                              color: Colors.red),
                                          onPressed: () {
                                            _removeImage(index);
                                          },
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ],
                            SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: _submitForm,
                              child: Text('Valider'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: Size(double.infinity, 48),
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
          ),
        ));
  }
}



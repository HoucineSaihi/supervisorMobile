import 'dart:io';
import 'dart:typed_data';

import 'package:easy_image_viewer/easy_image_viewer.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:image_picker/image_picker.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supervisormobile/features/calendar/models/CategoryQuestions.dart';
import 'package:supervisormobile/features/calendar/models/questionMissionModel.dart';
import 'package:supervisormobile/features/calendar/screens/widgets/captureImageScreen.dart';
import 'package:supervisormobile/features/calendar/screens/widgets/edit_question_response.dart';
import 'package:supervisormobile/features/calendar/screens/widgets/questionResponse.dart';
import 'package:supervisormobile/features/calendar/services/missionService.dart';
import 'package:supervisormobile/utils/constants/colors.dart';

class QuestionsListWidget extends StatefulWidget {
  final List<CategoryQuestions> questions;
  final Function(int questionId, String response) onResponseSelected;
  final int mode; // Add this line to accept mode
  final int sousMissionID;
  final int modelResponseID;
  final int status;
  final int missionID;

  const QuestionsListWidget({
    Key? key,
    required this.questions,
    required this.onResponseSelected,
    required this.mode,
    required this.sousMissionID,
    required this.modelResponseID,
    required this.status,
    required this.missionID
  }) : super(key: key);

  @override
  _QuestionsListWidgetState createState() => _QuestionsListWidgetState();
}

class _QuestionsListWidgetState extends State<QuestionsListWidget> {
  late List<CategoryQuestions> _questions;
  final ImagePicker _picker = ImagePicker();
  List<XFile>? _imageFiles;
  File? jointureFichier;
  PlatformFile? infoFichier;

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

  Future<void> _fetchQuestions() async {
    try {
      List<CategoryQuestions> fetchedQuestions = await MissionService().getQuestionsForSousMission(widget.sousMissionID,widget.missionID);
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
                      if (question.missionAnswers.isEmpty) ...[
                        // Show a single button named "Repondre"
                        SizedBox(
                          height: 32, // Smaller height for the button
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              if(widget.status != 1 && widget.status != 2 ) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Checklist validée, vous ne pouvez pas changer votre réponse.')));
                              }else {
                                final shouldRefresh = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => QuestionResponseWidget(
                                      questionId: question.id ?? 0,
                                      modelResponseID: widget.modelResponseID,
                                      missionId: widget.missionID,
                                      question_description: question.description!,
                                    ),
                                  ),
                                );
                                if (shouldRefresh == true) {
                                  // Handle refresh logic if necessary
                                  _handleRefresh();
                                }
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
                                _getIconForValue(question.missionAnswers[0]?.choixReponseQuestion?.incident ?? false), // Icon based on value
                                color: Color(_getColorFromHex(question.missionAnswers[0]?.choixReponseQuestion?.color ?? '#000000')), // Color from ChoixReponseQuestion
                                size: 24.0,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      question.missionAnswers[0].choixReponseQuestion?.libelle ?? 'N/A',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(_getColorFromHex(question.missionAnswers[0]?.choixReponseQuestion?.color ?? '#000000')), // Color from ChoixReponseQuestion
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Valeur: ${question.missionAnswers[0]?.choixReponseQuestion?.valeur ?? 0}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: () async {
                                      if(widget.status != 1 && widget.status != 2 ) {
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Checklist validée, vous ne pouvez pas changer votre réponse.')));
                                      }else {
                                        final shouldRefresh = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => EditQuestionResponse(
                                              questionId: question.id ?? 0,
                                              modeleReponseId: widget.modelResponseID,
                                              mission_id: widget.missionID,
                                              questionDescr: question.description!,
                                            ),
                                          ),
                                        );
                                        if (shouldRefresh == true) {
                                          _handleRefresh();
                                        }
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
                              ),    //Bouton de modification
                            ],
                          ),
                        ),
                      ],
                    ]

                    ,

                    if (widget.mode == 0) ...[
                      // Handle case when mode is 0 (No buttons displayed)
                      if (question.missionAnswers != null) ...[
                        // Button spans full width if response is not null

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

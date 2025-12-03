import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:image_picker/image_picker.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supervisormobile/features/calendar/models/questionMissionModel.dart';
import 'package:supervisormobile/features/calendar/screens/widgets/captureImageScreen.dart';
import 'package:supervisormobile/features/calendar/screens/widgets/edit_question_response.dart';
import 'package:supervisormobile/features/calendar/screens/widgets/questionResponse.dart';
import 'package:supervisormobile/features/calendar/services/missionService.dart';
import 'package:supervisormobile/utils/constants/colors.dart';

import '../../../incidents/models/IncidentCategory.dart';

class QuestionsListWidget extends StatefulWidget {
  final List<QuestionMission> questions;
  final Function(int questionId, String response) onResponseSelected;
  final int mode; // Add this line to accept mode
  final int sousMissionID;
  final int modelResponseID;
  final int status;
  final IncidentCategory preSelectedType;

  const QuestionsListWidget({
    Key? key,
    required this.questions,
    required this.onResponseSelected,
    required this.mode,
    required this.sousMissionID,
    required this.modelResponseID,
    required this.status,
    required this.preSelectedType
  }) : super(key: key);

  @override
  _QuestionsListWidgetState createState() => _QuestionsListWidgetState();
}

class _QuestionsListWidgetState extends State<QuestionsListWidget> {
  late List<QuestionMission> _questions;
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

  void _removeImage(int index) {
    setState(() {
      _imageFiles!.removeAt(index);
    });
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
            icon: Icon(Iconsax.arrow_left),
            onPressed: () {
              if (widget.mode == 1) {
                Navigator.pop(context, true);
              } else {
                Navigator.pop(context);
              }
            },
          ),
        ),
        body: Column(
          children: [
            // Refresh button at top right
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(Iconsax.refresh),
                  onPressed: _handleRefresh,
                  tooltip: 'Refresh Questions',
                ),
              ],
            ),

            // Questions list below, scrollable
            Expanded(
              child: ListView.builder(
                itemCount: _questions.length,
                itemBuilder: (context, index) {
                  final question = _questions[index];
                  final isResponseYes = question.reponse == 'Oui';

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Q: ${question.description ?? 'No Description'}',
                          style: TextStyle(fontSize: 18),
                        ),
                        SizedBox(height: 12),

                        if (widget.mode == 1) ...[
                          if (question.reponseID == null) ...[
                            SizedBox(
                              height: 32,
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () async {
                                  if (widget.status != 1 && widget.status != 2) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Checklist validée, vous ne pouvez pas changer votre réponse.')),
                                    );
                                  } else {
                                    final shouldRefresh = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => QuestionResponseWidget(
                                          questionId: question.id ?? 0,
                                          modelResponseID: widget.modelResponseID,
                                          preSelectedType: widget.preSelectedType,
                                          originalType: widget.preSelectedType,
                                        ),
                                      ),
                                    );
                                    if (shouldRefresh == true) _handleRefresh();
                                  }
                                },
                                child: Text('Repondre'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                                ),
                              ),
                            ),
                          ] else ...[
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
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _getIconForValue(question.choixReponseQuestion?.incident ?? false),
                                    color: Color(_getColorFromHex(question.choixReponseQuestion?.color ?? '#000000')),
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
                                            color: Color(_getColorFromHex(question.choixReponseQuestion?.color ?? '#000000')),
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Valeur: ${question.choixReponseQuestion?.valeur ?? 0}',
                                          style: TextStyle(fontSize: 14, color: Colors.black54),
                                        ),
                                      ],
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      if (widget.status != 1 && widget.status != 2) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Checklist validée, vous ne pouvez pas changer votre réponse.')),
                                        );
                                      } else {
                                        final shouldRefresh = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => EditQuestionResponse(
                                              questionId: question.id ?? 0,
                                              modeleReponseId: widget.modelResponseID,
                                              preSelectedType: widget.preSelectedType,
                                            ),
                                          ),
                                        );
                                        if (shouldRefresh == true) _handleRefresh();
                                      }
                                    },
                                    icon: Icon(Icons.edit, color: Colors.white),
                                    label: Text(''),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blueAccent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],

                        if (widget.mode == 0 && question.reponse != null) ...[
                          SizedBox(
                            height: 32,
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final shouldRefresh = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditQuestionResponse(
                                      questionId: question.id ?? 0,
                                      modeleReponseId: widget.modelResponseID,
                                      preSelectedType: widget.preSelectedType,
                                    ),
                                  ),
                                );
                                if (shouldRefresh == true) _handleRefresh();
                              },
                              icon: Icon(
                                isResponseYes ? Icons.check : Icons.cancel,
                                color: Colors.white,
                              ),
                              label: Text(question.reponse ?? 'Response'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isResponseYes ? Colors.green : Colors.red,
                              ),
                            ),
                          ),
                        ],
                        SizedBox(height: 30),
                        Divider(),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

}

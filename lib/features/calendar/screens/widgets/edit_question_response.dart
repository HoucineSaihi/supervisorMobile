import 'dart:io';
import 'dart:typed_data';
import 'dart:io' as io;
import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supervisormobile/features/calendar/models/questionMissionModel.dart';
import 'package:supervisormobile/features/calendar/models/actionsModel.dart';
import 'package:supervisormobile/features/calendar/screens/widgets/captureImageScreen.dart';
import 'package:supervisormobile/features/calendar/screens/widgets/questionResponse.dart';
import 'package:supervisormobile/features/calendar/services/missionService.dart';
import 'package:flutter_image_slideshow/flutter_image_slideshow.dart';
import 'dart:html' as html;

import '../../../../dtos/questions/questionAnswerDto.dart';
import '../../../incidents/models/IncidentCategory.dart';
import '../../DTOs/FileInfo.dart';
import 'package:permission_handler/permission_handler.dart';

class EditQuestionResponse extends StatefulWidget {
  final int questionId;
  final int modeleReponseId;
  final IncidentCategory preSelectedType;

  const EditQuestionResponse(
      {Key? key, required this.questionId, required this.modeleReponseId, required this.preSelectedType})
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

  final ImagePicker _picker = ImagePicker();

  List<XFile>? _imageFiles = []; // All picked image files (mobile + web UI)
  List<html.File>? _webImageFiles = []; // Raw files to upload on web

  List<XFile> _mobileImages = []; // For mobile: picked + fetched images
  List<XFile> _webImages = []; // For web: picked + fetched images

  dynamic jointureFichier; // Either html.File or dart.io.File
  PlatformFile? infoFichier; // Info about selected jointure file

  bool hasDeletedFile = false;
  bool _isLoading = false;
  IncidentCategory? _selectedCategory;

  void updateQuestion() async {
    setState(() => _isLoading = true);

    try {
      String? imageName;
      String? fileName;

      final question = await _questionFuture;

      // ✅ Update comment and selected action
      final updatedComment =
          _isEditingComment ? _commentController.text : question.commentaire;
      final updatedActionId =
          _isActionDropdownVisible && _selectedAction != null
              ? _selectedAction!.id
              : question.actionId;

      question.commentaire = updatedComment;
      question.actionId = updatedActionId;

      // ✅ Determine which images are newly added (not in _existingImageNames)
      final allImages = kIsWeb ? _webImages : _mobileImages;
      final newImages = allImages
          .where((img) => !_existingImageNames.contains(img.name))
          .toList();

      // ✅ Upload only if there's at least one new image
      if (newImages.isNotEmpty) {
        final XFile firstNewImage = newImages.first;

        if (kIsWeb) {
          final htmlFile = html.File(
            [await firstNewImage.readAsBytes()],
            firstNewImage.name,
          );
          imageName = await MissionService().uploadFileWeb(htmlFile);
        } else {
          imageName =
              await MissionService().uploadFile(File(firstNewImage.path));
        }

        question.fileName = imageName;
      }

      // ✅ Upload jointure file if it's new
      if (jointureFichier != null && question.jointureFichier == null) {
        fileName = kIsWeb
            ? await MissionService()
                .uploadJointureWeb(jointureFichier as html.File)
            : await MissionService().uploadJointure(jointureFichier as File);
        question.jointureFichier = fileName;
      }

      // ✅ Clear jointure if it was removed
      if (jointureFichier == null && question.jointureFichier == null) {
        question.jointureFichier = null;
      }

      final updatedQuestion = questionAnswerDto(
          id: widget.questionId,
          commentaire: question.commentaire,
          actionId: question.actionId,
          fileName: question.fileName, // Add the uploaded file path
          reponseID: question.reponseID,
          selectedResponseValue: question.selectedResponseValue,
          jointureFichier: question.fileName,
          typeIncident: _selectedCategory ?? widget.preSelectedType

      );
      // ✅ Update the question
      await MissionService()
          .updateMissionQuestion(widget.questionId, updatedQuestion, context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: AwesomeSnackbarContent(
            title: 'Success!',
            message: 'Question updated successfully.',
            contentType: ContentType.success,
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      );

      // ✅ Refresh data
      setState(() {
        _questionFuture =
            MissionService().getQuestionDetails(widget.questionId);
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: AwesomeSnackbarContent(
            title: 'Error!',
            message: 'Failed to update question: $error',
            contentType: ContentType.failure,
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      );
      setState(() => _isLoading = false);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<String> _existingImageNames = [];
  List<String> _existingFileNames = [];

  @override
  void initState() {
    super.initState();
    _questionFuture = MissionService().getQuestionDetails(widget.questionId);
    _actionsFuture = MissionService().getActions();

    _questionFuture.then((questionDetails) async {
      // Initialize comment controller
      _commentController.text = questionDetails.commentaire ?? '';

      // Load initial image(s) if present
      if (questionDetails.fileName != null &&
          questionDetails.fileName!.isNotEmpty) {
        await _fetchImage(questionDetails.fileName!);
        _existingImageNames.add(questionDetails.fileName!);
      }
      if (questionDetails.jointureFichier != null &&
          questionDetails.jointureFichier!.isNotEmpty){
        _existingFileNames.add(questionDetails.jointureFichier!);
      }

        setState(() {});
    }).catchError((error) {
      print('❌ Failed to fetch question details: $error');
    });
  }

  void selectFile() async {
    final result = await FilePicker.platform.pickFiles(
      withData: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt', 'csv', 'zip'], // ✅ allowed types
    );

    if (result != null && result.files.isNotEmpty) {
      infoFichier = result.files.first;

      // ✅ Size check: max 10MB
      const int maxSizeInBytes = 10 * 1024 * 1024;
      if (infoFichier!.size > maxSizeInBytes) {
        print("❌ Selected file is too large (${infoFichier!.size} bytes). Maximum allowed size is 10MB.");
        return;
      }

      if (kIsWeb && infoFichier!.bytes != null) {
        // ✅ Web: use the picked bytes directly (no corruption)
        jointureFichier = html.File([infoFichier!.bytes!], infoFichier!.name);
        print("📄 Web file selected: ${infoFichier!.name}");
        print("Size: ${infoFichier!.bytes!.length} bytes");
      } else if (!kIsWeb && infoFichier!.path != null) {
        // ✅ Mobile/Desktop
        jointureFichier = File(infoFichier!.path!);
        print("📄 Mobile file selected: ${infoFichier!.name}");
        print("Path: ${infoFichier!.path}");
      }

      setState(() {});
    } else {
      print("❌ File picking cancelled");
    }
  }


  Future<void> _fetchImage(String filename) async {
    try {
      final mimeType = lookupMimeType(filename) ?? 'image/jpeg';

      if (kIsWeb) {
        final bytes = await MissionService().getImageBytes(filename);
        if (bytes != null) {
          final xfile =
              XFile.fromData(bytes, name: filename, mimeType: mimeType);
          setState(() {
            _webImages.add(xfile);
          });
          print("✅ Image fetched (web): $filename");
        }
      } else {
        final file = await MissionService().getImage(filename);
        if (file != null) {
          final bytes = await file.readAsBytes();
          final xfile =
              XFile.fromData(bytes, name: filename, mimeType: mimeType);
          setState(() {
            _mobileImages.add(xfile);
          });
          print("✅ Image fetched (mobile): $filename");
        }
      }
    } catch (e) {
      print('❌ Failed to fetch image $filename: $e');
    }
  }

  void _showImageViewer(int index) {
    // final imageProvider = Image.file(_imageFiles[index].file).image;
    // showImageViewer(context, imageProvider,useSafeArea: true,immersive: false);
  }

  void _toggleImageSize() {
    setState(() {
      _isImageEnlarged = !_isImageEnlarged;
    });
  }

  Future<Map<String, dynamic>?> _showResponseEditDialog(
      int modeleReponse, int questionId) async {
    // Fetch the list of choices from the service
    var _listChoixReponse =
        await MissionService().getAllChoixReponse(modeleReponse);

    return await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text('Choisir réponse'),
              content: SingleChildScrollView(
                child: ListBody(
                  children: _listChoixReponse.map<Widget>((choix) {
                    return ListTile(
                      leading: Text(
                        choix.valeur.toString(),
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      title: Text(choix.libelle ?? 'Sans libellé'),
                      onTap: () {
                        // Return selected choice details
                        Navigator.of(context).pop({
                          'id': choix.id,
                          'libelle': choix.libelle,
                          'valeur': choix.valeur,
                          'color': choix.color
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  // Cancel selection
                  child: Text('Annuler'),
                ),
              ],
            );
          },
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

  Color? hexToColor(String? code) {
    if (code == null || code.isEmpty) {
      return null;
    }
    final hexCode = code.replaceAll('#', '');
    return Color(int.parse('FF$hexCode', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final imagesToShow = kIsWeb ? _webImages : _mobileImages;
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Modifier reponse '),
          leading: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.pop(context, true); // Navigate back
              }),
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
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18.0),
                        ),
                        SizedBox(height: 4),
                        Text('${question.description ?? 'No Description'}',
                            style: TextStyle(fontSize: 16.0)),
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
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18.0),
                                  ),
                                  SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${question.choixReponseQuestion!.valeur ?? 'No Response'}',
                                          style: TextStyle(
                                            fontSize: 16.0,
                                            color: hexToColor(question
                                                .choixReponseQuestion!.color),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          '${question.choixReponseQuestion!.libelle ?? 'No Response'}',
                                          style: TextStyle(
                                            fontSize: 16.0,
                                            color: hexToColor(question
                                                .choixReponseQuestion!.color),
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(Iconsax.edit),
                                        onPressed: () async {
                                          var selectedChoice =
                                              await _showResponseEditDialog(
                                                  widget.modeleReponseId,
                                                  question.id);
                                          if (selectedChoice != null) {
                                            setState(() {
                                              question.reponseID =
                                                  selectedChoice['id'];
                                              question.choixReponseQuestion!
                                                      .libelle =
                                                  selectedChoice['libelle'];
                                              question.choixReponseQuestion!
                                                      .valeur =
                                                  selectedChoice['valeur'];
                                              question.choixReponseQuestion!
                                                      .color =
                                                  selectedChoice['color'];
                                            }); // Refresh the UI
                                          }
                                        },
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
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18.0),
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
                                      controller: _commentController,
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
                    SizedBox(height: 16),
                    DropdownButtonFormField<IncidentCategory>(
                      decoration: InputDecoration(
                        labelText: "Catégorie d'incident",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                      ),
                      value: _selectedCategory ?? widget.preSelectedType, // ✅ Use the preselected if nothing chosen yet
                      items: IncidentCategory.values
                          .map((category) => DropdownMenuItem(
                        value: category,
                        child: Text(category.label),
                      ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value!;
                        });
                      },
                      validator: (value) =>
                      value == null ? "Veuillez sélectionner une catégorie" : null,
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
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18.0),
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
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  question.actionId = null;
                                  question.actions = null;
                                });
                              },
                              icon: Icon(Iconsax.trash),
                            ),
                          ],
                        ),
                        if (_isActionDropdownVisible)
                          FutureBuilder<List<ActionM>>(
                            future: _actionsFuture,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return Center(
                                    child: CircularProgressIndicator());
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
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                '${newActionDescription.isNotEmpty ? newActionDescription : (currentAction?.description ?? 'No Action Description')}',
                                                softWrap: true,
                                                maxLines: null,
                                                style: TextStyle(
                                                    overflow:
                                                        TextOverflow.visible),
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
                                            color:
                                                Colors.black.withOpacity(0.5),
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
                        SizedBox(height: 10),
                        if (question.jointureFichier != null) ...[
                          Text(
                            'Cette réponse contient un fichier joint :',
                            style: TextStyle(
                                fontSize: 16.0, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () => _downloadFile(
                                question.jointureFichier!, context),
                            icon: Icon(Icons.download),
                            label: Text('Télécharger le fichier'),
                            style: ElevatedButton.styleFrom(
                                minimumSize: Size(double.infinity, 50)),
                          ),
                          SizedBox(height: 10),
                          ElevatedButton.icon(
                            onPressed: () {
                              deleteFileByName(
                                  question.jointureFichier!, context);
                              setState(() {
                                question.jointureFichier = null;
                                jointureFichier = null;
                                hasDeletedFile = true;
                              });
                            },
                            icon: Icon(Icons.delete),
                            label: Text('Supprimer le fichier'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: Size(double.infinity, 50),
                              backgroundColor: Colors.red,
                            ),
                          ),
                        ] else if (jointureFichier != null &&
                            infoFichier != null) ...[
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.attach_file,
                                          color: Colors.blue),
                                      SizedBox(width: 8),
                                      Text(
                                        "Fichier joint :",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16),
                                      ),
                                      Spacer(),
                                      IconButton(
                                        icon: Icon(Icons.close,
                                            color: Colors.red),
                                        onPressed: () {
                                          setState(() {
                                            jointureFichier = null;
                                            infoFichier = null;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  Text("Nom: ${infoFichier?.name}"),
                                  Text(
                                      "Taille: ${(infoFichier!.size / 1024).toStringAsFixed(2)} KB"),
                                  Text(
                                      "Type: ${infoFichier?.extension ?? 'Inconnu'}"),
                                ],
                              ),
                            ),
                          )
                        ] else ...[
                          ElevatedButton.icon(
                            onPressed: selectFile,
                            icon: Icon(Icons.attach_file),
                            label: Text('Ajouter un fichier'),
                            style: ElevatedButton.styleFrom(
                                minimumSize: Size(double.infinity, 50)),
                          ),
                        ]
                      ],
                    ),
                    SizedBox(height: 20),
                    if (imagesToShow.isNotEmpty) ...[
                      ImageSlideshow(
                        width: double.infinity,
                        height: 300,
                        initialPage: 0,
                        indicatorColor: Colors.blue,
                        indicatorBackgroundColor: Colors.grey,
                        isLoop: true,
                        children: imagesToShow.asMap().entries.map((entry) {
                          final index = entry.key;
                          final imageFile = entry.value;

                          return Stack(
                            children: [
                              Container(
                                margin: EdgeInsets.symmetric(horizontal: 8.0),
                                child: GestureDetector(
                                  onTap: () {
                                    if (!kIsWeb) _showImageViewer(index);
                                  },
                                  child: kIsWeb
                                      ? FutureBuilder<Uint8List>(
                                          future: imageFile.readAsBytes(),
                                          builder: (context, snapshot) {
                                            if (snapshot.connectionState ==
                                                    ConnectionState.done &&
                                                snapshot.hasData) {
                                              return Image.memory(
                                                snapshot.data!,
                                                fit: BoxFit.cover,
                                                width: double.infinity,
                                              );
                                            } else {
                                              return Center(
                                                  child:
                                                      CircularProgressIndicator());
                                            }
                                          },
                                        )
                                      : Image.file(
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
                                  icon: Icon(Iconsax.trash, color: Colors.red),
                                  onPressed: () async {
                                    final images =
                                        kIsWeb ? _webImages : _mobileImages;
                                    final imageName = images[index].name;

                                    final isAlreadyUploaded =
                                        _existingImageNames.contains(imageName);

                                    if (isAlreadyUploaded) {
                                      try {
                                        await MissionService()
                                            .deleteImage(imageName);
                                        setState(() {
                                          images.removeAt(index);
                                          _existingImageNames.remove(
                                              imageName); // Also clean it from the tracked list
                                        });
                                        print(
                                            "🗑️ Deleted image from server: $imageName");
                                      } catch (e) {
                                        print(
                                            "❌ Failed to delete image $imageName: $e");
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text(
                                                  'Failed to delete image from server')),
                                        );
                                      }
                                    } else {
                                      // Local-only image, safe to just remove
                                      setState(() {
                                        images.removeAt(index);
                                      });
                                      print(
                                          "🗑️ Removed local image: $imageName");
                                    }
                                  },
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ] else ...[
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
                      /*
                      OutlinedButton.icon(
                        onPressed: () {
                          if (kIsWeb) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text('Camera is not supported on web.')),
                            );
                          } else {
                            _openCamera();
                          }
                        },
                        icon: Icon(Icons.camera_alt, size: 24),
                        label: Text('Ouvrir Camera'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: Size(double.infinity, 48),
                        ),
                      )
                      */
                    ],
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        _isLoading ? null : updateQuestion();
                      },
                      child: _isLoading
                          ? CircularProgressIndicator(
                              color: Colors.white,
                            )
                          : Text('Enregistrer'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(
                            double.infinity, 50), // Full width and fixed height
                      ),
                    )
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickImages() async {
    if (kIsWeb) {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.image,
        withData: true,
      );

      if (result != null) {
        setState(() {
          _webImages.addAll(result.files.map((file) {
            return XFile.fromData(file.bytes!,
                name: file.name, mimeType: file.extension);
          }));
        });
        print("🖼️ ${_webImages.length} images selected (web)");
      }
    } else {
      final selected = await _picker.pickMultiImage();
      if (selected != null && selected.isNotEmpty) {
        setState(() {
          _mobileImages.addAll(selected);
        });
        print("🖼️ ${_mobileImages.length} images selected (mobile)");
      }
    }
  }

  void _openCamera() async {}

  void _removeImage(int index) {
    setState(() {
      if (kIsWeb) {
        _webImages.removeAt(index);
      } else {
        _mobileImages.removeAt(index);
      }
    });
  }

  Future<String> uploadFile(File file) async {
    try {
      // Call the MissionService's uploadJointure method to upload the file
      final String uploadedFileName =
          await MissionService().uploadJointure(file);

      // Return the uploaded file's name
      return uploadedFileName; // No need to access as a Map, just return the file name
    } catch (e) {
      // Handle errors, e.g., if the upload fails
      print('Error during file upload: $e');
      return ''; // Return an empty string or a custom error message if needed
    }
  }

  void _addFile() {}

  void deleteFileByName(String fileName, BuildContext context) async {
    try {
      // Use the MissionService to delete the file
      await MissionService().deleteFile(fileName);

      // Show a success notification
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('File "$fileName" deleted successfully.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      // Show an error notification
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete file "$fileName": $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _downloadFile(String fileName, BuildContext context) async {
    try {
      if (kIsWeb) {
        // ✅ Web: Download via browser
        final bytes = await MissionService().getFileBytes(fileName);
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);

        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', fileName)
          ..click();

        html.Url.revokeObjectUrl(url);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Fichier téléchargé via le navigateur.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        // ✅ Mobile: Download using service and save to Downloads
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Permission de stockage refusée.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
          return;
        }

        final tempFilePath = await MissionService().downloadFile(fileName);
        final tempFile = File(tempFilePath);

        // ✅ Downloads directory (fallback if needed)
        final downloadsDir = Directory('/storage/emulated/0/Download');
        if (!downloadsDir.existsSync()) {
          await downloadsDir.create(recursive: true);
        }

        final destinationPath = '${downloadsDir.path}/$fileName';
        await tempFile.copy(destinationPath);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Fichier téléchargé : $destinationPath'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        print('📥 File saved at: $destinationPath');
      }
    } catch (e) {
      print('❌ Error downloading file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur lors du téléchargement: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }



}

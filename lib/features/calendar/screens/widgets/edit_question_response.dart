import 'dart:io';
import 'dart:typed_data';

import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:easy_image_viewer/easy_image_viewer.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supervisormobile/features/calendar/models/questionMissionModel.dart';
import 'package:supervisormobile/features/calendar/models/actionsModel.dart';
import 'package:supervisormobile/features/calendar/screens/widgets/captureImageScreen.dart';
import 'package:supervisormobile/features/calendar/screens/widgets/questionResponse.dart';
import 'package:supervisormobile/features/calendar/services/missionService.dart';
import 'package:flutter_image_slideshow/flutter_image_slideshow.dart';

import '../../DTOs/FileInfo.dart';
import 'package:permission_handler/permission_handler.dart';

class EditQuestionResponse extends StatefulWidget {
  final int questionId;
  final int modeleReponseId;

  const EditQuestionResponse({Key? key, required this.questionId,required this.modeleReponseId})
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
  List<FileInfo> _images = [];
  final ImagePicker _picker = ImagePicker();
  List<XFile>? _imageFiles = [];
  File? jointureFichier;
  PlatformFile? infoFichier;
  bool hasDeletedFile = false;
  bool _isLoading = false;

  void updateQuestion() async {
    setState(() => _isLoading = true);

    try {
      String? imageName;
      String? fileName;

      final question = await _questionFuture;

      final updatedComment = _isEditingComment ? _commentController.text : question.commentaire;
      final updatedActionId = _isActionDropdownVisible && _selectedAction != null ? _selectedAction!.id : question.actionId;

      question.commentaire = updatedComment;
      question.actionId = updatedActionId;
      if(_images.isEmpty && _imageFiles!.isNotEmpty) {
        final firstFile = _imageFiles!.first;
        imageName = await MissionService().uploadFile(File(firstFile.path));
        question.fileName = imageName;
      }
      if(jointureFichier != null && question.jointureFichier == null){
        fileName = await MissionService().uploadJointure(jointureFichier!);
        question.jointureFichier = fileName;
      }
      if(jointureFichier == null && question.jointureFichier == null){
        question.jointureFichier = null;
      }




      await MissionService().updateMissionQuestion(widget.questionId, question,context);

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

      setState(() {
        _questionFuture = MissionService().getQuestionDetails(widget.questionId);
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




  @override
  void initState() {
    super.initState();
    _questionFuture = MissionService().getQuestionDetails(widget.questionId);
    _actionsFuture = MissionService().getActions();
    _questionFuture.then((questionDetails) {
      _commentController.text = questionDetails.commentaire ?? ''; // Initialize the controller
    }).catchError((error) {
      print('Failed to fetch question details: $error');
    });
    _questionFuture.then((questionDetails) {
      if (questionDetails.fileName != null && questionDetails.fileName!.isNotEmpty) {
        _fetchImage(questionDetails.fileName!);
      }
    }).catchError((error) {
      print('Failed to fetch question details: $error');
    });
  }

  void selectFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      jointureFichier = File(result.files.single.path!);

      infoFichier = result.files.first;

      print(infoFichier?.name);
      print(infoFichier?.bytes);
      print(infoFichier?.size);
      print(infoFichier?.extension);
      print(infoFichier?.path);
      setState(() {});
    } else {
      // User canceled the picker
    }
  }

  Future<void> _fetchImage(String filename) async {
    try {
      final file = await MissionService().getImage(filename);
      setState(() {
        if(file != null) {
          final fileInfo = FileInfo(file: file,name: filename);
          _images?.add(fileInfo); // Add to the image list for slideshow

        }

      });
    } catch (e) {
      print('Failed to fetch image: $e');
      setState(() {
        _imageFile = null;
      });
    }
  }

  void _showImageViewer(int index) {
    final imageProvider = Image.file(_images[index].file).image;
    showImageViewer(context, imageProvider,useSafeArea: true,immersive: false);
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
                          'color':choix.color
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null), // Cancel selection
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
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Modifier reponse '),
          leading: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.pop(context,true); // Navigate back
              }
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
                                          '${question.choixReponseQuestion!.valeur ?? 'No Response'}',
                                          style: TextStyle(
                                            fontSize: 16.0,
                                            color: hexToColor(question.choixReponseQuestion!.color),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          '${question.choixReponseQuestion!.libelle ?? 'No Response'}',
                                          style: TextStyle(
                                            fontSize: 16.0,
                                            color: hexToColor(question.choixReponseQuestion!.color),
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(Iconsax.edit),
                                        onPressed: () async {
                                          var selectedChoice = await _showResponseEditDialog(widget.modeleReponseId, question.id);
                                          if (selectedChoice != null) {
                                            setState(() {
                                              question.reponseID = selectedChoice['id'];
                                              question.choixReponseQuestion!.libelle = selectedChoice['libelle'];
                                              question.choixReponseQuestion!.valeur = selectedChoice['valeur'];
                                              question.choixReponseQuestion!.color = selectedChoice['color'];
                                            }); // Refresh the UI
                                          }
                                        },                                      ),
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
                                                softWrap: true,
                                                maxLines: null,
                                                style: TextStyle(overflow: TextOverflow.visible),
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
                        SizedBox(height: 10),
                        if (question.jointureFichier != null) ...[
                          Text(
                            'Cette réponse contient un fichier joint :',
                            style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () {
                              // Logic to download the file
                              _downloadFile(question.jointureFichier!,context);
                            },
                            icon: Icon(Icons.download),
                            label: Text('Télécharger le fichier'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: Size(double.infinity, 50),
                            ),
                          ),
                          SizedBox(height: 10),
                          ElevatedButton.icon(
                            onPressed: () {
                              // Logic to delete the file
                              deleteFileByName(question.jointureFichier!,context);
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
                        ] else
                          if (jointureFichier != null && infoFichier != null) ...[
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      children: [
                                        // Adding an icon for the file attachment
                                        Icon(
                                          Icons.attach_file,
                                          // Attach file icon
                                          color:
                                          Colors.blue, // Color for the icon
                                        ),
                                        SizedBox(width: 8),
                                        // Bold text for the "Fichier joint" label
                                        Text(
                                          "Fichier joint :",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            // Bolder text
                                            fontSize:
                                            16, // Optional: Adjust the font size for emphasis
                                          ),
                                        ),
                                        Spacer(),
                                        // Pushes the "X" button to the right
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
                          ] else ... [

                            ElevatedButton.icon(
                              onPressed: selectFile,
                              icon: Icon(Icons.attach_file),
                              label: Text('Ajouter un fichier'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: Size(double.infinity, 50),
                              ),
                            ),
                          ]


                      ],
                    ),



                    SizedBox(height: 20),
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
                                    _removeImageFile(index);
                                  },
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ],
                    if (_images!.isNotEmpty && _imageFiles!.isEmpty) ...[
                      Text(
                        'Cette réponse contient une image :',
                        style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                      ),
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
                          final index = _images.indexOf(image); // Get the index of the image
                          return SafeArea(
                            child: GestureDetector(
                              onTap: () => _showImageViewer(index),
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: Image.file(
                                      image.file,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 10,
                                    right: 10,
                                    child: IconButton(
                                      icon: Icon(Iconsax.trash, color: Colors.red, size: 30),
                                      onPressed: () {
                                        setState(() {
                                           _removeImageXFile(index,image.name);
                                          _images.removeAt(index); // Remove the selected image
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ] else ... [
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
                      )
                    ],
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        _isLoading ? null : updateQuestion() ;
                      },
                      child: _isLoading
                          ? CircularProgressIndicator(
                        color: Colors.white,
                      )
                          : Text('Enregistrer'),
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
      ),
    );
  }

  Future<void> _pickImages() async {
    final List<XFile>? selectedImages = await _picker.pickMultiImage();
    if (selectedImages != null) {
      setState(() {
        _imageFiles = selectedImages;
      });
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
  Future<void> _removeImageXFile(int index, String imageName) async {
    await MissionService().deleteImage(imageName);

    setState(() {
      _imageFiles!.removeAt(index);
    });
  }
  void _removeImageFile(int index) {

    setState(() {
      _images.removeAt(index);
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
      // Request storage permissions
      var status = await Permission.storage.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Storage permission denied.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      // Download the file to a temporary location
      String tempFilePath = await MissionService().downloadFile(fileName);
      File tempFile = File(tempFilePath);

      // Get the system's Downloads directory
      Directory downloadsDir = Directory('/storage/emulated/0/Download');

      if (!downloadsDir.existsSync()) {
        throw Exception('Downloads directory not found.');
      }

      // Move the file to the Downloads directory
      String destinationPath = "${downloadsDir.path}/$fileName";
      File destinationFile = tempFile.copySync(destinationPath);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('File downloaded successfully: $destinationPath'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      print('File downloaded successfully at: $destinationPath');
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error downloading file: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );

      print('Error downloading file: $e');
    }
  }



}


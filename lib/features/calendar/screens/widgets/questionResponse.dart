import 'dart:io';
import 'dart:typed_data';
import 'dart:html' as html;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
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
import 'dart:io' as io; // for mobile File

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
  ChoixReponseQuestion? reponse;
  int? selectedResponseID;
  int? selectedResponseVallue;
  bool _showAdditionalWidgets = false;
  List<ActionM> _actions = [];
  final ImagePicker _picker = ImagePicker();
  List<XFile>? _imageFiles;
  dynamic jointureFichier;
  PlatformFile? infoFichier;
  bool _isLoading = false;
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
    setState(() => _isLoading = true);

    String? imageName;
    String? fileName;

    // 🔧 Upload the first image if available
    if (_imageFiles != null && _imageFiles!.isNotEmpty) {
      try {
        if (kIsWeb) {
          // Use _webImageFiles instead of XFile
          final webFile = _webImageFiles!.first;
          imageName = await MissionService().uploadFileWeb(webFile);
          print("Uploaded Image (Web): $imageName");
        } else {
          final firstFile = _imageFiles!.first;
          imageName = await MissionService().uploadFile(File(firstFile.path));
          print("Uploaded Image (Mobile): $imageName");
        }
      } catch (e, stackTrace) {
        print('❌ Upload image failed: $e');
        print('📛 Stack trace: $stackTrace');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image file')),
        );
        setState(() => _isLoading = false);
      }

      }


    // 🔧 Upload jointure file
    if (jointureFichier != null) {
      try {
        print("📄 Uploading jointure file: ${kIsWeb ? (jointureFichier as html.File).name : (jointureFichier as File).path}");

        if (kIsWeb) {
          // Ensure jointureFichier is an html.File
          if (jointureFichier is html.File) {
            fileName = await MissionService().uploadJointureWeb(jointureFichier);
            print("✅ Jointure uploaded (web): $fileName");
          } else {
            throw Exception("Invalid jointure file type for web");
          }
        } else {
          // Ensure jointureFichier is a dart.io File
          if (jointureFichier is File) {
            fileName = await MissionService().uploadJointure(jointureFichier);
            print("✅ Jointure uploaded (mobile): $fileName");
          } else {
            throw Exception("Invalid jointure file type for mobile");
          }
        }
      } catch (e, stackTrace) {
        print('❌ Jointure upload failed: $e');
        print('📛 Stack trace: $stackTrace');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload jointure fichier')),
        );
        setState(() => _isLoading = false);
        return;
      }
    }



    final updatedQuestion = QuestionMission(
      id: widget.questionId,
      commentaire: _commentController.text,
      actionId: _selectedAction?.id,
      fileName: imageName,
      reponseID: selectedResponseID,
      selectedResponseValue: selectedResponseVallue,
      jointureFichier: fileName,
    );

    try {
      await MissionService().updateMissionQuestion(updatedQuestion.id, updatedQuestion, context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Question updated successfully')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update question')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }



  void selectFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      withData: true, // crucial for Web
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt', 'csv', 'zip'], // ✅ allowed file types
    );

    if (result != null && result.files.isNotEmpty) {
      infoFichier = result.files.first;

      // ✅ Check file size before proceeding (max 10MB)
      const int maxSizeInBytes = 10 * 1024 * 1024; // 10MB
      if (infoFichier!.size > maxSizeInBytes) {
        print("❌ Selected file is too large (${infoFichier!.size} bytes). Maximum allowed size is 10MB.");
        // You can also show a toast/snackbar here if needed
        return;
      }

      if (kIsWeb && infoFichier!.bytes != null) {
        // ✅ Correct: use the picked file bytes directly, do not recreate unnecessarily
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






  void _onActionChanged(ActionM? newValue) {
    setState(() {
      _selectedAction = newValue;
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
  List<html.File>? _webImageFiles;

  Future<void> _pickImages() async {
    if (kIsWeb) {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.image,
        withData: true,
      );

      if (result != null) {
        setState(() {
          _imageFiles = result.files.map((file) {
            return XFile.fromData(
              file.bytes!,
              name: file.name,
              mimeType: file.extension,
            );
          }).toList();

          // Store raw web files for upload
          _webImageFiles = result.files.map((file) {
            return html.File([file.bytes!], file.name); // ✅ CORRECT
          }).toList();

        });

        print("🖼️ ${_imageFiles!.length} images selected (web)");
      }
    } else {
      final List<XFile>? selectedImages = await _picker.pickMultiImage();

      if (selectedImages != null && selectedImages.isNotEmpty) {
        setState(() {
          _imageFiles = selectedImages;
        });

        print("🖼️ ${_imageFiles!.length} images selected (mobile)");
      }
    }
  }



  void _showImageViewer(int index) {
    if (_imageFiles != null && _imageFiles!.isNotEmpty) {
      final imageProvider = FileImage(File(_imageFiles![index].path));

    }
  }

  void _openCamera() async {

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
                                  selectedResponseID = newValue?.id;
                                  selectedResponseVallue = newValue
                                      ?.valeur; // Assuming `id` is the identifier for the response
                                  reponse = newValue ;
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

                            // Add the "None" option at the start of the list
                            final noneAction =
                                ActionM(id: 0, description: 'Aucune action');
                            final allActions = [noneAction, ...actions];

                            return CustomDropdown<ActionM>.search(
                              hintText: 'Select Action',
                              items: allActions,
                              excludeSelected: false,
                              onChanged: (value) {
                                // Handle the "None" option when selected
                                if (value?.id == -1) {
                                  _selectedAction = null; // Deselect logic
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
                                  Flexible(
                                    // Use Flexible to allow the Text to wrap
                                    child: Text(
                                      'Action: ${_selectedAction?.description ?? ''}',
                                      softWrap: true,
                                      // Allows text to break into multiple lines
                                      overflow: TextOverflow
                                          .visible, // Makes sure the overflow is handled
                                    ),
                                  ),
                                ],
                              )
                            : SizedBox.shrink(),
                        // Returns an empty widget when _selectedAction is null

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
                          onPressed: selectFile,
                          icon: Icon(Icons.add, size: 24),
                          label: Text('Fichier'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: Size(double.infinity, 48),
                          ),
                        ),
                        SizedBox(height: 16),
/*
                        OutlinedButton.icon(
                          onPressed: _openCamera,
                          icon: Icon(Icons.camera_alt, size: 24),
                          label: Text('Ouvrir Camera'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: Size(double.infinity, 48),
                          ),
                        ),
                        */

                        SizedBox(height: 16),
                        if (infoFichier != null) ...[
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.attach_file, color: Colors.blue),
                                      const SizedBox(width: 8),
                                      const Text(
                                        "Fichier joint :",
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      const Spacer(),
                                      IconButton(
                                        icon: const Icon(Icons.close, color: Colors.red),
                                        onPressed: () {
                                          setState(() {
                                            jointureFichier = null;
                                            infoFichier = null;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text("Nom : ${infoFichier!.name}"),
                                  Text(
                                    "Taille : ${infoFichier!.size != null ? (infoFichier!.size / 1024).toStringAsFixed(2) : 'N/A'} KB",
                                  ),
                                  Text("Type : ${infoFichier!.extension ?? 'Inconnu'}"),
                                  if (!kIsWeb && jointureFichier != null) ...[
                                    const SizedBox(height: 8),
                                    Text("Chemin : ${jointureFichier!.path}"),
                                  ],
                                ],
                              ),
                            ),
                          )
                        ],


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
                                    margin: EdgeInsets.symmetric(horizontal: 8.0),
                                    child: GestureDetector(
                                      onTap: () {
                                        if (!kIsWeb) _showImageViewer(index); // Disable for web
                                      },
                                      child: kIsWeb
                                          ? FutureBuilder<Uint8List>(
                                        future: imageFile.readAsBytes(),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState == ConnectionState.done &&
                                              snapshot.hasData) {
                                            return Image.memory(
                                              snapshot.data!,
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                            );
                                          } else {
                                            return Center(child: CircularProgressIndicator());
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
                                      onPressed: () => _removeImage(index),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ],

                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _submitForm,
                          // Disable button when loading
                          child: _isLoading
                              ? CircularProgressIndicator(
                            color: Colors.white,
                          )
                              : Text('Valider'),
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

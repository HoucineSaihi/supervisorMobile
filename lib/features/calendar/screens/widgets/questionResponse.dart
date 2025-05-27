import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:easy_image_viewer/easy_image_viewer.dart';
import 'package:file_picker/file_picker.dart';
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
import 'package:path_provider/path_provider.dart';
import 'package:supervisormobile/features/incidents/models/IncidentCategory.dart';

import '../../../../dtos/questions/questionAnswerDto.dart'; // For accessing the temp directory

class QuestionResponseWidget extends StatefulWidget {
  final int questionId;
  final int modelResponseID;
  final IncidentCategory preSelectedType;

  const QuestionResponseWidget(
      {Key? key, required this.questionId, required this.modelResponseID, required this.preSelectedType})
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
  File? jointureFichier;
  PlatformFile? infoFichier;
  bool _isLoading = false;
  IncidentCategory? _selectedCategory;
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
 /*
    if( reponse!.incident == true && _commentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Commentaire obligatoire en cas d'incident.")),
      );
      setState(() => _isLoading = false);

      return ;
    } */

    if (selectedResponseID != null) {
      String? imageName;
      String? fileName;
      // Check if there are image files and upload the first one if it exists
      if (_imageFiles != null && _imageFiles!.isNotEmpty) {
        try {
          final firstFile = _imageFiles!.first;
          imageName = await MissionService().uploadFile(File(firstFile.path));
          print("\n File Name ----------------------------------------------- \n" + imageName);
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to upload image file')),
          );
          return; // Stop execution if image upload fails
        }
      }

      // Check if a file is selected and upload it if present
      if (jointureFichier != null) {
        try {
          fileName = await MissionService().uploadJointure(jointureFichier!);
          print("\n Jointure Fichier ----------------------------------------- \n" + fileName);
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to upload jointure fichier')),
          );
          return; // Stop execution if jointure fichier upload fails
        }
      }

      // Create the updated question object
      final updatedQuestion = questionAnswerDto(
        id: widget.questionId,
        commentaire: _commentController.text,
        actionId: _selectedAction?.id,
        fileName: imageName, // Add the uploaded file path
        reponseID: selectedResponseID,
        selectedResponseValue: selectedResponseVallue,
        jointureFichier: fileName,
        typeIncident: _selectedCategory ?? widget.preSelectedType

      );

      print("-----------------------------------Valeur JSON \n");
      print(updatedQuestion.actionId);
      print(updatedQuestion.reponseID);
      print(updatedQuestion.fileName);
      print(selectedResponseVallue);

      try {
        await MissionService().updateMissionQuestion(widget.questionId, updatedQuestion,context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Question updated successfully')),
        );
        Navigator.pop(context, true); // Navigate back
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update question')),
        );
        setState(() => _isLoading = false);
      }
      finally {
        setState(() => _isLoading = false); // Stop loader
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Séléctionner une réponse.')),
      );
    }
  }


  void selectFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt', 'csv', 'zip'], // ✅ Only allowed types
    );

    if (result != null && result.files.isNotEmpty) {
      infoFichier = result.files.first;

      // ✅ Size check: max 10MB
      const int maxSizeInBytes = 5 * 1024 * 1024; // 5MB
      if (infoFichier!.size > maxSizeInBytes) {
        print("❌ Selected file is too large (${infoFichier!.size} bytes). Maximum allowed size is 5MB.");
        return;
      }

      if (infoFichier!.path != null) {
        jointureFichier = File(infoFichier!.path!);
        print("📄 Mobile file selected: ${infoFichier!.name}");
        print("Size: ${infoFichier!.size} bytes");
        print("Extension: ${infoFichier!.extension}");
        print("Path: ${infoFichier!.path}");
      } else {
        print("❌ No valid file path.");
        return;
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

  Future<void> _pickImages() async {
    final List<XFile>? selectedImages = await _picker.pickMultiImage();

    if (selectedImages != null && selectedImages.isNotEmpty) {
      const int maxImageSizeInBytes = 5 * 1024 * 1024; // 5MB limit
      final allowedExtensions = ['jpg', 'jpeg', 'png'];

      List<XFile> filteredImages = [];

      for (final image in selectedImages) {
        final extension = image.name.split('.').last.toLowerCase();
        final isValidExtension = allowedExtensions.contains(extension);

        if (isValidExtension) {
          final fileSize = await image.length(); // ✅ Async correct size check
          if (fileSize <= maxImageSizeInBytes) {
            filteredImages.add(image);
          } else {
            print("❌ Image ${image.name} is too large (${fileSize} bytes). Skipped.");
          }
        } else {
          print("❌ Image ${image.name} has unsupported format. Skipped.");
        }
      }

      if (filteredImages.isEmpty) {
        print("❌ No valid images selected. Only JPG, JPEG, PNG under 5MB are allowed.");
        return;
      }

      setState(() {
        _imageFiles = filteredImages;
      });

      print("📷 Selected ${filteredImages.length} valid image(s).");
    } else {
      print("❌ No images selected.");
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

                        OutlinedButton.icon(
                          onPressed: _openCamera,
                          icon: Icon(Icons.camera_alt, size: 24),
                          label: Text('Ouvrir Camera'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: Size(double.infinity, 48),
                          ),
                        ),
                        SizedBox(height: 16),
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

import 'dart:io';
import 'dart:typed_data';
import 'dart:html' as html;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_slideshow/flutter_image_slideshow.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supervisormobile/features/authentification/services/login_service.dart';
import 'package:supervisormobile/features/calendar/models/Problem.dart';
import 'package:supervisormobile/features/calendar/models/boutiqueModel.dart';
import 'package:supervisormobile/features/calendar/screens/widgets/captureImageScreen.dart';
import 'package:supervisormobile/features/calendar/services/missionService.dart';
import 'package:supervisormobile/features/incidents/models/Coefficient.dart';
import 'package:supervisormobile/features/incidents/services/incident_service.dart';
import 'package:supervisormobile/utils/constants/colors.dart';

class IncidentFormWidget extends StatefulWidget {
  @override
  _IncidentFormWidgetState createState() => _IncidentFormWidgetState();
}

class _IncidentFormWidgetState extends State<IncidentFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _commentController = TextEditingController();

  List<BoutiqueModel> _boutiques = [];
  List<Coefficient> _priorities = [];

  final ImagePicker _picker = ImagePicker();
  List<XFile>? _imageFiles;
  dynamic jointureFichier;
  PlatformFile? infoFichier;

  BoutiqueModel? _selectedBoutique;

  Coefficient? _selectedPriority;

  final _storage = FlutterSecureStorage();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    MissionService().getBoutiques().then((boutiques) {
      setState(() {
        _boutiques = boutiques; // Update the boutique list
      });
    });

    IncidentService().getAllCoefficients().then((coefficients) {
      setState(() {
        _priorities = coefficients; // Update the priorities list
      });
    });
  }

  void selectFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      withData: true, // this is crucial for Web
    );

    if (result != null) {
      infoFichier = result.files.first;

      if (kIsWeb) {
        // Store as html.File for later upload
        jointureFichier = html.File(
          infoFichier!.bytes!,
          infoFichier!.name,
        );
        print("📄 Web file selected: ${infoFichier!.name}");
        print("Size: ${infoFichier!.bytes?.length} bytes");
      } else {
        // Mobile/Desktop
        jointureFichier = File(result.files.single.path!);
        print("📄 Mobile file selected: ${infoFichier!.name}");
        print("Path: ${infoFichier!.path}");
      }

      setState(() {});
    } else {
      print("❌ File picking cancelled");
    }
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

  void _openCamera() async {}

  void _removeImage(int index) {
    setState(() {
      _imageFiles!.removeAt(index);
    });
  }

  void _submitForm() async {
    if (_selectedBoutique != null &&
        _selectedPriority != null &&
        _commentController.text.isNotEmpty &&
        _descriptionController.text.isNotEmpty) {
      setState(() => _isLoading = true);

      String? imageName;
      String? fileName;

      try {
        // ✅ Upload image (first one only)
        final imageList = kIsWeb ? _webImageFiles : _imageFiles;
        if (imageList != null && imageList.isNotEmpty) {
          try {
            if (kIsWeb) {
              final webFile = _webImageFiles!.first;
              imageName = await MissionService().uploadFileWeb(webFile);
              print("✅ Image uploaded (web): $imageName");
            } else {
              final mobileFile = File(_imageFiles!.first.path);
              imageName = await MissionService().uploadFile(mobileFile);
              print("✅ Image uploaded (mobile): $imageName");
            }
          } catch (e, stack) {
            print('❌ Image upload failed: $e\n📛 $stack');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Échec de l’envoi de l’image')),
            );
            setState(() => _isLoading = false);
            return;
          }
        }

        // ✅ Upload jointure file
        if (jointureFichier != null) {
          try {
            if (kIsWeb && jointureFichier is html.File) {
              fileName =
                  await MissionService().uploadJointureWeb(jointureFichier);
              print("✅ Jointure uploaded (web): $fileName");
            } else if (!kIsWeb && jointureFichier is File) {
              fileName = await MissionService().uploadJointure(jointureFichier);
              print("✅ Jointure uploaded (mobile): $fileName");
            } else {
              throw Exception("❌ Type de fichier jointure non supporté.");
            }
          } catch (e, stack) {
            print('❌ Jointure upload failed: $e\n📛 $stack');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Échec de l’envoi du fichier joint')),
            );
            setState(() => _isLoading = false);
            return;
          }
        }

        // ✅ Get current user ID from secure storage
        final storage = SecureStorageService();
        final loginData = await storage.getLoginData();
        final userIdString = loginData['currentUserId'];
        final userId = int.tryParse(userIdString ?? '') ?? 0;

        // ✅ Construct the problem object
        final declaredProblem = Problem(
          id: 0,
          user_id: userId,
          boutique_id: _selectedBoutique!.id,
          coef_id: _selectedPriority!.coefId,
          problem_image_before: imageName,
          joint_file_before: fileName,
          commentaire: _commentController.text,
          description: _descriptionController.text,
          cluster: _selectedBoutique!.cluster,
        );

        print("📦 Problem submitted: ${declaredProblem.toJson()}");

        // ✅ Submit to API
        await IncidentService().addProblem(declaredProblem);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Incident ajouté avec succès.')),
        );
        Navigator.pop(context, true); // Go back
      } catch (e) {
        print('❌ Error submitting problem: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossible de soumettre l’incident.')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Veuillez remplir tous les champs obligatoires.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Ajouter un incident",
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16.0),
                DropdownButtonFormField<BoutiqueModel>(
                  decoration: InputDecoration(
                    labelText: "Boutique",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  items: _boutiques
                      .map((boutique) => DropdownMenuItem<BoutiqueModel>(
                            value: boutique,
                            child: Text(
                                boutique.libelle!), // Display boutique name
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedBoutique =
                          value; // Store selected boutique name or any unique identifier
                    });
                  },
                  validator: (value) => value == null
                      ? "Veuillez sélectionner une boutique"
                      : null,
                ),

                const SizedBox(height: 16.0),

                // Description TextField
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: "Description",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  validator: (value) => value!.isEmpty
                      ? "Veuillez fournir une description de l’incident"
                      : null,
                ),
                const SizedBox(height: 16.0),

                // Commentaire TextField
                TextFormField(
                  controller: _commentController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: "Commentaire",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? "Veuillez fournir un commentaire" : null,
                ),
                const SizedBox(height: 16.0),

                Text('Joindre des images',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                const SizedBox(height: 16.0),
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
                                color: Colors.blue, // Color for the icon
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
                                icon: Icon(Icons.close, color: Colors.red),
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
                          Text("Type: ${infoFichier?.extension ?? 'Inconnu'}"),
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
                    onPageChanged: (value) => print('Page changed: $value'),
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
                                if (!kIsWeb)
                                  _showImageViewer(
                                      index); // Optional: viewer only on mobile
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
                              onPressed: () => _removeImage(index),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 16.0),

                // Priority Dropdown
                DropdownButtonFormField<Coefficient>(
                  decoration: InputDecoration(
                    labelText: "Priorité",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  items: _priorities
                      .map((priority) => DropdownMenuItem<Coefficient>(
                            value: priority,
                            child: Text(priority.libelle ??
                                "Unknown"), // Display priority label
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedPriority =
                          value; // Store selected priority name or any unique identifier
                    });
                  },
                  validator: (value) => value == null
                      ? "Veuillez sélectionner une priorité"
                      : null,
                ),

                const SizedBox(height: 24.0),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading == true ? null : _submitForm,
                    // Disable button when loading
                    child: _isLoading
                        ? CircularProgressIndicator(
                            color: Colors.white,
                          )
                        : Text('Soumettre'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 48),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

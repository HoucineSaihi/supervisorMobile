import 'dart:io';
import 'dart:typed_data';

import 'package:easy_image_viewer/easy_image_viewer.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_slideshow/flutter_image_slideshow.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supervisormobile/features/calendar/models/Problem.dart';
import 'package:supervisormobile/features/calendar/models/boutiqueModel.dart';
import 'package:supervisormobile/features/calendar/models/incidentTypeModel.dart';
import 'package:supervisormobile/features/calendar/screens/widgets/captureImageScreen.dart';
import 'package:supervisormobile/features/calendar/services/missionService.dart';
import 'package:supervisormobile/features/incidents/models/Coefficient.dart';
import 'package:supervisormobile/features/incidents/services/incident_service.dart';
import 'package:supervisormobile/utils/constants/colors.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../models/IncidentCategory.dart';

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
  late Future<List<IncidentType>> _incidentTypesFuture;

  final ImagePicker _picker = ImagePicker();
  File? jointureFichier;
  PlatformFile? infoFichier;
  List<XFile>? _imageFiles;

  BoutiqueModel? _selectedBoutique;

  Coefficient? _selectedPriority;

  final _storage = FlutterSecureStorage();
  bool _isLoading = false;
  IncidentType? _selectedIncidentType;



  @override
  void initState(){
    super.initState();
    _incidentTypesFuture = MissionService().getIncidentTypes();
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
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt', 'csv', 'zip'], // ✅ Only allow safe types
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
        print("❌ ${AppLocalizations.of(context)!.noValidFilePath}");
        return;
      }

      setState(() {});
    } else {
      print("❌ ${AppLocalizations.of(context)!.filePickingCancelled}");
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
      print('${AppLocalizations.of(context)!.errorDuringFileUpload} $e');
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
          final fileSize = await image.length(); // ✅ Async: await correct file size
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
          print(AppLocalizations.of(context)!.imageViewerDismissed);
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
          print(AppLocalizations.of(context)!.imageSavedToGallerySuccessfully);
        } else {
          print(AppLocalizations.of(context)!.failedToSaveImageToGallery);
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
        print('${AppLocalizations.of(context)!.errorSavingImageToFile} $e');
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _imageFiles!.removeAt(index);
    });
  }



  void _submitForm() async {




    if(_selectedBoutique != null && _selectedPriority != null && _selectedIncidentType != null && _commentController.text.isNotEmpty && _descriptionController.text.isNotEmpty ){
      setState(() => _isLoading = true);

      String? imageName;
      String? fileName;
      try {
      if (_imageFiles != null && _imageFiles!.isNotEmpty) {
        try {
          final firstFile = _imageFiles!.first;
          imageName = await MissionService().uploadFile(File(firstFile.path));
          print("\n File Name ----------------------------------------------- \n" + imageName);
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.failedToUploadImageFile)),
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
            SnackBar(content: Text(AppLocalizations.of(context)!.failedToUploadJointureFile)),
          );
          return; // Stop execution if jointure fichier upload fails
        }
      }
      int _currentUserID = 0;
      String? userIdString = await _storage.read(key: 'currentUserId');
      _currentUserID = userIdString != null ? int.tryParse(userIdString) ?? 0 : 0;
      final declaredProblem = Problem(id: 0,
          user_id: _currentUserID,
          boutique_id: _selectedBoutique!.id,
          coef_id: _selectedPriority!.coefId,
          problem_image_before: imageName,
          joint_file_before: fileName,
          commentaire:_commentController.text,
          description: _descriptionController.text ,
        cluster: _selectedBoutique!.cluster,
          IncidentTypeId: _selectedIncidentType?.id

      );

      print(declaredProblem.toJson());


     await IncidentService().addProblem(declaredProblem);
     ScaffoldMessenger.of(context).showSnackBar(
       SnackBar(content: Text(AppLocalizations.of(context)!.incidentAddedSuccessfully)),
     );
     Navigator.pop(context, true); // Navigate back
      }catch (e) {
        print(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.failedToSubmitIncident)),
        );
        setState(() => _isLoading = false);
      }
      finally {
        setState(() => _isLoading = false); // Stop loader
      }
    }
    else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.allFieldsAreRequired))) ;
    }

  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.addIncident,),

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
                FutureBuilder<List<IncidentType>>(
                  future: _incidentTypesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(
                          child: Text('${AppLocalizations.of(context)!.error}: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                          child: Text(AppLocalizations.of(context)!.noDataFound));
                    }

                    final incidentTypes = snapshot.data!;

                    return DropdownButtonFormField<IncidentType>(
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.incidentCategory,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                      ),
                      value: _selectedIncidentType,
                      items: incidentTypes.map((incidentType) {
                        return DropdownMenuItem<IncidentType>(
                          value: incidentType,
                          child: Text(incidentType.libelle ?? '${incidentType.id}'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedIncidentType = value;
                        });
                      },
                      validator: (value) =>
                      value == null ? AppLocalizations.of(context)!.pleaseSelectCategory : null,
                    );
                  },
                ),
                const SizedBox(height: 16.0),
                DropdownButtonFormField<BoutiqueModel>(
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.boutique,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  items: _boutiques
                      .map((boutique) => DropdownMenuItem<BoutiqueModel>(
                    value: boutique,
                    child: Text(boutique.libelle!), // Display boutique name
                  ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedBoutique = value; // Store selected boutique name or any unique identifier
                    });
                  },
                  validator: (value) => value == null ? AppLocalizations.of(context)!.pleaseSelectBoutique : null,
                ),

                const SizedBox(height: 16.0),

                // Description TextField
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.descriptionLabel,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  validator: (value) => value!.isEmpty
                      ? AppLocalizations.of(context)!.pleaseProvideDescription
                      : null,
                ),
                const SizedBox(height: 16.0),

                // Commentaire TextField
                TextFormField(
                  controller: _commentController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.commentLabel,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  validator: (value) =>
                  value!.isEmpty ? AppLocalizations.of(context)!.pleaseProvideComment : null,
                ),
                const SizedBox(height: 16.0),


                Text(AppLocalizations.of(context)!.attachImages,
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _pickImages,
                  icon: Icon(Icons.add, size: 24),
                  label: Text(AppLocalizations.of(context)!.image),
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size(double.infinity, 48),
                  ),
                ),
                SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: selectFile,
                  icon: Icon(Icons.add, size: 24),
                  label: Text(AppLocalizations.of(context)!.file),
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size(double.infinity, 48),
                  ),
                ),
                SizedBox(height: 16),

                OutlinedButton.icon(
                  onPressed: _openCamera,
                  icon: Icon(Icons.camera_alt, size: 24),
                  label: Text(AppLocalizations.of(context)!.openCamera),
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
                                color:
                                Colors.blue, // Color for the icon
                              ),
                              SizedBox(width: 8),
                              // Bold text for the "Fichier joint" label
                              Text(
                                AppLocalizations.of(context)!.attachedFile,
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
                          Text("${AppLocalizations.of(context)!.name} ${infoFichier?.name}"),
                          Text(
                              "${AppLocalizations.of(context)!.size} ${(infoFichier!.size / 1024).toStringAsFixed(2)} KB"),
                          Text(
                              "${AppLocalizations.of(context)!.type} ${infoFichier?.extension ?? AppLocalizations.of(context)!.unknown}"),
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

                const SizedBox(height: 16.0),

                // Priority Dropdown
                DropdownButtonFormField<Coefficient>(
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.priorityLabel,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  items: _priorities
                      .map((priority) => DropdownMenuItem<Coefficient>(
                    value: priority,
                    child: Text(priority.libelle ?? "Unknown"), // Display priority label
                  ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedPriority = value; // Store selected priority name or any unique identifier
                    });
                  },
                  validator: (value) => value == null ? AppLocalizations.of(context)!.pleaseSelectPriority : null,
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
                        : Text(AppLocalizations.of(context)!.submit),
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

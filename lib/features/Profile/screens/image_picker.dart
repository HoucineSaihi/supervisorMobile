import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io'; // Import this to use File
import 'package:supervisormobile/features/Profile/models/user_model.dart';
import 'package:supervisormobile/utils/constants/colors.dart';
import 'package:supervisormobile/features/Profile/services/user_service.dart'; // Import the UserService
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ImagePickerScreen extends StatefulWidget {
  final UserModel user; // Added user parameter

  const ImagePickerScreen({super.key, required this.user}); // Updated constructor

  @override
  _ImagePickerScreenState createState() => _ImagePickerScreenState();
}

class _ImagePickerScreenState extends State<ImagePickerScreen> {
  XFile? _image;
  final UserService _userService = UserService(); // Create an instance of UserService

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.gallery);

    setState(() {
      _image = pickedImage;
    });
  }

  Future<void> _saveImage() async {
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: AwesomeSnackbarContent(
            title: AppLocalizations.of(context)!.noImage,
            message: AppLocalizations.of(context)!.noImageSelected,
            contentType: ContentType.warning, // Adjust this based on your needs (e.g., success, failure, help)
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      );
      return;
    }

    try {
      final filename = await _userService.uploadFile(File(_image!.path));
      final updatedUser = widget.user.copyWith(img: filename);

      final updateSuccess = await _userService.updateUser(updatedUser);

      if (updateSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: AwesomeSnackbarContent(
              title: AppLocalizations.of(context)!.success,
              message: AppLocalizations.of(context)!.profileImageUpdatedSuccessfully,
              contentType: ContentType.success,
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
        );
        Navigator.of(context).pop(); // Navigate back to the previous screen
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: AwesomeSnackbarContent(
              title: AppLocalizations.of(context)!.failure,
              message: AppLocalizations.of(context)!.failedToUpdateProfileImage,
              contentType: ContentType.failure,
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: AwesomeSnackbarContent(
            title: AppLocalizations.of(context)!.error,
            message: '${AppLocalizations.of(context)!.anErrorOccurred} $e',
            contentType: ContentType.failure,
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.editProfilePhoto)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 80,
                  backgroundColor: Colors.grey[200],
                  child: _image != null
                      ? ClipOval(
                    child: Image.file(
                      File(_image!.path),
                      fit: BoxFit.cover,
                      width: 160,
                      height: 160,
                    ),
                  )
                      : widget.user.img != null && widget.user.img!.isNotEmpty
                      ? ClipOval(
                    child: Image.network(
                      '${dotenv.env['BASE_URL']}/api/Files/getImage/${widget.user.img!}',
                      fit: BoxFit.cover,
                      width: 160,
                      height: 160,
                    ),
                  )
                      : const Icon(Icons.camera_alt, size: 40),
                ),
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: _saveImage, // Update this to call _saveImage
              style: OutlinedButton.styleFrom(
                foregroundColor: TColors.accent,
                side: BorderSide(color: TColors.accent),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.save, size: 20, color: TColors.accent),
                const SizedBox(width: 8),
                Text(AppLocalizations.of(context)!.save),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

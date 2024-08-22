import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io'; // Import this to use File
import 'package:supervisormobile/features/Profile/models/user_model.dart';
import 'package:supervisormobile/utils/constants/colors.dart';
import 'package:supervisormobile/features/Profile/services/user_service.dart'; // Import the UserService

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
        SnackBar(content: Text('No image selected')),
      );
      return;
    }

    try {
      final filename = await _userService.uploadFile(File(_image!.path));
      final updatedUser = widget.user.copyWith(img: filename);

      final updateSuccess = await _userService.updateUser(updatedUser);

      if (updateSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile image updated successfully')),
        );
        Navigator.of(context).pop(); // Navigate back to the previous screen
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile image')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Modifier photo de profile')),
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
                      'https://3051-102-159-183-142.ngrok-free.app/api/Files/getImage/${widget.user.img!}',
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
                children: const [
                  Icon(Icons.save, size: 20, color: TColors.accent),
                  SizedBox(width: 8),
                  Text('Enregistrer'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

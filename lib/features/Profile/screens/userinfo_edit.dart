import 'package:flutter/material.dart';
import 'package:supervisormobile/features/Profile/models/user_model.dart';
import 'package:supervisormobile/features/Profile/services/user_service.dart';
import 'package:supervisormobile/utils/constants/colors.dart';

class EditUserInfoScreen extends StatefulWidget {
  final UserModel user; // Added user parameter

  const EditUserInfoScreen({super.key, required this.user}); // Updated constructor

  @override
  _EditUserInfoScreenState createState() => _EditUserInfoScreenState();
}

class _EditUserInfoScreenState extends State<EditUserInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userService = UserService(); // Create an instance of UserService

  late String _nom;
  late String _username;
  late String _fax;
  late String _tel;
  late int _codePostal;

  @override
  void initState() {
    super.initState();
    // Initialize fields with user data
    _nom = widget.user.nom ?? '';
    _username = widget.user.username ?? '';
    _fax = widget.user.fax ?? '';
    _tel = widget.user.tel ?? '';
    _codePostal = widget.user.codePostal ?? 0;
  }

  Future<void> _updateUser() async {
    final updatedUser = widget.user.copyWith(
      nom: _nom,
      username: _username,
      fax: _fax,
      tel: _tel,
      codePostal: _codePostal,
    );

    try {
      final updateSuccess = await _userService.updateUser(updatedUser);

      if (updateSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User information updated successfully')),
        );
        Navigator.of(context).pop(); // Navigate back to the previous screen
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update user information')),
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
      appBar: AppBar(title: const Text('Modifier information utilisateur')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                initialValue: _nom,
                decoration: const InputDecoration(labelText: 'Name'),
                onChanged: (value) => setState(() => _nom = value),
                validator: (value) => value!.isEmpty ? 'Please enter a name' : null,
              ),SizedBox(height: 24.0),
              TextFormField(
                initialValue: _username,
                decoration: const InputDecoration(labelText: 'Username'),
                onChanged: (value) => setState(() => _username = value),
                validator: (value) => value!.isEmpty ? 'Please enter a username' : null,
              ),SizedBox(height: 24.0),
              TextFormField(
                initialValue: _fax,
                decoration: const InputDecoration(labelText: 'Fax'),
                onChanged: (value) => setState(() => _fax = value),
                validator: (value) => value!.isEmpty ? 'Please enter a fax' : null,
              ),SizedBox(height: 24.0),
              TextFormField(
                initialValue: _tel,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                onChanged: (value) => setState(() => _tel = value),
                validator: (value) => value!.isEmpty ? 'Please enter a phone number' : null,
              ),SizedBox(height: 24.0),
              TextFormField(
                initialValue: _codePostal.toString(),
                decoration: const InputDecoration(labelText: 'Postal Code'),
                keyboardType: TextInputType.number,
                onChanged: (value) => setState(() => _codePostal = int.tryParse(value) ?? 0),
                validator: (value) => value!.isEmpty ? 'Please enter a postal code' : null,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity, // This makes the button take the whole width of its parent
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _updateUser();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Enregistrer'),
                ),
              )

            ],
          ),
        ),
      ),
    );
  }
}

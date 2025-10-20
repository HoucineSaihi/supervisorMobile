import 'package:flutter/material.dart';
import 'package:supervisormobile/features/Profile/models/user_model.dart';
import 'package:supervisormobile/features/Profile/services/user_service.dart';
import 'package:supervisormobile/utils/constants/colors.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
          SnackBar(content: Text(AppLocalizations.of(context)!.userInfoUpdatedSuccessfully)),
        );
        Navigator.of(context).pop(); // Navigate back to the previous screen
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.failedToUpdateUserInfo)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context)!.anErrorOccurred} $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.editUserInfo)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                initialValue: _nom,
                decoration: InputDecoration(labelText: AppLocalizations.of(context)!.name),
                onChanged: (value) => setState(() => _nom = value),
                validator: (value) => value!.isEmpty ? AppLocalizations.of(context)!.pleaseEnterName : null,
              ),SizedBox(height: 24.0),
              TextFormField(
                initialValue: _username,
                decoration: InputDecoration(labelText: AppLocalizations.of(context)!.username),
                onChanged: (value) => setState(() => _username = value),
                validator: (value) => value!.isEmpty ? AppLocalizations.of(context)!.pleaseEnterUsername : null,
              ),SizedBox(height: 24.0),
              TextFormField(
                initialValue: _fax,
                decoration: InputDecoration(labelText: AppLocalizations.of(context)!.fax),
                onChanged: (value) => setState(() => _fax = value),
                validator: (value) => value!.isEmpty ? AppLocalizations.of(context)!.pleaseEnterFax : null,
              ),SizedBox(height: 24.0),
              TextFormField(
                initialValue: _tel,
                decoration: InputDecoration(labelText: AppLocalizations.of(context)!.phoneNumber),
                onChanged: (value) => setState(() => _tel = value),
                validator: (value) => value!.isEmpty ? AppLocalizations.of(context)!.pleaseEnterPhoneNumber : null,
              ),SizedBox(height: 24.0),
              TextFormField(
                initialValue: _codePostal.toString(),
                decoration: InputDecoration(labelText: AppLocalizations.of(context)!.postalCode),
                keyboardType: TextInputType.number,
                onChanged: (value) => setState(() => _codePostal = int.tryParse(value) ?? 0),
                validator: (value) => value!.isEmpty ? AppLocalizations.of(context)!.pleaseEnterPostalCode : null,
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
                  child: Text(AppLocalizations.of(context)!.save),
                ),
              )

            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:supervisormobile/features/authentification/services/login_service.dart';
import 'package:supervisormobile/features/calendar/screens/calendar.dart';
import 'package:supervisormobile/features/communication/controllers/messenger_controller.dart';
import 'package:supervisormobile/navigation_menu.dart';
import 'package:supervisormobile/utils/Helpers/helper_functions.dart';
import 'package:supervisormobile/utils/constants/TImages.dart';
import 'package:supervisormobile/utils/constants/colors.dart';
import 'package:supervisormobile/utils/constants/sizes.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';



class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _loginService = LoginService(); // Instantiate LoginService
  bool _isLoading = false;
  bool _isPasswordObscured = true;
  final _secureStorage = const FlutterSecureStorage();


  @override
  void initState() {
    super.initState();
    _checkIfLoggedIn();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordObscured = !_isPasswordObscured;
    });
  }

  Future<void> _checkIfLoggedIn() async {
    // Check for current_user_id in secure storage
    final currentUserId = await _secureStorage.read(key: 'currentUserId');

    // If current_user_id exists, redirect to Calendar screen
    if (currentUserId != null) {
      Get.off(() => const CalendarPlanning()); // Navigate to Calendar
    }
  }

  Future<void> _login() async {
    // Basic input validation
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.usernamePasswordEmpty)),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _loginService.login(username, password);

      if (result['success']) {
        // If a MessengerController survived the previous session (it is permanent),
        // it is still holding the old account's identity and an empty, reset state.
        // Re-bootstrap it against the credentials just written to secure storage so
        // the new user gets their own conversations and hub connection.
        if (Get.isRegistered<MessengerController>()) {
          await Get.find<MessengerController>().reinitializeForNewUser();
        }

        // Replace the login screen with the home screen
        Get.offAll(() => NavigationMenu());
      } else {
        // Handle login failure
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? AppLocalizations.of(context)!.loginFailed)),
        );
      }
    } catch (e) {
      // Provide a generic error message to the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.errorOccurred)),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            top: 56.0,
            left: TSizes.defaultSpace,
            bottom: TSizes.defaultSpace,
            right: TSizes.defaultSpace,
          ),
          child: Column(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image(
                    height: 150,
                    image: AssetImage(dark ? TImages.lightAppLogo : TImages.darkAppLogo),
                  ),
                  Text(
                    AppLocalizations.of(context)!.appTitle,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 16.0),
                  Text(
                    AppLocalizations.of(context)!.appDescription,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              Form(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32.0),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          prefixIcon: Icon(Iconsax.direct_right),
                          labelText: AppLocalizations.of(context)!.enterUsername,
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _isPasswordObscured,
                        decoration: InputDecoration(
                          prefixIcon: Icon(Iconsax.password_check),
                          labelText: AppLocalizations.of(context)!.enterPassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordObscured
                                  ? Iconsax.eye_slash
                                  : Iconsax.eye,
                            ),
                            onPressed: _togglePasswordVisibility,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          child: _isLoading
                              ? const CircularProgressIndicator()
                              : Text(AppLocalizations.of(context)!.login),
                        ),
                      ),

                    ],
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Divider(
                    color: dark ? TColors.darkGrey : TColors.grey,
                    thickness: 0.5,
                    indent: 60,
                    endIndent: 5,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supervisormobile/common/widgets/custom_shapes/containers/primary_header_container.dart';
import 'package:supervisormobile/features/Profile/models/user_model.dart';
import 'package:supervisormobile/features/Profile/screens/image_picker.dart';
import 'package:supervisormobile/features/Profile/screens/userinfo_edit.dart';
import 'package:supervisormobile/features/Profile/services/user_service.dart';
import 'package:supervisormobile/features/authentification/screens/login/login.dart';
import 'package:supervisormobile/utils/constants/colors.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';


class ProfileInfo extends StatefulWidget {
  const ProfileInfo({super.key});

  @override
  _ProfileInfoState createState() => _ProfileInfoState();
}

class _ProfileInfoState extends State<ProfileInfo> {
  late Future<UserModel?> _userDetails;
  final FlutterSecureStorage _storage = FlutterSecureStorage();




  @override
  void initState() {
    super.initState();
    // Initialize with static user ID

    _userDetails = UserService().getUserById();
  }

  void _openImagePicker(UserModel user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImagePickerScreen(user: user),
      ),
    );
  }

  void _openEditUserInfo(UserModel user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditUserInfoScreen(user: user), // Navigate to the new screen
      ),
    );
  }

  Future<void> _handleLogout() async {
    await _storage.deleteAll(); // Clear secure storage (used in both)

    if (!kIsWeb) {
      // ✅ Mobile: Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      print('🧹 SharedPreferences cleared (mobile)');
    }

    // ✅ Navigate to login screen and remove all previous routes
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => LoginScreen()),
          (Route<dynamic> route) => false,
    );
  }


  Future<void> _handleRefresh() async {
    setState(() {
      _userDetails = UserService().getUserById();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LiquidPullToRefresh(
        onRefresh: _handleRefresh,
        springAnimationDurationInMilliseconds: 300,
        height: 60.0,
        color: TColors.primary,
        child: SingleChildScrollView(
          child: TPrimaryHeaderContainer(
            height: 400,
            child: SafeArea(
              child: FutureBuilder<UserModel?>(
                future: _userDetails,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data == null) {
                    return const Center(child: Text('No user data found.'));
                  }

                  final user = snapshot.data!;

                  return Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            SizedBox(
                              width: 120,
                              height: 120,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(100),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(100),
                                  child: user.img != null && user.img!.isNotEmpty
                                      ? Image.network(
                                    'http://shopconnect.exoticgroup.net:8080/api/Files/getImage/${user.img!}',
                                    fit: BoxFit.cover,
                                  )
                                      : Image.asset('lib/assets/logos/testLogo.png'),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () => {},
                                child: Container(
                                  width: 35,
                                  height: 35,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: const Icon(
                                    Iconsax.edit,
                                    size: 20,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Divider(),
                        const SizedBox(height: 10),
                        Text(
                          user.nom ?? 'User Name',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(
                          user.username ?? 'Username',
                          style: TextStyle(fontSize: 16, color: TColors.grey),
                        ),
                        const SizedBox(height: 20),
                        OutlinedButton(
                          onPressed: () => _openEditUserInfo(user),
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
                              const Icon(Iconsax.edit, size: 20, color: TColors.accent),
                              const SizedBox(width: 8),
                              Text('Info Profile'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            secondChild: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // FutureBuilder for user details
                FutureBuilder<UserModel?>(
                  future: _userDetails,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data == null) {
                      return const Center(child: Text('No user data found.'));
                    }

                    final user = snapshot.data!;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                            decoration: BoxDecoration(
                              border: Border.all(color: TColors.primary, width: 2),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Text(
                                      'Tel: ${user.tel ?? 'Not available'}',
                                      style: TextStyle(fontSize: 18),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Icon(Iconsax.call, color: TColors.primary),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                            decoration: BoxDecoration(
                              border: Border.all(color: TColors.primary, width: 2),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Text(
                                      'Role: ${user.role?.libelle ?? 'Not available'}',
                                      style: TextStyle(fontSize: 18),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Icon(Iconsax.user, color: TColors.primary),
                                ),
                              ],
                            ),
                          ),
                          /* Container(
                            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                            decoration: BoxDecoration(
                              border: Border.all(color: TColors.primary, width: 2),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Text(
                                      'Appartient à: ${user.groups?.isNotEmpty == true ? 'Groupe, ${user.groups![0].groupName}' : "Boutique, ${user.boutique?.libelle ?? ''}"}',
                                      style: TextStyle(fontSize: 18),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Icon(Iconsax.group, color: TColors.primary),
                                ),
                              ],
                            ),
                          ), */
                        ],
                      ),
                    );
                  },
                ),
                // Logout button placed separately below the FutureBuilder
                const SizedBox(height: 30),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0), // Margin on the left and right
                  child: ElevatedButton(
                    onPressed: _handleLogout, // Call the logout function here
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TColors.primary, // Background color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8), // Button border radius
                      ),
                      padding: EdgeInsets.symmetric(vertical: 14), // Button padding
                      textStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center, // Center text and icon
                      children: [
                        Icon(Iconsax.logout, color: Colors.white),
                        SizedBox(width: 8),
                        Text('Se Déconnecter', style: TextStyle(color: Colors.white)),
                      ],
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
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:iconsax/iconsax.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:supervisormobile/common/widgets/custom_shapes/containers/primary_header_container.dart';
import 'package:supervisormobile/features/Profile/models/user_model.dart';
import 'package:supervisormobile/features/Profile/screens/userinfo_edit.dart';
import 'package:supervisormobile/features/Profile/services/user_service.dart';
import 'package:supervisormobile/features/authentification/screens/login/login.dart';
import 'package:supervisormobile/utils/constants/colors.dart';
import 'dart:html';

class ProfileInfo extends StatefulWidget {
  const ProfileInfo({super.key});

  @override
  _ProfileInfoState createState() => _ProfileInfoState();
}

class _ProfileInfoState extends State<ProfileInfo> {
  late Future<UserModel?> _userDetails;

  @override
  void initState() {
    super.initState();
    _userDetails = UserService().getUserById();
  }

  Future<void> _handleLogout() async {
    // Clear local storage directly for web
    // Check if this is running on the web platform
    if (kIsWeb) {
      // Clear all local storage items
      window.localStorage.clear();
    }

    // Navigate to the login screen and remove all previous routes
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
      body: SingleChildScrollView(
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
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(100),
                                  child: user.img != null && user.img!.isNotEmpty
                                      ? Image.network(
                                    '${dotenv.env['BASE_URL']}/api/Files/getImage/${user.img!}',
                                    fit: BoxFit.cover,
                                  )
                                      : Image.asset('lib/assets/logos/testLogo.png'),
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
                      ],
                    ),
                  );
                },
              ),
            ),
            secondChild: FutureBuilder<UserModel?>(
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: Icon(Iconsax.refresh), // Replace with the reload icon you are using
                            onPressed: () {
                              // Your function to reload or refresh
                              _handleRefresh();
                            },
                          ),
                        ],
                      ),
                      _buildInfoCard(
                        title: 'Tel: ${user.tel ?? 'Not available'}',
                        icon: Iconsax.call,
                      ),
                      _buildInfoCard(
                        title: 'Role: ${user.role?.libelle ?? 'Not available'}',
                        icon: Iconsax.user,
                      ),
                      _buildInfoCard(
                        title: 'Appartient à: ${user.groups?.isNotEmpty == true ? 'Groupe , ${user.groups![0].groupName}' : "Boutique , ${user.boutique?.libelle ?? ''}"}',
                        icon: Iconsax.group,
                      ),
                      SizedBox(height: 30),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: ElevatedButton(
                          onPressed: () {
                            _handleLogout();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: TColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Iconsax.logout, size: 20, color: Colors.white),
                              const SizedBox(width: 8),
                              const Text('Se déconnecter', style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),

    );
  }

  Widget _buildInfoCard({required String title, required IconData icon}) {
    return Container(
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
                title,
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Icon(icon, color: TColors.primary),
          ),
        ],
      ),
    );
  }
}

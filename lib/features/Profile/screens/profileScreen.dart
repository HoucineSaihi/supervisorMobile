import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:iconsax/iconsax.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:supervisormobile/common/widgets/custom_shapes/containers/primary_header_container.dart';
import 'package:supervisormobile/features/Profile/models/user_model.dart';
import 'package:supervisormobile/features/Profile/screens/image_picker.dart';
import 'package:supervisormobile/features/Profile/screens/userinfo_edit.dart';
import 'package:supervisormobile/features/Profile/services/user_service.dart';
import 'package:supervisormobile/features/authentification/screens/login/login.dart';
import 'package:supervisormobile/features/communication/controllers/messenger_controller.dart';
import 'package:supervisormobile/utils/constants/colors.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supervisormobile/common/widgets/language_selector.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';


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
    // Tear the messenger down *before* clearing storage: it has to stop the live
    // SignalR hub and drop the cached threads while it can still identify the
    // session. Get.deleteAll below does not do this on its own — a permanent
    // controller's onClose is skipped unless it is actually disposed, so the old
    // user's conversations would otherwise leak into the next login.
    if (Get.isRegistered<MessengerController>()) {
      await Get.find<MessengerController>().resetForLogout();
    }

    await _storage.deleteAll();

    // Delete all registered GetX controllers so the next user starts fresh
    Get.deleteAll(force: true);

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

  Widget _buildInfoCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: TColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: TColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value.isEmpty ? AppLocalizations.of(context)!.notAvailable : value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
                    return Center(child: Text('${AppLocalizations.of(context)!.error}: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data == null) {
                    return Center(child: Text(AppLocalizations.of(context)!.noUserDataFound));
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
                        const SizedBox(height: 4),
                        Text(
                          user.email ?? AppLocalizations.of(context)!.notAvailable,
                          style: TextStyle(fontSize: 14, color: Colors.white70),
                        ),
                        const SizedBox(height: 8),
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
                      return Center(child: Text('${AppLocalizations.of(context)!.error}: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data == null) {
                      return Center(child: Text(AppLocalizations.of(context)!.noUserDataFound));
                    }

                    final user = snapshot.data!;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoCard(
                            context: context,
                            icon: Iconsax.user,
                            label: AppLocalizations.of(context)!.name,
                            value: user.nom ?? '',
                          ),
                          _buildInfoCard(
                            context: context,
                            icon: Iconsax.profile_circle,
                            label: AppLocalizations.of(context)!.username,
                            value: user.username ?? '',
                          ),
                          _buildInfoCard(
                            context: context,
                            icon: Iconsax.sms,
                            label: 'Email',
                            value: user.email ?? '',
                          ),
                          _buildInfoCard(
                            context: context,
                            icon: Iconsax.shield_tick,
                            label: AppLocalizations.of(context)!.role,
                            value: user.role?.libelle ?? '',
                          ),
                          _buildInfoCard(
                            context: context,
                            icon: Iconsax.code,
                            label: 'Role code',
                            value: user.role?.code ?? '',
                          ),
                        ],
                      ),
                    );
                  },
                ),
                // Language selector
                const LanguageSelector(),
                const SizedBox(height: 20),
                // Logout button placed separately below the FutureBuilder
                const SizedBox(height: 10),
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
                        Text(AppLocalizations.of(context)!.logout, style: TextStyle(color: Colors.white)),
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
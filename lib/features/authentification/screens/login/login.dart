import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:supervisormobile/features/authentification/services/login_service.dart';
import 'package:supervisormobile/features/calendar/screens/calendar.dart';
import 'package:supervisormobile/features/communication/controllers/messenger_controller.dart';
import 'package:supervisormobile/navigation_menu.dart';
import 'package:supervisormobile/utils/constants/TImages.dart';
import 'package:supervisormobile/utils/constants/colors.dart';
import 'package:supervisormobile/utils/theme/theme.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// Brand gradient of the welcome panel / header.
const Color _brandLight = Color(0xFF2F74DB);
const Color _brandDark = Color(0xFF173E95);

// Web uses the split layout (brand panel | form); the native apps use the
// header layout. A browser window narrower than this falls back to the header
// layout because the split no longer fits.
const double _webSplitMinWidth = 700;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();
  final _loginService = LoginService(); // Instantiate LoginService
  bool _isLoading = false;
  bool _isPasswordObscured = true;
  final _secureStorage = const FlutterSecureStorage();


  @override
  void initState() {
    super.initState();
    _checkIfLoggedIn();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
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
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? AppLocalizations.of(context)!.loginFailed)),
        );
      }
    } catch (e) {
      // Provide a generic error message to the user
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.errorOccurred)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    // The login screen keeps its branded light look regardless of the app theme,
    // so everything below reads the light theme through the LayoutBuilder context.
    return Theme(
      data: TAppTheme.lightTheme,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: Colors.white,
          body: LayoutBuilder(
            builder: (context, constraints) => kIsWeb && constraints.maxWidth >= _webSplitMinWidth
                ? _buildWideLayout(context, constraints)
                : _buildCompactLayout(context, constraints),
          ),
        ),
      ),
    );
  }

  /// Web / tablet: brand panel on the left, cloud edge, form on the right.
  Widget _buildWideLayout(BuildContext context, BoxConstraints constraints) {
    final panelWidth = (constraints.maxWidth * 0.45).clamp(300.0, 640.0);
    final cloudThickness = (panelWidth * 0.26).clamp(90.0, 150.0);
    final l10n = AppLocalizations.of(context)!;

    return Stack(
      children: [
        Row(
          children: [
            SizedBox(
              width: panelWidth,
              child: _BrandPanel(
                contentPadding: EdgeInsets.only(left: 32, right: 32 + cloudThickness * 0.5),
                child: Column(
                  children: [
                    const SizedBox(height: 56),
                    Text(
                      l10n.loginWelcomeTo,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const Spacer(),
                    const _LogoBadge(size: 128),
                    const SizedBox(height: 16),
                    Text(
                      l10n.appTitle,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 28),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 360),
                      child: Text(
                        l10n.appDescription,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.88),
                              height: 1.6,
                            ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${l10n.appTitle} © ${DateTime.now().year}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.white.withOpacity(0.7),
                            letterSpacing: 1.2,
                          ),
                    ),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: constraints.maxWidth < 1000 ? 32 : 48,
                    vertical: 40,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: _buildForm(context, titleAlign: TextAlign.center),
                  ),
                ),
              ),
            ),
          ],
        ),
        // Clouds spilling from the form side over the edge of the brand panel.
        Positioned(
          left: panelWidth - cloudThickness,
          width: cloudThickness,
          top: 0,
          bottom: 0,
          child: IgnorePointer(
            child: RotatedBox(
              quarterTurns: 3,
              child: CustomPaint(painter: _CloudEdgePainter(frontColor: Colors.white)),
            ),
          ),
        ),
      ],
    );
  }

  /// Phone: brand header with a cloud bottom edge, form below.
  Widget _buildCompactLayout(BuildContext context, BoxConstraints constraints) {
    const cloudHeight = 72.0;
    final topInset = MediaQuery.of(context).padding.top;
    final headerHeight = (constraints.maxHeight * 0.34).clamp(240.0, 320.0) + topInset;
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(
            height: headerHeight,
            child: Stack(
              children: [
                Positioned.fill(
                  child: _BrandPanel(
                    contentPadding: EdgeInsets.only(top: topInset, bottom: cloudHeight * 0.6),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const _LogoBadge(size: 92),
                        const SizedBox(height: 12),
                        Text(
                          l10n.appTitle,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: cloudHeight,
                  child: IgnorePointer(
                    child: CustomPaint(painter: _CloudEdgePainter(frontColor: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: _buildForm(context, titleAlign: TextAlign.center),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context, {required TextAlign titleAlign}) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;

    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.loginTitle,
            textAlign: titleAlign,
            style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.loginSubtitle,
            textAlign: titleAlign,
            style: textTheme.bodySmall?.copyWith(
              color: TColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          _FieldLabel(l10n.username),
          TextField(
            controller: _usernameController,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.username],
            autocorrect: false,
            enableSuggestions: false,
            onSubmitted: (_) => _passwordFocus.requestFocus(),
            decoration: _fieldDecoration(hint: l10n.enterUsername),
          ),
          const SizedBox(height: 20),
          _FieldLabel(l10n.loginPasswordLabel),
          TextField(
            controller: _passwordController,
            focusNode: _passwordFocus,
            obscureText: _isPasswordObscured,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            onSubmitted: (_) {
              if (!_isLoading) _login();
            },
            decoration: _fieldDecoration(
              hint: l10n.enterPassword,
              suffix: IconButton(
                icon: Icon(
                  _isPasswordObscured ? Iconsax.eye_slash : Iconsax.eye,
                  size: 20,
                ),
                onPressed: _togglePasswordVisibility,
              ),
            ),
          ),
          const SizedBox(height: 32),
          _GradientButton(
            onPressed: _isLoading ? null : _login,
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                  )
                : Text(
                    l10n.login,
                    style: textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
          const SizedBox(height: 28),
          Text(
            l10n.loginNoAccountHint,
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(
              color: TColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration({required String hint, Widget? suffix}) {
    final radius = BorderRadius.circular(10);
    final idle = OutlineInputBorder(borderRadius: radius, borderSide: BorderSide.none);

    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontSize: 13, color: const Color(0xFF9AA3B5)),
      filled: true,
      fillColor: const Color(0xFFEEF3FD),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      suffixIcon: suffix,
      border: idle,
      enabledBorder: idle,
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: _brandLight, width: 1.4),
      ),
    );
  }
}

/// Blue gradient surface used behind the welcome content.
class _BrandPanel extends StatelessWidget {
  const _BrandPanel({required this.child, this.contentPadding = EdgeInsets.zero});

  final Widget child;
  final EdgeInsets contentPadding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_brandLight, _brandDark],
        ),
      ),
      child: Padding(padding: contentPadding, child: Center(child: child)),
    );
  }
}

/// App logo inside a white circle.
class _LogoBadge extends StatelessWidget {
  const _LogoBadge({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: EdgeInsets.all(size * 0.045),
      child: ClipOval(
        child: Image.asset(TImages.darkAppLogo, fit: BoxFit.contain),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({required this.onPressed, required this.child});

  final VoidCallback? onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(10);
    return Opacity(
      opacity: onPressed == null ? 0.85 : 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: const LinearGradient(colors: [_brandLight, _brandDark]),
          boxShadow: [
            BoxShadow(
              color: _brandLight.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onPressed,
            borderRadius: radius,
            child: SizedBox(height: 52, child: Center(child: child)),
          ),
        ),
      ),
    );
  }
}

/// Paints three layers of cloud puffs rising from the bottom edge of its box.
/// The front layer uses [frontColor] so it blends into the form background;
/// rotate the painter (RotatedBox) to put the clouds on another edge.
class _CloudEdgePainter extends CustomPainter {
  const _CloudEdgePainter({required this.frontColor});

  final Color frontColor;

  @override
  void paint(Canvas canvas, Size size) {
    // (base height, min radius, max radius) as fractions of the box height.
    _paintLayer(canvas, size, Colors.white.withOpacity(0.22), 0.34, 0.20, 0.52, 3);
    _paintLayer(canvas, size, Colors.white.withOpacity(0.45), 0.24, 0.16, 0.40, 11);
    _paintLayer(canvas, size, frontColor, 0.12, 0.12, 0.32, 23);
  }

  void _paintLayer(
    Canvas canvas,
    Size size,
    Color color,
    double baseFrac,
    double minRFrac,
    double maxRFrac,
    int seed,
  ) {
    final random = math.Random(seed);
    final h = size.height;
    final baseY = h - h * baseFrac;
    final path = Path()..addRect(Rect.fromLTRB(0, baseY, size.width, h));

    var x = -h * maxRFrac;
    while (x < size.width + h * maxRFrac) {
      final r = h * (minRFrac + (maxRFrac - minRFrac) * random.nextDouble());
      final cy = baseY + r * 0.25 * random.nextDouble();
      path.addOval(Rect.fromCircle(center: Offset(x, cy), radius: r));
      x += r * (1.1 + 0.4 * random.nextDouble());
    }

    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_CloudEdgePainter oldDelegate) => oldDelegate.frontColor != frontColor;
}

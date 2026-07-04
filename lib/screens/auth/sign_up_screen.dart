import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spentree/core/error_helper.dart';
import 'package:spentree/screens/auth/verify_number_screen.dart';
import 'package:spentree/screens/profile/privacy_screen.dart';
import 'package:spentree/screens/profile/terms_screen.dart';
import '../../core/app_style.dart';
import 'package:flutter/material.dart';
import 'sign_in_screen.dart';
import '../../core/user_data.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:spentree/screens/main_wrapper.dart';
import 'package:spentree/core/transaction_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isChecked = false;
  bool _showTermsError = false;
  bool _isLoading = false; // Added loading state

  // Errors
  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;

  // --- DIMENSIONS ---
  final double horizontalPadding = 24.0;
  final double componentHeight = 60.0;
  final double cornerRadius = 14.0;
  final double inputGap = 16.0;
  final double inputTermsGap = 26.0;
  final double termsButtonGap = 32.0;

  Future<void> _validateAndSubmit() async {
    setState(() {
      _nameError = null;
      _emailError = null;
      _passwordError = null;
      _confirmPasswordError = null;
      _showTermsError = false;
    });

    bool isValid = true;
    final email = _emailController.text.trim();
    final _emailRegex = RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,}$');
    // Add this near your other validation in _validateAndSubmit(), before the Supabase call:
    final password = _passwordController.text;
    final passwordPattern = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$&*~^%()_\-+=]).{8,}$',
    );
    if (_passwordController.text.isNotEmpty &&
        !passwordPattern.hasMatch(_passwordController.text)) {
      setState(
        () => _passwordError =
            "Password must be at least 8 characters and include an uppercase letter, a lowercase letter, a number, and a symbol.",
      );
      isValid = false;
    }

    if (_nameController.text.trim().isEmpty) {
      setState(() => _nameError = "Name is required");
      isValid = false;
    }
    if (email.isEmpty || !_emailRegex.hasMatch(email)) {
      setState(() => _emailError = "Please enter a valid email address");
      isValid = false;
    }
    if (_passwordController.text.isEmpty) {
      setState(() => _passwordError = "Password is required");
      isValid = false;
    }
    if (_confirmPasswordController.text != _passwordController.text) {
      setState(() => _confirmPasswordError = "Passwords do not match");
      isValid = false;
    }
    if (!_isChecked) {
      setState(() => _showTermsError = true);
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _showTermsError = false);
      });
      isValid = false;
    }

    if (isValid) {
      setState(() => _isLoading = true);
      try {
        final hasInternet = await checkInternetConnection();
        if (!hasInternet) {
          setState(
            () => _emailError =
                "No internet connection. Please check your network and try again.",
          );
          return;
        }
        // 1. Create user in Supabase Auth
        final res = await Supabase.instance.client.auth.signUp(
          email: email,
          password: _passwordController.text,
          data: {'full_name': _nameController.text.trim()},
        );

        final user = res.user;
        if (user != null &&
            (user.identities == null || user.identities!.isEmpty)) {
          setState(
            () => _emailError =
                "This email is already registered. Please sign in instead.",
          );
          return;
        }

        if (user != null) {
          UserData.userName = _nameController.text.trim();
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VerifyEmailScreen(email: email),
              ),
            );
          }
        }
      } on AuthException catch (e) {
  setState(() => _emailError = mapAuthError(e));
} catch (e) {
        setState(
          () => _emailError =
              "Something went wrong creating your account. Please try again.",
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    MediaQuery.platformBrightnessOf(context);

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentTheme, child) {
        return Scaffold(
          backgroundColor: AppColors.bgWhite,
          resizeToAvoidBottomInset: true,
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                    ),
                    child: Column(
                      children: [
                        // --- TOP MARGIN ---
                        const Spacer(flex: 1),
                        const SizedBox(height: 20),

                        Text(
                          "Sign Up",
                          style: GoogleFonts.poppins(
                            fontSize: 34,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryGreen,
                          ),
                        ),

                        const SizedBox(height: 12),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            "Create a new account and start growing today.",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: AppColors.grey700,
                              height: 1.5,
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // --- INPUTS ---
                        _buildTextField(
                          _nameController,
                          "Name",
                          errorText: _nameError,
                        ),
                        SizedBox(height: inputGap),

                        _buildTextField(
                          _emailController,
                          "Email Address",
                          isEmail:
                              true, // You'll need to add an 'isEmail' boolean to your _buildTextField signature to change keyboardType to TextInputType.emailAddress
                          errorText: _emailError,
                        ),
                        SizedBox(height: inputGap),

                        _buildTextField(
                          _passwordController,
                          "New Password",
                          isPassword: true,
                          isVisible: _isPasswordVisible,
                          onVisibilityChanged: () => setState(
                            () => _isPasswordVisible = !_isPasswordVisible,
                          ),
                          errorText: _passwordError,
                        ),
                        SizedBox(height: inputGap),

                        _buildTextField(
                          _confirmPasswordController,
                          "Confirm Password",
                          isPassword: true,
                          isVisible: _isConfirmPasswordVisible,
                          onVisibilityChanged: () => setState(
                            () => _isConfirmPasswordVisible =
                                !_isConfirmPasswordVisible,
                          ),
                          errorText: _confirmPasswordError,
                        ),

                        SizedBox(height: inputTermsGap),

                        // --- COMBINED STACK FOR TERMS AND BUTTON ---
                        // This Stack ensures the Tooltip (defined last) paints ON TOP of the button.
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // LAYER 1: Content (Terms -> Gap -> Button)
                            Column(
                              children: [
                                // Terms Row
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _isChecked = !_isChecked;
                                          if (_isChecked)
                                            _showTermsError = false;
                                        });
                                      },
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        width: 22,
                                        height: 22,
                                        margin: const EdgeInsets.only(top: 2),
                                        decoration: BoxDecoration(
                                          color: _isChecked
                                              ? AppColors.primaryGreen
                                              : AppColors.inputFill,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: _isChecked
                                            ? Icon(
                                                Icons.check,
                                                size: 16,
                                                color: AppColors.colwhite,
                                              )
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: RichText(
                                        text: TextSpan(
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w400,
                                            color: AppColors.grey800,
                                          ),
                                          children: [
                                            TextSpan(text: "I agree to the "),
                                            TextSpan(
                                              text: "terms and conditions",
                                              style: const TextStyle(
                                                color: AppColors.primaryGreen,
                                              ),
                                              recognizer: TapGestureRecognizer()
                                                ..onTap = () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          const TermsScreen(),
                                                    ),
                                                  );
                                                },
                                            ),
                                            TextSpan(text: " and "),
                                            TextSpan(
                                              text: "Privacy Policy",
                                              style: const TextStyle(
                                                color: AppColors.primaryGreen,
                                              ),
                                              recognizer: TapGestureRecognizer()
                                                ..onTap = () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          const PrivacyScreen(),
                                                    ),
                                                  );
                                                },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                SizedBox(height: termsButtonGap),

                                // Create Account Button
                                SizedBox(
                                  width: double.infinity,
                                  height: componentHeight,
                                  child: ElevatedButton(
                                    onPressed: _validateAndSubmit,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primaryGreen,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          cornerRadius,
                                        ),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: _isLoading
                                        ? SizedBox(
                                            height: 24,
                                            width: 24,
                                            child: CircularProgressIndicator(
                                              color: AppColors.colwhite,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Text(
                                            "Create Account",
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              color: AppColors.colwhite,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),

                            // LAYER 2: Tooltip (Floating on top)
                            if (_showTermsError)
                              Positioned(
                                left: -5,
                                top: 35, // Pushes it down over the button
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(left: 12),
                                      child: CustomPaint(
                                        size: const Size(12, 8),
                                        painter: _ArrowPainter(),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.colwhite,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: const Color(
                                            0xFFFFAB40,
                                          ).withOpacity(0.5),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.colblack
                                                .withOpacity(0.1),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.info_outline,
                                            size: 16,
                                            color: Colors.orange,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            "Please check this box to proceed.",
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: AppColors.colblack,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // --- SIGN IN LINK ---
                        Align(
                          alignment: Alignment.centerLeft,
                          child: RichText(
                            text: TextSpan(
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: AppColors.grey800,
                              ),
                              children: [
                                TextSpan(text: "Do you have account? "),
                                TextSpan(
                                  text: "Sign In",
                                  style: const TextStyle(
                                    color: AppColors.primaryGreen,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const SignInScreen(),
                                        ),
                                      );
                                    },
                                ),
                              ],
                            ),
                          ),
                        ),

                        const Spacer(flex: 3),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    bool isPassword = false,
    bool isEmail = false,
    bool? isVisible,
    VoidCallback? onVisibilityChanged,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: componentHeight,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.inputFill,
            borderRadius: BorderRadius.circular(cornerRadius),
            border: errorText != null
                ? Border.all(color: AppColors.errorRed, width: 1.0)
                : null,
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword && !(isVisible ?? false),
            // Open the Email keyboard layout if it's an email field
            keyboardType: isEmail
                ? TextInputType.emailAddress
                : TextInputType.text,
            style: GoogleFonts.poppins(
              fontSize: 15,
              color: AppColors.colblack,
              fontWeight: FontWeight.w400,
            ),
            textAlignVertical: TextAlignVertical.center,
            decoration: InputDecoration(
              isCollapsed: true,
              hintText: hint,
              hintStyle: GoogleFonts.poppins(
                fontSize: 15,
                color: AppColors.textGrey,
                fontWeight: FontWeight.w400,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              suffixIcon: isPassword
                  ? Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: IconButton(
                        icon: Icon(
                          (isVisible ?? false)
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppColors.grey600,
                          size: 24,
                        ),
                        onPressed: onVisibilityChanged,
                      ),
                    )
                  : null,
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 12),
            child: Text(
              errorText,
              style: GoogleFonts.poppins(
                color: AppColors.errorRed,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}

class _ArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.colwhite
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = const Color(0xFFFFAB40).withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(size.width / 2, 0);
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);

    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width / 2, 0),
      borderPaint,
    );
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width, size.height),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

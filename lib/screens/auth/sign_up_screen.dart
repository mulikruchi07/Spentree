import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spentree/screens/profile/privacy_screen.dart';
import 'package:spentree/screens/profile/terms_screen.dart';
import '../../core/app_style.dart';
import 'verify_number_screen.dart';
import 'sign_in_screen.dart';
import '../../core/user_data.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isChecked = false;
  bool _showTermsError = false;

  // Errors
  String? _nameError;
  String? _phoneError;
  String? _passwordError;
  String? _confirmPasswordError;

  // --- DIMENSIONS ---
  final double horizontalPadding = 24.0;
  final double componentHeight = 60.0;
  final double cornerRadius = 14.0;
  final double inputGap = 16.0;
  final double inputTermsGap = 26.0;
  final double termsButtonGap = 32.0;

  void _validateAndSubmit() {
    setState(() {
      _nameError = null;
      _phoneError = null;
      _passwordError = null;
      _confirmPasswordError = null;
      _showTermsError = false;
    });

    bool isValid = true;

    if (_nameController.text.isEmpty) {
      setState(() => _nameError = "Name is required");
      isValid = false;
    }
    if (_phoneController.text.length != 10) {
      setState(() => _phoneError = "Phone number must be 10 digits");
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
      UserData.userName = _nameController.text;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const VerifyNumberScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
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
                    _buildTextField(_nameController, "Name", errorText: _nameError),
                    SizedBox(height: inputGap),

                    _buildTextField(
                      _phoneController,
                      "Phone Number",
                      isPhone: true,
                      errorText: _phoneError,
                    ),
                    SizedBox(height: inputGap),

                    _buildTextField(
                      _passwordController,
                      "New Password",
                      isPassword: true,
                      isVisible: _isPasswordVisible,
                      onVisibilityChanged: () =>
                          setState(() => _isPasswordVisible = !_isPasswordVisible),
                      errorText: _passwordError,
                    ),
                    SizedBox(height: inputGap),

                    _buildTextField(
                      _confirmPasswordController,
                      "Confirm Password",
                      isPassword: true,
                      isVisible: _isConfirmPasswordVisible,
                      onVisibilityChanged: () => setState(
                        () => _isConfirmPasswordVisible = !_isConfirmPasswordVisible,
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
                                      if (_isChecked) _showTermsError = false;
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 22,
                                    height: 22,
                                    margin: const EdgeInsets.only(top: 2),
                                    decoration: BoxDecoration(
                                      color: _isChecked
                                          ? AppColors.primaryGreen
                                          : AppColors.inputFill,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: _isChecked
                                        ? const Icon(
                                            Icons.check,
                                            size: 16,
                                            color: Colors.white,
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
                                        const TextSpan(text: "I agree to the "),
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
                                                  builder: (context) => const TermsScreen(),
                                                ),
                                              );
                                            },
                                        ),
                                        const TextSpan(text: " and "),
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
                                                  builder: (context) => const PrivacyScreen(),
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
                                    borderRadius: BorderRadius.circular(cornerRadius),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  "Create Account",
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
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
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.orangeAccent.withOpacity(0.5)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.info_outline, size: 16, color: Colors.orange),
                                      const SizedBox(width: 8),
                                      Text(
                                        "Please check this box to proceed.",
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: Colors.black87,
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
                            const TextSpan(text: "Do you have account? "),
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
                                      builder: (context) => const SignInScreen(),
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
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    bool isPassword = false,
    bool isPhone = false,
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
                ? Border.all(color: Colors.redAccent, width: 1.0)
                : null,
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword && !(isVisible ?? false),
            keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
            style: GoogleFonts.poppins(
              fontSize: 15,
              color: AppColors.textMain,
              fontWeight: FontWeight.w400,
            ),
            inputFormatters: isPhone
                ? [
                    LengthLimitingTextInputFormatter(10),
                    FilteringTextInputFormatter.digitsOnly,
                  ]
                : [],
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
                          color: AppColors.grey800,
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
              style: GoogleFonts.poppins(color: Colors.redAccent, fontSize: 12),
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
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    final borderPaint = Paint()
      ..color = Colors.orangeAccent.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(size.width / 2, 0);
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
    
    canvas.drawLine(Offset(0, size.height), Offset(size.width / 2, 0), borderPaint);
    canvas.drawLine(Offset(size.width / 2, 0), Offset(size.width, size.height), borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
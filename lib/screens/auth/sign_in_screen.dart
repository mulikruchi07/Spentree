import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spentree/screens/auth/forgot_password_screen.dart';
import 'package:spentree/screens/main_wrapper.dart';
import '../../core/app_style.dart';
import 'sign_up_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  // Validation Errors
  String? _phoneError;
  String? _passwordError;

  final double horizontalPadding = 24.0;
  final double componentHeight = 60.0;
  final double cornerRadius = 14.0;
  final double inputGap = 16.0;

  void _validateAndSubmit() {
    setState(() {
      _phoneError = null;
      _passwordError = null;
    });

    bool isValid = true;

    if (_phoneController.text.length != 10) {
      setState(() => _phoneError = "Phone number must be 10 digits");
      isValid = false;
    }
    if (_passwordController.text.isEmpty) {
      setState(() => _passwordError = "Password is required");
      isValid = false;
    }

    if (isValid) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MainWrapper()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgWhite,
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
                    const SizedBox(height: 110),

                    Text(
                      "Sign In",
                      style: GoogleFonts.poppins(
                        fontSize: 34,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        "Bounce back to your old forest and start planting again.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: AppColors.grey700,
                          height: 1.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // --- INPUTS ---
                    _buildTextField(
                      _phoneController,
                      "Phone Number",
                      isPhone: true,
                      errorText: _phoneError,
                    ),
                    SizedBox(height: inputGap),

                    _buildTextField(
                      _passwordController,
                      "Password",
                      isPassword: true,
                      isVisible: _isPasswordVisible,
                      onVisibilityChanged: () => setState(
                        () => _isPasswordVisible = !_isPasswordVisible,
                      ),
                      errorText: _passwordError,
                    ),

                    // --- Forgot Password ---
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ForgotPasswordScreen(),
                          ),
                        );
                      },
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: Text(
                            "Forgot Password?",
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // --- Log In Button ---
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
                          "Log In",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppColors.colwhite,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // --- Sign Up Link ---
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
                            TextSpan(text: "Don't have an account? "),
                            TextSpan(
                              text: "Sign Up",
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
                                          const SignUpScreen(),
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
                ? Border.all(color: AppColors.errorRed, width: 1.0)
                : null,
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword && !(isVisible ?? false),
            keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
            style: GoogleFonts.poppins(
              fontSize: 15,
              color: AppColors.colblack,
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
                      padding: const EdgeInsets.only(right: 8.0),
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

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_style.dart';
import 'verify_number_screen.dart';
import 'sign_in_screen.dart';

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

  // Errors
  String? _nameError;
  String? _phoneError;
  String? _passwordError;
  String? _confirmPasswordError;

  // --- UPDATED DIMENSIONS ---
  final double horizontalPadding = 24.0;
  final double componentHeight = 68.0; // Taller to match Figma
  final double cornerRadius = 14.0;
  final double inputGap = 16.0;

  // "Gap between input box and terms text is less in code" -> Increased to 32
  final double inputTermsGap = 32.0;

  // "Create button is too up" -> Increased to 40 to push it down
  final double termsButtonGap = 40.0;

  void _validateAndSubmit() {
    setState(() {
      _nameError = null;
      _phoneError = null;
      _passwordError = null;
      _confirmPasswordError = null;
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please agree to terms", style: GoogleFonts.poppins()),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 1),
        ),
      );
      isValid = false;
    }

    if (isValid) {
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
      resizeToAvoidBottomInset: false, // NO SCROLL when keyboard opens
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Column(
            children: [
              // --- FIXED TOP MARGIN ---
              // Ensures exact same start height on all screens
              const SizedBox(height: 110),

              Text(
                "Sign Up",
                style: GoogleFonts.poppins(
                  fontSize: 34,
                  fontWeight: FontWeight.w600, // Reduced weight from w700
                  color: AppColors.primaryGreen,
                ),
              ),

              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  "Create a new account and start growing today and building a forest.",
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

              // --- Inputs ---
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

              SizedBox(height: inputTermsGap), // Larger gap here
              // --- Terms Checkbox ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _isChecked = !_isChecked),
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
                          color: Colors.black,
                        ),
                        children: [
                          const TextSpan(text: "I agree to the "),
                          TextSpan(
                            text: "terms and conditions",
                            style: const TextStyle(
                              color: AppColors.primaryGreen,
                            ),
                            recognizer: TapGestureRecognizer()..onTap = () {},
                          ),
                          const TextSpan(text: " and "),
                          TextSpan(
                            text: "Privacy Policy",
                            style: const TextStyle(
                              color: AppColors.primaryGreen,
                            ),
                            recognizer: TapGestureRecognizer()..onTap = () {},
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(
                height: termsButtonGap,
              ), // Larger gap to push button down
              // --- Create Account Button ---
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

              const SizedBox(height: 20),

              // --- Sign In Link (Left Aligned) ---
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
            ],
          ),
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
                ? Border.all(
                    color: Colors.redAccent,
                    width: 1.0,
                  ) // Thin red border
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
                      padding: const EdgeInsets.only(
                        right: 16.0,
                      ), // Gap from right
                      child: IconButton(
                        icon: Icon(
                          (isVisible ?? false)
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppColors.textGrey,
                          size: 24, // Increased Eye Size
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

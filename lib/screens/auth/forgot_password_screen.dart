import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_style.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  final double horizontalPadding = 24.0;
  final double componentHeight = 68.0;
  final double cornerRadius = 14.0;
  final double inputGap = 16.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Column(
            children: [
              const SizedBox(height: 110),

              Text(
                "Forgot Password",
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
                  "It happens! Reset your password to safely return to your forest.",
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

              _buildTextField(
                _newPasswordController,
                "New Password",
                isPassword: true,
                isVisible: _isNewPasswordVisible,
                onVisibilityChanged: () => setState(
                  () => _isNewPasswordVisible = !_isNewPasswordVisible,
                ),
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
              ),

              Padding(
                padding: const EdgeInsets.only(top: 16.0, left: 8, right: 8),
                child: Text(
                  "Min. 8 Characters, 1 lowercase, 1 uppercase, 1 number and at least 1 special character.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.grey700,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: componentHeight,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(cornerRadius),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    "Submit",
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
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    bool isPassword = false,
    bool? isVisible,
    VoidCallback? onVisibilityChanged,
  }) {
    return Container(
      height: componentHeight,
      alignment: Alignment
          .center, // This aligns the internal TextField to the center of the Container
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(cornerRadius),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword && !(isVisible ?? false),
        textAlignVertical: TextAlignVertical
            .center, // Centers the text vertically inside the input
        style: GoogleFonts.poppins(
          fontSize: 15,
          color: AppColors.textMain,
          fontWeight: FontWeight.w400,
        ),
        decoration: InputDecoration(
          isCollapsed: true, // Crucial for manual vertical centering
          hintText: hint,
          hintStyle: GoogleFonts.poppins(
            fontSize: 15,
            color: AppColors.textGrey,
            fontWeight: FontWeight.w400,
          ),
          border: InputBorder.none,
          // Symmetric padding ensures the hint text sits exactly in the middle
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 0,
          ),
          suffixIcon: isPassword
              ? Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: IconButton(
                    icon: Icon(
                      (isVisible ?? false)
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.textGrey,
                      size: 24,
                    ),
                    onPressed: onVisibilityChanged,
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

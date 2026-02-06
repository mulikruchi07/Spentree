import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_style.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  // Spacing and UI Constants
  final double horizontalPadding = 24.0;
  final double componentHeight = 68.0;
  final double cornerRadius = 14.0;
  final double inputGap = 16.0;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // --- Success Toast Logic ---
  void _showSuccessToast(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.only(bottom: 20, left: 24, right: 24),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF34C759), // SpenTree Primary Green
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF34C759).withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Password changed successfully!",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
              // Standard top margin matching your auth pages
              const SizedBox(height: 110),

              Text(
                "Change Password",
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
                  "Change your password to improve security & protect your forest",
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

              // New Password
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

              // Confirm Password
              _buildTextField(
                _confirmPasswordController,
                "Confirm Password",
                isPassword: true,
                isVisible: _isConfirmPasswordVisible,
                onVisibilityChanged: () => setState(
                  () => _isConfirmPasswordVisible = !_isConfirmPasswordVisible,
                ),
              ),

              // Requirements
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

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: componentHeight,
                child: ElevatedButton(
                  onPressed: () {
                    // Trigger success toast
                    _showSuccessToast(context);

                    // Navigate back to Account Screen after toast appears
                    Timer(const Duration(seconds: 2), () {
                      if (mounted) Navigator.pop(context);
                    });
                  },
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

  // --- Centered Hint Text Field ---
  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    bool isPassword = false,
    bool? isVisible,
    VoidCallback? onVisibilityChanged,
  }) {
    return Container(
      height: componentHeight,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.inputFill, // F1F1F1
        borderRadius: BorderRadius.circular(cornerRadius),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword && !(isVisible ?? false),
        textAlignVertical:
            TextAlignVertical.center, // Pixel-perfect vertical centering
        style: GoogleFonts.poppins(
          fontSize: 15,
          color: AppColors.textMain,
          fontWeight: FontWeight.w400,
        ),
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

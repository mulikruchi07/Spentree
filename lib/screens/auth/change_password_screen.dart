import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spentree/core/error_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/app_style.dart';
import '../main_wrapper.dart';

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
  bool _isLoading = false;

  String? _newPasswordError;
  String? _confirmPasswordError;
  String? _successMessage;

  final double horizontalPadding = 24.0;
  final double componentHeight = 60.0;
  final double cornerRadius = 14.0;
  final double inputGap = 16.0;

  static final _passwordPattern = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$&*~^%()_\-+=]).{8,}$',
  );
  static const _passwordRuleMessage =
      "Password must be at least 8 characters and include an uppercase letter, a lowercase letter, a number, and a symbol.";

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _validateAndSubmit() async {
    setState(() {
      _newPasswordError = null;
      _confirmPasswordError = null;
      _successMessage = null;
    });

    bool isValid = true;
    final newPassword = _newPasswordController.text;

    if (newPassword.isEmpty) {
      setState(() => _newPasswordError = "New password is required");
      isValid = false;
    } else if (!_passwordPattern.hasMatch(newPassword)) {
      setState(() => _newPasswordError = _passwordRuleMessage);
      isValid = false;
    }

    if (_confirmPasswordController.text != newPassword) {
      setState(() => _confirmPasswordError = "Passwords do not match");
      isValid = false;
    }

    if (!isValid) return;

    setState(() => _isLoading = true);
    try {
      final hasInternet = await checkInternetConnection();
if (!hasInternet) {
  setState(() => _newPasswordError = "No internet connection. Please check your network and try again.");
  return;
}
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      setState(() => _successMessage = "Password changed successfully!");

      Timer(const Duration(milliseconds: 1200), () {
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const MainWrapper()),
            (route) => false,
          );
        }
      });
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('password')) {
        setState(() => _newPasswordError = _passwordRuleMessage);
      } else {
        setState(() => _newPasswordError = mapAuthError(e));
      }
    } catch (e) {
      setState(
        () => _newPasswordError = "Something went wrong. Please try again.",
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
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

                        _buildTextField(
                          _newPasswordController,
                          "New Password",
                          isPassword: true,
                          isVisible: _isNewPasswordVisible,
                          onVisibilityChanged: () => setState(
                            () =>
                                _isNewPasswordVisible = !_isNewPasswordVisible,
                          ),
                          errorText: _newPasswordError,
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

                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(
                              top: 16.0,
                              left: 4,
                              right: 4,
                            ),
                            child: Text(
                              "Min. 8 Characters, 1 lowercase, 1 uppercase, 1 number and at least 1 special character.",
                              textAlign: TextAlign.left,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: AppColors.grey700,
                              ),
                            ),
                          ),
                        ),

                        if (_successMessage != null)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                top: 12.0,
                                left: 4,
                                right: 4,
                              ),
                              child: Text(
                                _successMessage!,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.primaryGreen,
                                ),
                              ),
                            ),
                          ),

                        const SizedBox(height: 32),

                        SizedBox(
                          width: double.infinity,
                          height: componentHeight,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _validateAndSubmit,
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
                                    "Submit",
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.colwhite,
                                    ),
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
            textAlignVertical: TextAlignVertical.center,
            style: GoogleFonts.poppins(
              fontSize: 15,
              color: AppColors.colblack,
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

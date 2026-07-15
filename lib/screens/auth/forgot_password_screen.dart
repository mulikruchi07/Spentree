import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spentree/core/auth_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import '../../core/app_style.dart';
import 'sign_in_screen.dart';
import 'package:spentree/core/error_helper.dart';

enum _ForgotStep { email, otp, newPassword }

class ForgotPasswordScreen extends StatefulWidget {
  final String? prefilledEmail;
  const ForgotPasswordScreen({super.key, this.prefilledEmail});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  _ForgotStep _step = _ForgotStep.email;

  final _emailController = TextEditingController();
  late final List<TextEditingController> _otpControllers;
  late final List<FocusNode> _otpFocusNodes;
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  String? _emailError;
  String? _otpError;
  String? _newPasswordError;
  String? _confirmPasswordError;
  String? _emailInfo;

  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  final double horizontalPadding = 24.0;
  final double componentHeight = 60.0;
  final double cornerRadius = 14.0;
  final double inputGap = 16.0;
  final int otpLength = 6;
  final double otpBoxWidth = 50.0;
  final double otpBoxHeight = 65.0;

  @override
  void initState() {
    super.initState();
    if (widget.prefilledEmail != null) {
      _emailController.text = widget.prefilledEmail!;
    }
    _otpControllers = List.generate(otpLength, (_) => TextEditingController());
    _otpFocusNodes = List.generate(otpLength, (_) => FocusNode());
  }

  @override
  void dispose() {
    _emailController.dispose();
    for (var c in _otpControllers) c.dispose();
    for (var n in _otpFocusNodes) n.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  // ── STEP 1: send code ──────────────────────────────────────────────
  Future<void> _sendCode() async {
    setState(() {
      _emailError = null;
      _emailInfo = null;
    });
    final email = _emailController.text.trim();
    final _emailRegex = RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,}$');

    if (email.isEmpty || !_emailRegex.hasMatch(email)) {
      setState(() => _emailError = "Please enter a valid email address");
      return;
    }

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
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      _showGenericSentMessageAndProceed();
    } on AuthException catch (e) {
      final msg = mapAuthError(e).toLowerCase();
      if (msg.contains('second') || msg.contains('security')) {
        setState(
          () => _emailError =
              "Too many requests. Please wait a moment and try again.",
        );
      } else {
        // Never confirm/deny account existence, even on unexpected auth errors.
        _showGenericSentMessageAndProceed();
      }
    } catch (e) {
      _showGenericSentMessageAndProceed();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showGenericSentMessageAndProceed() {
    if (!mounted) return;
    setState(
      () => _emailInfo =
          "If that email exists in our system, we've sent a recovery code to it.",
    );
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _step = _ForgotStep.otp);
    });
  }

  // ── STEP 2: verify code ────────────────────────────────────────────
  Future<void> _verifyCode() async {
    setState(() => _otpError = null);
    final otp = _otpControllers.map((c) => c.text).join();

    if (otp.length != otpLength) {
      setState(() => _otpError = "Please enter the complete 6-digit code.");
      return;
    }

    setState(() => _isLoading = true);
    try {
      final hasInternet = await checkInternetConnection();
      if (!hasInternet) {
        setState(
          () => _otpError =
              "No internet connection. Please check your network and try again.",
        );
        return;
      }
      await Supabase.instance.client.auth.verifyOTP(
        type: OtpType.recovery,
        token: otp,
        email: _emailController.text.trim(),
      );
      if (mounted) setState(() => _step = _ForgotStep.newPassword);
    } on AuthException catch (e) {
      setState(() => _otpError = "Invalid code. Please try again.");
      debugPrint("Recovery OTP error: ${mapAuthError(e)}");
    } catch (e) {
      setState(() => _otpError = "Invalid code. Please try again.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendCode() async {
    if (_resendCooldown > 0) return;
    try {
      await Supabase.instance.client.auth.resend(
        type: OtpType.recovery,
        email: _emailController.text.trim(),
      );
      if (mounted) {
        setState(() {
          _otpError = null;
        });
        _startCooldown(60);
        setState(() => _resendMessage = "Code resent! Check your inbox.");
      }
    } on AuthException catch (e) {
      final seconds = RegExp(
        r'(\d+) second',
      ).firstMatch(mapAuthError(e))?.group(1);
      setState(() {
        _resendMessage = seconds != null
            ? "You can request a new code after $seconds seconds for security reasons."
            : mapAuthError(e);
        _resendIsError = true;
      });
      if (seconds != null) _startCooldown(int.parse(seconds));
      return;
    } catch (e) {
      setState(() {
        _resendMessage = "Couldn't resend the code. Please try again.";
        _resendIsError = true;
      });
      return;
    }
    setState(() => _resendIsError = false);
  }

  String? _resendMessage;
  bool _resendIsError = false;

  void _startCooldown(int seconds) {
    _cooldownTimer?.cancel();
    setState(() => _resendCooldown = seconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_resendCooldown <= 1) {
        timer.cancel();
        setState(() => _resendCooldown = 0);
      } else {
        setState(() => _resendCooldown--);
      }
    });
  }

  // ── STEP 3: set new password ───────────────────────────────────────
  Future<void> _submitNewPassword() async {
    setState(() {
      _newPasswordError = null;
      _confirmPasswordError = null;
    });

    bool isValid = true;
    final passwordPattern = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$&*~^%()_\-+=]).{8,}$',
    );

    if (_newPasswordController.text.isEmpty) {
      setState(() => _newPasswordError = "New password is required");
      isValid = false;
    } else if (!passwordPattern.hasMatch(_newPasswordController.text)) {
      setState(
        () => _newPasswordError =
            "Password must be at least 8 characters and include an uppercase letter, a lowercase letter, a number, and a symbol.",
      );
      isValid = false;
    }
    if (_confirmPasswordController.text != _newPasswordController.text) {
      setState(() => _confirmPasswordError = "Passwords do not match");
      isValid = false;
    }
    if (!isValid) return;

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: _newPasswordController.text),
      );
      await AuthHelper.signOutEverywhere();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const SignInScreen()),
          (route) => false,
        );
      }
    } on AuthException catch (e) {
      setState(() => _newPasswordError = mapAuthError(e));
    } catch (e) {
      setState(
        () => _newPasswordError = "Something went wrong. Please try again.",
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _subtitleFor(_ForgotStep step) {
    switch (step) {
      case _ForgotStep.email:
        return "It happens! Reset your password to safely return to your forest.";
      case _ForgotStep.otp:
        return "If that email exists in our system, we've sent a 6-digit code to it.";
      case _ForgotStep.newPassword:
        return "Almost there — choose a new password for your account.";
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

                        // Static header — never rebuilt by the step switcher
                        Text(
                          "Forgot Password",
                          style: GoogleFonts.poppins(
                            fontSize: 34,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                        const SizedBox(height: 16),

                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          switchInCurve: Curves.easeOut,
                          switchOutCurve: Curves.easeIn,
                          transitionBuilder: (child, animation) =>
                              FadeTransition(opacity: animation, child: child),
                          child: KeyedSubtree(
                            key: ValueKey(_step),
                            child: _buildStepContent(),
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

  Widget _buildStepContent() {
    switch (_step) {
      case _ForgotStep.email:
        return _buildEmailStep();
      case _ForgotStep.otp:
        return _buildOtpStep();
      case _ForgotStep.newPassword:
        return _buildNewPasswordStep();
    }
  }

  // ── STEP 1 UI ───────────────────────────────────────────────────────
  Widget _buildEmailStep() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            _subtitleFor(_ForgotStep.email),
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

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: componentHeight,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                borderRadius: BorderRadius.circular(cornerRadius),
                border: _emailError != null
                    ? Border.all(color: AppColors.errorRed, width: 1.0)
                    : null,
              ),
              child: TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textAlignVertical: TextAlignVertical.center,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: AppColors.colblack,
                  fontWeight: FontWeight.w400,
                ),
                decoration: InputDecoration(
                  isCollapsed: true,
                  hintText: "Email Address",
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 15,
                    color: AppColors.textGrey,
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                ),
              ),
            ),
            if (_emailError != null)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 12),
                child: Text(
                  _emailError!,
                  style: GoogleFonts.poppins(
                    color: AppColors.errorRed,
                    fontSize: 12,
                  ),
                ),
              ),
            if (_emailError == null && _emailInfo != null)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 12),
                child: Text(
                  _emailInfo!,
                  style: GoogleFonts.poppins(
                    color: AppColors.primaryGreen,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 32),

        SizedBox(
          width: double.infinity,
          height: componentHeight,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _sendCode,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(cornerRadius),
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
                    "Send Code",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.colwhite,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  // ── STEP 2 UI ───────────────────────────────────────────────────────
  Widget _buildOtpStep() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            _subtitleFor(_ForgotStep.otp),
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

        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              otpLength,
              (index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: _buildOtpDigitBox(index),
              ),
            ),
          ),
        ),

        if (_otpError != null)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Text(
              _otpError!,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: AppColors.errorRed,
                fontSize: 13,
              ),
            ),
          ),
        if (_otpError == null && _resendMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Text(
              _resendMessage!,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: _resendIsError
                    ? AppColors.errorRed
                    : AppColors.primaryGreen,
                fontSize: 13,
              ),
            ),
          ),

        const SizedBox(height: 32),

        SizedBox(
          width: double.infinity,
          height: componentHeight,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _verifyCode,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(cornerRadius),
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
                    "Verify",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.colwhite,
                    ),
                  ),
          ),
        ),

        const SizedBox(height: 20),

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
                const TextSpan(text: "Didn't get the code? "),
                TextSpan(
                  text: _resendCooldown > 0
                      ? "Resend in ${_resendCooldown}s"
                      : "Resend",
                  style: TextStyle(
                    color: _resendCooldown > 0
                        ? AppColors.textGrey
                        : AppColors.primaryGreen,
                    fontWeight: FontWeight.w400,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = _resendCooldown > 0 ? null : _resendCode,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpDigitBox(int index) {
    return Container(
      width: otpBoxWidth,
      height: otpBoxHeight,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(12),
        border: _otpError != null
            ? Border.all(color: AppColors.errorRed, width: 1)
            : null,
      ),
      child: TextField(
        controller: _otpControllers[index],
        focusNode: _otpFocusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: AppColors.colblack,
        ),
        decoration: const InputDecoration(
          counterText: "",
          border: InputBorder.none,
          isCollapsed: true,
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (value) {
          if (value.isNotEmpty && index < otpLength - 1) {
            FocusScope.of(context).requestFocus(_otpFocusNodes[index + 1]);
          } else if (value.isEmpty && index > 0) {
            FocusScope.of(context).requestFocus(_otpFocusNodes[index - 1]);
          }
          if (_otpError != null) setState(() => _otpError = null);
        },
      ),
    );
  }

  // ── STEP 3 UI (restored from your commented block) ────────────────
  Widget _buildNewPasswordStep() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            _subtitleFor(_ForgotStep.newPassword),
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

        _buildPasswordField(
          _newPasswordController,
          "New Password",
          isVisible: _isNewPasswordVisible,
          onVisibilityChanged: () =>
              setState(() => _isNewPasswordVisible = !_isNewPasswordVisible),
          errorText: _newPasswordError,
        ),
        SizedBox(height: inputGap),
        _buildPasswordField(
          _confirmPasswordController,
          "Confirm Password",
          isVisible: _isConfirmPasswordVisible,
          onVisibilityChanged: () => setState(
            () => _isConfirmPasswordVisible = !_isConfirmPasswordVisible,
          ),
          errorText: _confirmPasswordError,
        ),

        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(top: 16.0, left: 4, right: 4),
            child: Text(
              "Min. 8 Characters, 1 lowercase, 1 uppercase, 1 number and at least 1 special character.",
              textAlign: TextAlign.left,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: AppColors.divider,
              ),
            ),
          ),
        ),

        const SizedBox(height: 32),

        SizedBox(
          width: double.infinity,
          height: componentHeight,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _submitNewPassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(cornerRadius),
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
      ],
    );
  }

  Widget _buildPasswordField(
    TextEditingController controller,
    String hint, {
    required bool isVisible,
    required VoidCallback onVisibilityChanged,
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
            obscureText: !isVisible,
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
              suffixIcon: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: IconButton(
                  icon: Icon(
                    isVisible
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: AppColors.grey600,
                    size: 24,
                  ),
                  onPressed: onVisibilityChanged,
                ),
              ),
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

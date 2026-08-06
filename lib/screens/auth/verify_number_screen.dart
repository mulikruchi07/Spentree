import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spentree/core/error_helper.dart';
import 'package:spentree/screens/main_wrapper.dart';
import 'package:spentree/core/transaction_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/app_style.dart';
import '../auth/change_password_screen.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String email; // Accept the email from the sign-up screen
  final bool isRecovery; // Add this flag
  final bool isEmailChange;

  const VerifyEmailScreen({
    super.key,
    required this.email,
    this.isRecovery = false,
    this.isEmailChange = false,
  });

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final int otpLength = 6; // SUPABASE OTPS ARE 6 DIGITS
  final double horizontalPadding = 24.0;
  final double otpBoxWidth = 50.0; // Slightly smaller to fit 6 boxes
  final double otpBoxHeight = 65.0;
  final double componentHeight = 60.0;
  final double cornerRadius = 14.0;

  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;
  String? _statusMessage;
  bool _isError = true;
  bool _isLoading = false;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(otpLength, (_) => TextEditingController());
    _focusNodes = List.generate(otpLength, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (var c in _controllers) c.dispose();
    for (var n in _focusNodes) n.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    setState(() {
      _statusMessage = null;
      _isLoading = true;
    });

    String otp = _controllers.map((c) => c.text).join();

    if (otp.length != otpLength) {
      setState(() {
        _statusMessage = "Please enter the complete 6-digit code.";
        _isError = true;
        _isLoading = false;
      });
      return;
    }

    try {
      final hasInternet = await checkInternetConnection();
      if (!hasInternet) {
        setState(() {
          _statusMessage =
              "No internet connection. Please check your network and try again.";
          _isError = true;
        });
        return;
      }
      await Supabase.instance.client.auth.verifyOTP(
        type: widget.isEmailChange
            ? OtpType.emailChange
            : (widget.isRecovery ? OtpType.recovery : OtpType.signup),
        token: otp,
        email: widget.email,
      );

      if (widget.isEmailChange && mounted) {
        Navigator.pop(context, true);
        return;
      }
    } on AuthException catch (e) {
      setState(() {
        _statusMessage = "Invalid code. Please try again.";
        _isError = true;
      });
      debugPrint("OTP Error: ${mapAuthError(e)}");
    } catch (e) {
      setState(() {
        _statusMessage = "Invalid code. Please try again.";
        _isError = true;
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendOtp() async {
    if (_resendCooldown > 0) return;
    try {
      final hasInternet = await checkInternetConnection();
      if (!hasInternet) {
        setState(() {
          _statusMessage =
              "No internet connection. Please check your network and try again.";
          _isError = true;
        });
        return;
      }
      await Supabase.instance.client.auth.resend(
        type: widget.isEmailChange
            ? OtpType.emailChange
            : (widget.isRecovery ? OtpType.recovery : OtpType.signup),
        email: widget.email,
      );
      if (mounted) {
        setState(() {
          _statusMessage = "OTP resent! Check your inbox.";
          _isError = false;
        });
        _startCooldown(60);
      }
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      final seconds = RegExp(r'(\d+) second').firstMatch(e.message)?.group(1);
      if (seconds != null) {
        setState(() {
          _statusMessage =
              "You can request a new code after $seconds seconds for security reasons.";
          _isError = true;
        });
        _startCooldown(int.parse(seconds));
      } else if (msg.contains('rate limit') || msg.contains('too many')) {
        setState(() {
          _statusMessage =
              "Too many attempts. Please wait a few minutes and try again.";
          _isError = true;
        });
      } else {
        setState(() {
          _statusMessage = e.message;
          _isError = true;
        });
      }
    }
  }

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

  @override
  Widget build(BuildContext context) {
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
                          "Verify Email",
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
                            "Enter the 6-digit code we just sent to\n${widget.email}",
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4.0,
                                ),
                                child: _buildOtpDigitBox(index),
                              ),
                            ),
                          ),
                        ),

                        if (_statusMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: Text(
                              _statusMessage!,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                color: _isError
                                    ? AppColors.errorRed
                                    : AppColors.primaryGreen,
                                fontSize: 13,
                              ),
                            ),
                          ),

                        const SizedBox(height: 40),

                        SizedBox(
                          width: double.infinity,
                          height: componentHeight,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _verifyOtp,
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
                                const TextSpan(text: "Didn’t get the code? "),
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
                                    ..onTap = _resendCooldown > 0
                                        ? null
                                        : _resendOtp,
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

  Widget _buildOtpDigitBox(int index) {
    return Container(
      width: otpBoxWidth,
      height: otpBoxHeight,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(12),
        border: (_isError && _statusMessage != null)
            ? Border.all(color: AppColors.errorRed, width: 1)
            : null,
      ),
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
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
            FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
          } else if (value.isEmpty && index > 0) {
            FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
          }
          if (_statusMessage != null) setState(() => _statusMessage = null);
        },
      ),
    );
  }
}

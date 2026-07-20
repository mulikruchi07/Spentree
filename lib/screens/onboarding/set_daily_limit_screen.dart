import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/app_style.dart';
import '../../core/user_data.dart';
import '../../core/auth_helper.dart';

class SetDailyLimitScreen extends StatefulWidget {
  final Widget nextScreen;
  const SetDailyLimitScreen({super.key, required this.nextScreen});

  @override
  State<SetDailyLimitScreen> createState() => _SetDailyLimitScreenState();
}

class _SetDailyLimitScreenState extends State<SetDailyLimitScreen> {
  final _amountController = TextEditingController();
  String? _inlineError;
  bool _isLoading = false;

  final double horizontalPadding = 24.0;
  final double componentHeight = 60.0;
  final double cornerRadius = 14.0;

  Future<void> _handleContinue() async {
    setState(() => _inlineError = null);

    if (_amountController.text.trim().isEmpty) {
      setState(() => _inlineError = "Please enter an amount.");
      return;
    }

    setState(() => _isLoading = true);

    final limitValue = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final nowIso = DateTime.now().toUtc().toIso8601String();

    // Reuses the exact same local-save method the questionnaire uses —
    // no duplicated logic. This already sets questionnaire_sync_pending.
    await UserData.saveQuestionnaireData(
      dailyLimitValue: limitValue,
      category: UserData.spendingCategory, // preserved if already set, else ""
      goal: UserData.spendingGoal,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('daily_expense_limit', int.tryParse(limitValue) ?? 5000);
    await prefs.setString('last_limit_change', nowIso);
    await prefs.setBool('has_completed_onboarding', true);
    final user = Supabase.instance.client.auth.currentUser;

    if (user != null) {
      await prefs.setBool('questionnaire_answered_${user.id}', true);
    }

    // Fire-and-forget cloud sync — never block navigation on network.
    // Uses the existing encrypted user-field sync helper, same one used
    // everywhere else. last_limit_change is a separate plaintext update
    // since the 7-day check reads it directly in SQL.
    unawaited(_syncToCloud(limitValue, nowIso));

    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => widget.nextScreen),
      );
    }
  }

  Future<void> _syncToCloud(String limitValue, String nowIso) async {
    try {
      await AuthHelper.syncEncryptedUserFields({'daily_limit': limitValue});
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await Supabase.instance.client
            .from('users')
            .update({'last_limit_change': nowIso})
            .eq('id', user.id)
            .timeout(const Duration(seconds: 8));
      }
    } catch (e) {
      debugPrint("Daily limit cloud sync deferred: $e");
    }
  }

  Widget _buildQuickButton(String amount) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          final current = int.tryParse(_amountController.text.trim()) ?? 0;
          final add = int.parse(amount);
          
          final newValue = (current + add).toString();
          // Updates text and keeps cursor at the end
          _amountController.value = TextEditingValue(
            text: newValue,
            selection: TextSelection.collapsed(offset: newValue.length),
          );

          setState(() => _inlineError = null);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.inputFill,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add, size: 16, color: AppColors.white600),
              const SizedBox(width: 4),
              Text(
                "Rs. $amount",
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w500,
                  color: AppColors.white600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
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
                        const Spacer(flex: 1),
                        Text(
                          "Set Your Daily Limit",
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
                            "This is the amount you don't want to cross in a day.",
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

                        // --- Reused verbatim from questionnaire_screen.dart ---
                        Container(
                          height: componentHeight,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.inputFill,
                            borderRadius: BorderRadius.circular(cornerRadius),
                          ),
                          child: TextField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            textAlignVertical: TextAlignVertical.center,
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              color: AppColors.colblack,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              isCollapsed: true,
                              hintText: "Enter the amount",
                              hintStyle: GoogleFonts.montserrat(
                                color: AppColors.grey600,
                                fontSize: 16,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              suffixIcon: Padding(
                                padding: const EdgeInsets.only(right: 20),
                                // Using Row with minAxisSize ensures perfect vertical centering
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "INR",
                                      style: GoogleFonts.montserrat(
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.colblack,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            onChanged: (_) {
                              if (_inlineError != null) {
                                setState(() => _inlineError = null);
                              }
                            },
                          ),
                        ),

                        const SizedBox(height: 16),

                        // The "Or" Divider Line
                        Row(
                          children: [
                            const Expanded(child: Divider(color: AppColors.inactiveGrey)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                "Or",
                                style: AppTextStyles.body.copyWith(fontSize: 14),
                              ),
                            ),
                            const Expanded(child: Divider(color: AppColors.inactiveGrey)),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Quick Add Buttons
                        Row(
                          children: [
                            _buildQuickButton("500"),
                            const SizedBox(width: 12),
                            _buildQuickButton("1000"),
                            const SizedBox(width: 12),
                            _buildQuickButton("5000"),
                          ],
                        ),

                        // Inline Error Display
                        if (_inlineError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12.0),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                _inlineError!,
                                style: GoogleFonts.poppins(
                                  color: AppColors.errorRed,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),

                        const SizedBox(height: 32),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          height: componentHeight,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleContinue,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryGreen,
                              // Added Drop Shadow properties here
                              elevation: 6,
                              shadowColor: AppColors.primaryGreen.withOpacity(0.4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(cornerRadius),
                              ),
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
                                    "Submit", // Changed from "Continue"
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.colwhite,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 12),
                        
                        // Left-Aligned Note
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Note: Limit can be changed only once a week.",
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: AppColors.grey700,
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
}
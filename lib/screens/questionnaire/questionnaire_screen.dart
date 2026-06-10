import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_style.dart';
import 'package:flutter/services.dart';
import '../onboarding/loading_screen.dart';
import '../../core/user_data.dart';

class QuestionnaireScreen extends StatefulWidget {
  const QuestionnaireScreen({super.key});

  @override
  State<QuestionnaireScreen> createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
  final PageController _controller = PageController();
  int _currentIndex = 0;

  // --- STATE VARIABLES ---
  final TextEditingController _amountController = TextEditingController();
  String? _selectedCategory;
  String? _selectedGoal;
  String? _inlineError;

  // --- BASE DIMENSIONS ---
  final double textPadding = 24.0;
  final double descPadding = 60.0;
  final double cornerRadius = 14.0;
  final double componentHeight = 64.0;

  // Data Lists
  final List<String> _categories = [
    "Food & Drinks",
    "Shopping",
    "Entertainment",
    "Other",
  ];
  final List<String> _goals = [
    "Save more money",
    "Control daily spending",
    "Understand where my money goes",
    "Build better money habits",
  ];

  // --- VALIDATION ---
  bool _validateCurrentPage() {
    setState(() => _inlineError = null);
    if (_currentIndex == 0 && _amountController.text.trim().isEmpty) {
      setState(() => _inlineError = "Please enter an amount.");
      return false;
    } else if (_currentIndex == 1 && _selectedCategory == null) {
      setState(() => _inlineError = "Please select a category.");
      return false;
    } else if (_currentIndex == 2 && _selectedGoal == null) {
      setState(() => _inlineError = "Please select a goal.");
      return false;
    }
    return true;
  }

  void _nextPage() {
    if (_validateCurrentPage()) {
      if (_currentIndex < 2) {
        _controller.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeIn,
        );
      }
    }
  }

  void _previousPage() {
    setState(() => _inlineError = null);
    if (_currentIndex > 0) {
      _controller.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    MediaQuery.platformBrightnessOf(context);

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentTheme, child) {
        // DYNAMIC SCALING
        final size = MediaQuery.of(context).size;
        final double height = size.height;
        final double scale = (height / 820.0).clamp(0.85, 1.0);

        // --- PRECISE FIXED GAPS ---
        final double topMargin = 90.0 * scale;
        final double stepToBarGap = 20.0 * scale;
        final double barToQuestionGap = 24.0 * scale; // Fixed Gap

        return Scaffold(
          backgroundColor: AppColors.bgWhite,
          resizeToAvoidBottomInset: true,
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Calculate header height to determine remaining space for PageView
                double headerHeight =
                    topMargin +
                    (30 * scale) +
                    stepToBarGap +
                    6 +
                    barToQuestionGap;
                double availableContentHeight =
                    constraints.maxHeight - headerHeight - topMargin;

                // Ensure a minimum height for PageView to prevent layout collapse
                double finalPageViewHeight = max(300.0, availableContentHeight);

                return SingleChildScrollView(
                  // Main scroll handles keyboard events for the whole screen
                  child: Column(
                    children: [
                      // 1. STATIC HEADER
                      SizedBox(height: topMargin),

                      Text(
                        _currentIndex == 0
                            ? "Step 1"
                            : _currentIndex == 1
                            ? "Step 2"
                            : "We’re almost ready!",
                        style: GoogleFonts.montserrat(
                          fontSize: 20 * scale,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryGreen,
                        ),
                      ),

                      SizedBox(height: stepToBarGap),

                      _buildProgressBar(),

                      SizedBox(height: barToQuestionGap),

                      // 2. CONTENT AREA (PageView)
                      SizedBox(
                        height: finalPageViewHeight,
                        child: PageView(
                          controller: _controller,
                          physics: const NeverScrollableScrollPhysics(),
                          onPageChanged: (index) =>
                              setState(() => _currentIndex = index),
                          children: [
                            _buildSafePage(_buildQuestionOne(scale)),
                            _buildSafePage(_buildQuestionTwo(scale)),
                            _buildSafePage(_buildQuestionThree(scale)),
                          ],
                        ),
                      ),

                      // Bottom spacing
                      SizedBox(height: topMargin),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  // --- SAFE PAGE WRAPPER (Fixes Pixel Overflow) ---
  // This wraps every question page. If content fits, it centers it.
  // If content is too big (small screen), it scrolls.
  Widget _buildSafePage(Widget content) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints
                  .maxHeight, // Forces minimum height to match container
            ),
            child: IntrinsicHeight(
              child: content, // The actual question content
            ),
          ),
        );
      },
    );
  }

  // --- PROGRESS BAR ---
  Widget _buildProgressBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 40,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            color: index == _currentIndex
                ? AppColors.primaryGreen
                : AppColors.inactiveGrey,
          ),
        );
      }),
    );
  }

  // --- PAGE 1: DAILY LIMIT ---
  Widget _buildQuestionOne(double scale) {
    final double subTextToInputGap = 25.0 * scale;
    final double quickToSubmitGap = 23.0 * scale;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: textPadding * scale),
            child: Text(
              "What’s your daily spending limit?",
              textAlign: TextAlign.center,
              style: AppTextStyles.title.copyWith(
                fontSize: 24 * scale,
                color: AppColors.colblack,
              ),
            ),
          ),
          SizedBox(height: 12 * scale),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: descPadding * scale),
            child: Text(
              "This is the amount you don't want to cross in a day.",
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w600,
                fontSize: 16 * scale,
                color: AppColors.subtext,
              ),
            ),
          ),

          SizedBox(height: subTextToInputGap),

          // Input Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Container(
              height: componentHeight * scale,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                borderRadius: BorderRadius.circular(cornerRadius),
              ),
              child: TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textAlignVertical: TextAlignVertical.center,
                style: GoogleFonts.montserrat(
                  fontSize: 16 * scale,
                  color: AppColors.colblack,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  isCollapsed: true,
                  hintText: "Enter the amount",
                  hintStyle: GoogleFonts.montserrat(
                    color: AppColors.grey600,
                    fontSize: 16 * scale,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  suffixIcon: Padding(
                    padding: const EdgeInsets.only(right: 20),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "INR",
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.w500,
                            color: AppColors.colblack,
                            fontSize: 16 * scale,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                onChanged: (_) {
                  if (_inlineError != null) setState(() => _inlineError = null);
                },
              ),
            ),
          ),

          SizedBox(height: 16 * scale),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              children: [
                const Expanded(child: Divider(color: AppColors.inactiveGrey)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    "Or",
                    style: AppTextStyles.body.copyWith(fontSize: 14 * scale),
                  ),
                ),
                const Expanded(child: Divider(color: AppColors.inactiveGrey)),
              ],
            ),
          ),

          SizedBox(height: 24 * scale),

          // Quick Select Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              children: [
                _buildQuickButton("500", scale),
                SizedBox(width: 12 * scale),
                _buildQuickButton("1000", scale),
                SizedBox(width: 12 * scale),
                _buildQuickButton("5000", scale),
              ],
            ),
          ),

          if (_inlineError != null)
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Text(
                _inlineError!,
                style: GoogleFonts.poppins(
                  color: AppColors.errorRed,
                  fontSize: 13 * scale,
                ),
              ),
            ),

          SizedBox(height: quickToSubmitGap),

          // Submit Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: _buildMainButton(
              label: "Submit",
              onTap: () => _nextPage(),
              scale: scale,
            ),
          ),
        ],
      ),
    );
  }

  // --- UNIFIED LIST BUILDER FOR Q2 & Q3 ---
  Widget _buildListQuestion({
    required double scale,
    required String title,
    required String subtext,
    required List<String> items,
    required String? selectedItem,
    required Function(String) onItemSelected,
    required bool isDone,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: textPadding * scale),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.title.copyWith(
                fontSize: 24 * scale,
                color: AppColors.colblack,
              ),
            ),
          ),
          SizedBox(height: 12 * scale),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: descPadding * scale),
            child: Text(
              subtext,
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w600,
                fontSize: 16 * scale,
                color: AppColors.subtext,
              ),
            ),
          ),

          SizedBox(height: 25 * scale),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: items.map((item) {
                return Padding(
                  padding: EdgeInsets.only(bottom: 12 * scale),
                  child: _buildSelectionCard(
                    label: item,
                    isSelected: selectedItem == item,
                    scale: scale,
                    onTap: () {
                      onItemSelected(item);
                      setState(() => _inlineError = null);
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          if (_inlineError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: Text(
                _inlineError!,
                style: GoogleFonts.poppins(
                  color: AppColors.errorRed,
                  fontSize: 13 * scale,
                ),
              ),
            ),

          SizedBox(height: 20 * scale),

          // Next / Done Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: _buildMainButton(
              label: isDone ? "Done" : "Next",
              scale: scale,
              onTap: () {
                if (isDone) {
                  if (_validateCurrentPage()) {
                    if (_amountController.text.isNotEmpty) {
                      UserData.dailyLimit = _amountController.text.replaceAll(
                        RegExp(r'[^0-9]'),
                        '',
                      );
                    }
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoadingScreen(),
                      ),
                    );
                  }
                } else {
                  _nextPage();
                }
              },
            ),
          ),

          SizedBox(height: 12 * scale),

          // Previous Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: _buildPreviousButton(
              onTap: () => _previousPage(),
              scale: scale,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionTwo(double scale) {
    return _buildListQuestion(
      scale: scale,
      title: "What are you usually spending on?",
      subtext: "We’ll use this to show better insights.",
      items: _categories,
      selectedItem: _selectedCategory,
      onItemSelected: (val) => setState(() => _selectedCategory = val),
      isDone: false,
    );
  }

  Widget _buildQuestionThree(double scale) {
    return _buildListQuestion(
      scale: scale,
      title: "What’s your goal with SpenTree?",
      subtext: "Your goal helps us guide your forest journey.",
      items: _goals,
      selectedItem: _selectedGoal,
      onItemSelected: (val) => setState(() => _selectedGoal = val),
      isDone: true,
    );
  }

  // --- HELPER: QUICK BUTTON ---
  Widget _buildQuickButton(String amount, double scale) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          _amountController.text = amount;
          setState(() => _inlineError = null);
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 16 * scale),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.inputFill,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(
            "Rs. $amount",
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w500,
              color: AppColors.white600,
              fontSize: 14 * scale,
            ),
          ),
        ),
      ),
    );
  }

  // --- HELPER: SELECTION CARD ---
  Widget _buildSelectionCard({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required double scale,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 8, right: 8),
            padding: EdgeInsets.symmetric(vertical: 20 * scale, horizontal: 20),
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(cornerRadius),
              border: Border.all(
                color: isSelected
                    ? AppColors.primaryGreen
                    : AppColors.inputFill,
                width: 1.5,
              ),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 14 * scale,
                fontWeight: FontWeight.w600,
                color: AppColors.colblack,
              ),
            ),
          ),
          if (isSelected)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryGreen,
                ),
                child: Icon(Icons.check, size: 16, color: AppColors.colwhite),
              ),
            ),
        ],
      ),
    );
  }

  // --- HELPER: MAIN BUTTON ---
  Widget _buildMainButton({
    required String label,
    required VoidCallback onTap,
    required double scale,
  }) {
    return SizedBox(
      width: double.infinity,
      height: componentHeight * scale,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(cornerRadius),
          ),
          elevation: 0,
        ),
        child: Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 18 * scale,
            fontWeight: FontWeight.w500,
            color: AppColors.colwhite,
          ),
        ),
      ),
    );
  }

  // --- HELPER: PREVIOUS BUTTON ---
  Widget _buildPreviousButton({
    required VoidCallback onTap,
    required double scale,
  }) {
    return SizedBox(
      width: double.infinity,
      height: componentHeight * scale,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.bgWhite,
          side: BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(cornerRadius),
          ),
          elevation: 0,
        ),
        child: Text(
          "Previous",
          style: GoogleFonts.montserrat(
            fontSize: 18 * scale,
            fontWeight: FontWeight.w500,
            color: AppColors.primaryGreen,
          ),
        ),
      ),
    );
  }
}

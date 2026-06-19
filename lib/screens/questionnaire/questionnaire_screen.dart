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

  final TextEditingController _amountController = TextEditingController();
  String? _selectedCategory;
  String? _selectedGoal;
  String? _inlineError;

  final double textPadding = 24.0;
  final double descPadding = 60.0;
  final double cornerRadius = 14.0;
  final double componentHeight = 64.0;

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
      FocusScope.of(context).unfocus();
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
  void dispose() {
    _amountController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    MediaQuery.platformBrightnessOf(context);

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentTheme, child) {
        final size = MediaQuery.of(context).size;
        final double height = size.height;
        final double scale = (height / 820.0).clamp(0.72, 1.0);

        // CHANGED: topMargin reduced drastically — was reserving large
        // static empty space above "Step 1" and below the button. Now
        // only a small breathing-room gap remains, scaled to screen size.
        final double topGap = 75.0 * scale;
        final double stepToBarGap = 20.0 * scale;
        final double barToQuestionGap = 24.0 * scale;
        final double bottomGap = 16.0 * scale;

        // FIX: Removed outer SingleChildScrollView + manual height calc
        // entirely. Column + Expanded now fills 100% of SafeArea height
        // with zero static reserved space, so content covers the whole
        // page and there is never a need to scroll.
        return Scaffold(
          backgroundColor: AppColors.bgWhite,
          resizeToAvoidBottomInset: true,
          body: SafeArea(
            child: Column(
              children: [
                SizedBox(height: topGap), // CHANGED: was topMargin (90*scale), now 24*scale

                Text(
                  _currentIndex == 0
                      ? "Step 1"
                      : _currentIndex == 1
                          ? "Step 2"
                          : "We're almost ready!",
                  style: GoogleFonts.montserrat(
                    fontSize: 20 * scale,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryGreen,
                  ),
                ),

                SizedBox(height: stepToBarGap),

                _buildProgressBar(),

                SizedBox(height: barToQuestionGap),

                // Expanded fills exactly the remaining height — every
                // question page starts its content at the SAME Y offset
                // because all three now use mainAxisAlignment.start below.
                Expanded(
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

                SizedBox(height: bottomGap), // CHANGED: was topMargin * 0.4, now a small fixed bottomGap
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSafePage(Widget content) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: content,
          ),
        );
      },
    );
  }

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

  Widget _buildQuestionOne(double scale) {
    final double subTextToInputGap = 25.0 * scale;
    final double quickToSubmitGap = 23.0 * scale;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        // CHANGED: .center → .start. This is the actual alignment fix —
        // Question 1's title now begins at the SAME top offset as
        // Question 2 and Question 3, instead of floating to the
        // vertical center of whatever space it has (which differed
        // from Q2/Q3 because Q1 has less content than the list questions).
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: textPadding * scale),
            child: Text(
              "What's your daily spending limit?",
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
        mainAxisAlignment: MainAxisAlignment.start, // unchanged — already .start, now matches Q1
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

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: _buildMainButton(
              label: isDone ? "Done" : "Next",
              scale: scale,
              onTap: () async {
                if (isDone) {
                  if (_validateCurrentPage()) {
                    final limitValue = _amountController.text.isNotEmpty
                        ? _amountController.text.replaceAll(
                            RegExp(r'[^0-9]'),
                            '',
                          )
                        : "5000";

                    await UserData.saveQuestionnaireData(
                      dailyLimitValue: limitValue,
                      category: _selectedCategory ?? "",
                      goal: _selectedGoal ?? "",
                    );

                    if (mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoadingScreen(),
                        ),
                      );
                    }
                  }
                } else {
                  _nextPage();
                }
              },
            ),
          ),

          SizedBox(height: 12 * scale),

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
      subtext: "We'll use this to show better insights.",
      items: _categories,
      selectedItem: _selectedCategory,
      onItemSelected: (val) => setState(() => _selectedCategory = val),
      isDone: false,
    );
  }

  Widget _buildQuestionThree(double scale) {
    return _buildListQuestion(
      scale: scale,
      title: "What's your goal with SpenTree?",
      subtext: "Your goal helps us guide your forest journey.",
      items: _goals,
      selectedItem: _selectedGoal,
      onItemSelected: (val) => setState(() => _selectedGoal = val),
      isDone: true,
    );
  }

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
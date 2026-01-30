import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_style.dart';
import '../../screens/auth/sign_up_screen.dart';
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

  // --- SPACING & SIZING CONSTANTS ---
  final double textPadding = 40.0;
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

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 1. TOP OFFSET
                // Moves the whole block "a little down with respect to now"
                const SizedBox(height: 60),

                // 2. PROGRESS BAR
                _buildProgressBar(),

                const SizedBox(height: 30),

                // 3. FORM CONTENT AREA
                SizedBox(
                  height: height * 0.75,
                  child: PageView(
                    controller: _controller,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (index) =>
                        setState(() => _currentIndex = index),
                    children: [
                      _buildPageContent(_buildQuestionOne()),
                      _buildPageContent(_buildQuestionTwo()),
                      _buildPageContent(_buildQuestionThree()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPageContent(Widget child) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: child,
      ),
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
  Widget _buildQuestionOne() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Title
        Padding(
          padding: EdgeInsets.symmetric(horizontal: textPadding),
          child: Text(
            "What’s your daily spending limit?",
            textAlign: TextAlign.center,
            style: AppTextStyles.title,
          ),
        ),

        const SizedBox(height: 12),

        // Description (Text Size Increased)
        Padding(
          padding: EdgeInsets.symmetric(horizontal: descPadding),
          child: Text(
            "This is the amount you don't want to cross in a day.",
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w600,
              fontSize: 16, // Increased slightly from 14
            ),
          ),
        ),

        const SizedBox(height: 40),

        // Input Field
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Container(
            height: componentHeight,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(cornerRadius),
            ),
            child: TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              textAlignVertical: TextAlignVertical.center,
              style: GoogleFonts.montserrat(
                fontSize: 16,
                color: AppColors.textMain,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                isCollapsed: true,
                hintText: "Enter the amount",
                hintStyle: GoogleFonts.montserrat(color: AppColors.textGrey),
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
                          color: AppColors.textMain,
                        ),
                      ),
                      const Icon(
                        Icons.keyboard_arrow_down,
                        color: AppColors.textMain,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // Reduced Gap Distance (Input <-> Or)
        const SizedBox(height: 16), // Reduced from 24
        // "Or" Divider
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            children: [
              const Expanded(child: Divider(color: AppColors.inactiveGrey)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text("Or", style: AppTextStyles.body),
              ),
              const Expanded(child: Divider(color: AppColors.inactiveGrey)),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Quick Select Buttons (Increased Height)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ["500", "1000", "5000"].map((amount) {
              return GestureDetector(
                onTap: () => _amountController.text = amount,
                child: Container(
                  // "Increase the quick select boxes height a little"
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 24,
                  ), // Increased vertical from 12 to 16
                  decoration: BoxDecoration(
                    color: AppColors.inputFill,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    "Rs. $amount",
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMain,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        // Increased Gap Distance (Boxes <-> Submit)
        const SizedBox(height: 56), // Increased from 40
        // Submit Button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: _buildMainButton(label: "Submit", onTap: () => _nextPage()),
        ),
      ],
    );
  }

  // --- PAGE 2: CATEGORY SELECTION ---
  Widget _buildQuestionTwo() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: textPadding),
          child: Text(
            "What are you usually spending on?",
            textAlign: TextAlign.center,
            style: AppTextStyles.title,
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: descPadding),
          child: Text(
            "We’ll use this to show better insights.",
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 16, // Consistent size increase
            ),
          ),
        ),

        const SizedBox(height: 40),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: _categories.map((category) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildSelectionCard(
                  label: category,
                  isSelected: _selectedCategory == category,
                  onTap: () => setState(() => _selectedCategory = category),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 24),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: _buildMainButton(label: "Next", onTap: () => _nextPage()),
        ),
      ],
    );
  }

  // --- PAGE 3: GOAL SELECTION ---
  Widget _buildQuestionThree() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: textPadding),
          child: Text(
            "What’s your goal with SpenTree?",
            textAlign: TextAlign.center,
            style: AppTextStyles.title,
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: descPadding),
          child: Text(
            "Your goal helps us guide your forest journey.",
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 16, // Consistent size increase
            ),
          ),
        ),

        const SizedBox(height: 40),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: _goals.map((goal) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildSelectionCard(
                  label: goal,
                  isSelected: _selectedGoal == goal,
                  onTap: () => setState(() => _selectedGoal = goal),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 24),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: _buildMainButton(
            label: "Done",
            onTap: () {
              // 1. Save the Limit (Remove 'Rs.' and clean it)
              if (_amountController.text.isNotEmpty) {
                UserData.dailyLimit = _amountController.text.replaceAll(
                  RegExp(r'[^0-9]'),
                  '',
                );
              }
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const SignUpScreen()),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- HELPER: SELECTION CARD ---
  Widget _buildSelectionCard({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 8, right: 8),
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(cornerRadius),
              border: Border.all(
                color: isSelected
                    ? AppColors.primaryGreen
                    : AppColors.borderGrey,
                width: 1.5,
              ),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textMain,
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
                child: const Icon(Icons.check, size: 16, color: Colors.white),
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
  }) {
    return SizedBox(
      width: double.infinity,
      height: componentHeight,
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
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  void _nextPage() {
    if (_currentIndex < 2) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    }
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../questionnaire/questionnaire_screen.dart'; // Adjust path if needed

class OnboardingColors {
  static const Color primaryGreen = Color(0xFF34C759);
  static const Color textMain = Color(0xFF2D2B2E);
  static const Color inactiveGrey = Color(0xFFE5E5EA);
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentIndex = 0;

  // --- 1. SPACING CONFIGURATION (UPDATED) ---

  // GAP: Distance between Image and Title Text
  final double imageTitleGap = 30.0;

  // GAP: Distance between Desc Text and Progress Bar
  // UPDATED: Increased massively to 100.0 to ensure the gap is visible
  final double descProgressGap = 100.0;

  // GAP: Distance between Progress Bar and Next Button
  final double buttonGap = 46.0;

  // PADDING: Text horizontal padding
  final double textPadding = 52.0;

  final List<Map<String, String>> _content = [
    {
      "tree": "assets/images/tree_1.png",
      "title": "Welcome to SpenTree",
      "desc":
          "Spentree turns your daily spending into a living tree. The better you manage your limit, the more your forest grows.",
    },
    {
      "tree": "assets/images/tree_2.png",
      "title": "Your spending affects your tree.",
      "desc":
          "Stay within your daily limit and your tree stays green. Overspend, and it starts to dry.",
    },
    {
      "tree": "assets/images/tree_3.png",
      "title": "Every good day grows your forest.",
      "desc":
          "Each day you control your spending, you plant a tree. Build a forest that shows your financial discipline.",
    },
  ];

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // --- 1. TOP MARGIN ---
            // Adjusted flex to 2 to balance the layout
            const Spacer(flex: 2),

            // --- 2. SWIPEABLE CONTENT AREA ---
            SizedBox(
              height: width * 1.35,
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (index) => setState(() => _currentIndex = index),
                itemCount: _content.length,
                itemBuilder: (context, index) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // A. IMAGE STACK
                      SizedBox(
                        height: width * 0.8,
                        width: width * 0.8,
                        child: Stack(
                          alignment: Alignment.bottomCenter,
                          clipBehavior: Clip.none,
                          children: [
                            // Static Background Room
                            Positioned(
                              bottom: 30,
                              child: Image.asset(
                                "assets/images/bg_room.png",
                                width: width * 0.75,
                                fit: BoxFit.contain,
                              ),
                            ),
                            // Dynamic Tree (UPDATED)
                            // Changed to 25 to move it visibly UP relative to BG
                            Positioned(
                              bottom: -5,
                              child: Image.asset(
                                _content[index]["tree"]!,
                                width: width * 0.65,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // B. GAP (Image <-> Title)
                      SizedBox(height: imageTitleGap),

                      // C. TEXT SECTION
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: textPadding),
                        child: Column(
                          children: [
                            Text(
                              _content[index]["title"]!,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.montserrat(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                color: OnboardingColors.textMain,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _content[index]["desc"]!,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.montserrat(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: OnboardingColors.textMain,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // --- 3. CONTROLS AREA ---
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // D. GAP (Desc Text <-> Progress Bar)
                // Using the new massive gap variable (100.0)
                SizedBox(height: descProgressGap),

                // PROGRESS BAR
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _content.length,
                    (index) => buildDot(index),
                  ),
                ),

                // E. GAP (Progress Bar <-> Button)
                SizedBox(height: buttonGap),

                // NEXT BUTTON
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 64,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentIndex == _content.length - 1) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const QuestionnaireScreen(),
                            ),
                          );
                        } else {
                          _controller.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeIn,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: OnboardingColors.primaryGreen,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        _currentIndex == _content.length - 1 ? "Done" : "Next",
                        style: GoogleFonts.montserrat(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // --- 4. BOTTOM MARGIN ---
            const Spacer(flex: 3),
          ],
        ),
      ),
    );
  }

  Widget buildDot(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 6,
      width: 40,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        color: _currentIndex == index
            ? OnboardingColors.primaryGreen
            : OnboardingColors.inactiveGrey,
      ),
    );
  }
}

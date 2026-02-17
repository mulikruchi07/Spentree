import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spentree/screens/questionnaire/questionnaire_screen.dart';
class OnboardingColors {
  static const Color primaryGreen = Color(0xFF34C759);
  static const Color textMain = Color(0xFF2D2B2E);
  static const Color inactiveGrey = Color(0xFFE5E5EA);
  static const Color textDesc = Color(0xFF818082);
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  late AnimationController _animController;
  late Animation<Offset> _slideUpRoomAnim;
  late Animation<Offset> _slideDownDescAnim;
  late Animation<double> _fadeTreeAnim;
  late Animation<double> _fadeControlsAnim;

  final List<Map<String, String>> _content = [
    {
      "tree": "assets/images/tree_1.png",
      "title": "Welcome to SpenTree",
      "desc": "Spentree turns your daily spending into a living tree. The better you manage your limit, the more your forest grows.",
    },
    {
      "tree": "assets/images/tree_2.png",
      "title": "Your spending affects your tree.",
      "desc": "Stay within your daily limit and your tree stays green. Overspend, and it starts to dry.",
    },
    {
      "tree": "assets/images/tree_3.png",
      "title": "Every good day grows your forest.",
      "desc": "Each day you control your spending, you plant a tree. Build a forest that shows your financial discipline.",
    },
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _slideUpRoomAnim = Tween<Offset>(
      begin: const Offset(0, 1.0), 
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutQuart),
    );

    _slideDownDescAnim = Tween<Offset>(
      begin: const Offset(0, -1.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );

    _fadeTreeAnim = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
    );
    _fadeControlsAnim = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. DYNAMIC CALCULATIONS
    final size = MediaQuery.of(context).size;
    final double width = size.width;
    final double height = size.height;

    // --- NEW LOGIC: DYNAMIC MARGINS ---
    // If screen is TALL (>800px), use 7% margin.
    // If screen is SMALL/STANDARD, use 3% margin (Original).
    final double marginPercentage = height > 800 ? 0.09 : 0.03;
    final double symmetricMargin = height * marginPercentage;

    // Gaps (Kept exactly as you liked them)
    final double gapImageToTitle = 20.0;
    final double gapDescToProgress = 20.0; 
    final double gapProgressToButton = 38.0;
    final double gapLogoToImage = height * 0.01; 

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SizedBox(
          width: double.infinity, 
          child: Column(
            children: [
              // -----------------------------------------------------------
              // 1. TOP MARGIN (Dynamic)
              // -----------------------------------------------------------
              SizedBox(height: symmetricMargin),
              
              // LOGO (Static & Scaled)
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: height * 0.06, 
                  maxWidth: 220,
                ),
                child: Hero(
                  tag: 'logo-image',
                  child: Image.asset(
                    "assets/logo-name.png",
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              // -----------------------------------------------------------
              // 2. SCROLLABLE MIDDLE SECTION (Room + Tree + Text)
              // -----------------------------------------------------------
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) => setState(() => _currentIndex = index),
                  itemCount: _content.length,
                  itemBuilder: (context, index) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center, 
                      children: [
                        SizedBox(height: gapLogoToImage),

                        // A. IMAGE STACK (Original Proportions)
                        SizedBox(
                          height: width * 0.8, 
                          width: width * 0.8, 
                          child: Stack(
                            alignment: Alignment.bottomCenter,
                            clipBehavior: Clip.none,
                            children: [
                              // Room (Slides Up)
                              Positioned(
                                bottom: 30, 
                                child: SlideTransition(
                                  position: _slideUpRoomAnim,
                                  child: Image.asset(
                                    "assets/images/bg_room.png",
                                    width: width * 0.75, 
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),

                              // Tree (Fades In)
                              Positioned(
                                bottom: 25, 
                                child: FadeTransition(
                                  opacity: _fadeTreeAnim,
                                  child: Image.asset(
                                    _content[index]["tree"]!,
                                    width: width * 0.55, 
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: gapImageToTitle),

                        // B. TEXT SECTION
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Column(
                            children: [
                              // Title
                              index == 0 ? Hero(
                                tag: 'welcome-text',
                                child: Material(
                                  type: MaterialType.transparency,
                                  child: Text(
                                    _content[index]["title"]!,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.montserrat(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w600,
                                      color: OnboardingColors.textMain,
                                    ),
                                  ),
                                ),
                              ) : Text(
                                _content[index]["title"]!,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.montserrat(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                  color: OnboardingColors.textMain,
                                ),
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Description
                              SlideTransition(
                                position: _slideDownDescAnim,
                                child: Text(
                                  _content[index]["desc"]!,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: OnboardingColors.textDesc,
                                    height: 1.5,
                                  ),
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

              // -----------------------------------------------------------
              // 3. BOTTOM CONTROLS
              // -----------------------------------------------------------
              FadeTransition(
                opacity: _fadeControlsAnim,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: gapDescToProgress),
                    
                    // Dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _content.length,
                        (index) => buildDot(index),
                      ),
                    ),
                    
                    SizedBox(height: gapProgressToButton),
                    
                    // Button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: SizedBox(
                        width: double.infinity,
                        height: 64, // Original Height
                        child: ElevatedButton(
                          onPressed: () {
  if (_currentIndex == _content.length - 1) {
    // 1. User is on the last slide ("Done") -> Navigate away
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        // Replace 'QuestionnaireScreen' with your actual next screen widget
        builder: (context) => const QuestionnaireScreen(), 
      ),
    );
  } else {
    // 2. User is on earlier slides ("Next") -> Slide to next page
    _pageController.nextPage(
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
              ),

              // -----------------------------------------------------------
              // 4. BOTTOM MARGIN (Dynamic - Matches Top)
              // -----------------------------------------------------------
              SizedBox(height: symmetricMargin),
            ],
          ),
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
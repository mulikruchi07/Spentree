import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

  final double imageTitleGap = 30.0;
  final double descProgressGap = 60.0;
  final double buttonGap = 46.0;
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
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // 1. BG ROOM: Slides UP (From Bottom to Top)
    // Offset(0, 1.0) means it starts shifted DOWN by its full height
    // Offset.zero means it ends at its natural position
    _slideUpRoomAnim =
        Tween<Offset>(begin: const Offset(0, 1.0), end: Offset.zero).animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutQuart),
        );

    // 2. DESC: Slides DOWN
    _slideDownDescAnim =
        Tween<Offset>(begin: const Offset(0, -1.0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animController,
            curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
          ),
        );

    // 3. Fades
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
    double width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),

            SizedBox(
              height: width * 1.35,
              child: PageView.builder(
                controller: _pageController,
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
                            // 1. BG ROOM (Slides UP)
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

                            // 2. HERO LOGO
                            // The flight starts at Splash size (220) and shrinks to this width (width * 0.45)
                            Positioned(
                              top: -60,
                              child: Hero(
                                tag: 'logo-image',
                                child: Image.asset(
                                  "assets/logo-name.png",
                                  width: width * 0.45,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),

                            // 3. TREE (Fades in)
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

                      SizedBox(height: imageTitleGap),

                      // B. TEXT SECTION
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: textPadding),
                        child: Column(
                          children: [
                            Hero(
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
                            ),
                            const SizedBox(height: 32),
                            SlideTransition(
                              position: _slideDownDescAnim,
                              child: FadeTransition(
                                opacity: _fadeTreeAnim,
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
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            FadeTransition(
              opacity: _fadeControlsAnim,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: descProgressGap),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _content.length,
                      (index) => buildDot(index),
                    ),
                  ),
                  SizedBox(height: buttonGap),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: SizedBox(
                      width: double.infinity,
                      height: 64,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_currentIndex < _content.length - 1) {
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
                          _currentIndex == _content.length - 1
                              ? "Done"
                              : "Next",
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

            const Spacer(flex: 2),
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

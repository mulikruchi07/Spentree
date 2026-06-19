import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spentree/screens/questionnaire/questionnaire_screen.dart';
import '../../core/app_style.dart';

class OnboardingColors {
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

    _slideUpRoomAnim =
        Tween<Offset>(begin: const Offset(0, 1.0), end: Offset.zero).animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutQuart),
        );

    _slideDownDescAnim =
        Tween<Offset>(begin: const Offset(0, -1.0), end: Offset.zero).animate(
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
    MediaQuery.platformBrightnessOf(context);

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentTheme, child) {
        // ── FIX 1: Determine effective brightness for dark-mode image swap ──
        // currentTheme can be ThemeMode.system, in which case we fall back
        // to the platform brightness. This correctly resolves the ACTUAL
        // rendered theme, not just the user's explicit selection.
        final Brightness effectiveBrightness = currentTheme == ThemeMode.dark
            ? Brightness.dark
            : currentTheme == ThemeMode.light
                ? Brightness.light
                : MediaQuery.platformBrightnessOf(context);
        final bool isDark = effectiveBrightness == Brightness.dark;

        // ── FIX 1: Pick the correct room background asset ──
        final String roomImagePath =
            isDark ? "assets/images/dbg_room.png" : "assets/images/bg_room.png";

        final size = MediaQuery.of(context).size;
        final double width = size.width;
        final double height = size.height;

        // ── FIX 2: Use LayoutBuilder-driven proportional gaps instead of
        // raw fixed pixels so short screens compress gracefully rather
        // than overflow. Values still resolve to the SAME numbers as
        // before on a standard ~812-896px tall screen, preserving the
        // exact visual design on typical devices, but now scale down on
        // very short ones (320x568, 360x640).
        final double heightScale = (height / 812.0).clamp(0.62, 1.0);

        final double marginPercentage = height > 800 ? 0.09 : 0.03;
        final double symmetricMargin = height * marginPercentage;

        final double gapImageToTitle = 20.0 * heightScale;
        final double gapDescToProgress = 20.0 * heightScale;
        final double gapProgressToButton = 38.0 * heightScale;
        final double gapLogoToImage = height * 0.01;

        return Scaffold(
          backgroundColor: AppColors.bgWhite,
          body: SafeArea(
            child: SizedBox(
              width: double.infinity,
              height: double.infinity, // FIX 2: anchors the Column to fill the full screen
              child: Column(
                children: [
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
                        AppImages.logoName,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  // ── FIX 2: middle section now uses Expanded with a
                  // LayoutBuilder so the PageView content can size itself
                  // to whatever space remains, instead of assuming a fixed
                  // image size of width * 0.8 regardless of available height.
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // Cap the image block to whichever is smaller:
                        // 80% of width (original design) OR a height-derived
                        // cap that guarantees text below it still fits.
                        // This is the actual overflow fix: on short screens,
                        // the image shrinks instead of pushing text off-screen.
                        final double maxImageByWidth = width * 0.8;
                        final double maxImageByHeight =
                            constraints.maxHeight * 0.52;
                        final double imageBlockSize =
                            maxImageByWidth < maxImageByHeight
                                ? maxImageByWidth
                                : maxImageByHeight;

                        return PageView.builder(
                          controller: _pageController,
                          onPageChanged: (index) =>
                              setState(() => _currentIndex = index),
                          itemCount: _content.length,
                          itemBuilder: (context, index) {
                            return SingleChildScrollView(
                              // FIX 2: This inner scroll is a safety net only —
                              // on any screen where content still doesn't fit
                              // (e.g. extreme font scaling), it scrolls instead
                              // of throwing a RenderFlex overflow error. On all
                              // normal screens, content fits exactly and no
                              // scrolling is visually needed because the
                              // ConstrainedBox below matches available height.
                              physics: const ClampingScrollPhysics(),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: constraints.maxHeight,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(height: gapLogoToImage),

                                    // A. IMAGE STACK (now responsively sized)
                                    SizedBox(
                                      height: imageBlockSize,
                                      width: imageBlockSize,
                                      child: Stack(
                                        alignment: Alignment.bottomCenter,
                                        clipBehavior: Clip.none,
                                        children: [
                                          // Room (Slides Up) — FIX 1: dynamic asset
                                          Positioned(
                                            bottom: 30 * heightScale,
                                            child: SlideTransition(
                                              position: _slideUpRoomAnim,
                                              child: Image.asset(
                                                roomImagePath,
                                                width: imageBlockSize * 0.94,
                                                fit: BoxFit.contain,
                                              ),
                                            ),
                                          ),

                                          // Tree (Fades In) — unchanged proportions
                                          Positioned(
                                            bottom: 25 * heightScale,
                                            child: FadeTransition(
                                              opacity: _fadeTreeAnim,
                                              child: Image.asset(
                                                _content[index]["tree"]!,
                                                width: imageBlockSize * 0.69,
                                                fit: BoxFit.contain,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    SizedBox(height: gapImageToTitle),

                                    // B. TEXT SECTION — unchanged
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 40,
                                      ),
                                      child: Column(
                                        children: [
                                          index == 0
                                              ? Hero(
                                                  tag: 'welcome-text',
                                                  child: Material(
                                                    type: MaterialType
                                                        .transparency,
                                                    child: Text(
                                                      _content[index]["title"]!,
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: GoogleFonts
                                                          .montserrat(
                                                        fontSize: 24,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color:
                                                            AppColors.colblack,
                                                      ),
                                                    ),
                                                  ),
                                                )
                                              : Text(
                                                  _content[index]["title"]!,
                                                  textAlign: TextAlign.center,
                                                  style:
                                                      GoogleFonts.montserrat(
                                                    fontSize: 24,
                                                    fontWeight:
                                                        FontWeight.w600,
                                                    color: AppColors.colblack,
                                                  ),
                                                ),

                                          const SizedBox(height: 16),

                                          SlideTransition(
                                            position: _slideDownDescAnim,
                                            child: Text(
                                              _content[index]["desc"]!,
                                              textAlign: TextAlign.center,
                                              style: GoogleFonts.montserrat(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w400,
                                                color:
                                                    OnboardingColors.textDesc,
                                                height: 1.5,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),

                  // BOTTOM CONTROLS — unchanged structure, gaps now scaled
                  FadeTransition(
                    opacity: _fadeControlsAnim,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(height: gapDescToProgress),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            _content.length,
                            (index) => buildDot(index),
                          ),
                        ),

                        SizedBox(height: gapProgressToButton),

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
                                      builder: (context) =>
                                          const QuestionnaireScreen(),
                                    ),
                                  );
                                } else {
                                  _pageController.nextPage(
                                    duration:
                                        const Duration(milliseconds: 300),
                                    curve: Curves.easeIn,
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryGreen,
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
                                  color: AppColors.colwhite,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: symmetricMargin),
                ],
              ),
            ),
          ),
        );
      },
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
            ? AppColors.primaryGreen
            : OnboardingColors.inactiveGrey,
      ),
    );
  }
}
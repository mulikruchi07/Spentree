import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spentree/screens/forest/forest_screen.dart';
import '../core/biometric_service.dart';
import 'analytics/analytics_screen.dart';
import 'dashboard/dashboard_screen.dart';
import 'profile/profile_screen.dart';
import '../../core/app_style.dart';
import 'achievements/achievements_screen.dart';

class MainWrapper extends StatefulWidget {
  final int initialIndex; // Add this variable

  // Add it to the constructor with a default value of 0 (Dashboard)
  const MainWrapper({super.key, this.initialIndex = 0});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  bool _isAuthenticating = false;
  bool _showPrivacyBlur = false;
  bool _lockCache = false;

  // --- NEW: PageController for swipe navigation ---
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    WidgetsBinding.instance.addObserver(this);
    _pageController = PageController(initialPage: _selectedIndex);
    _syncLockState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _syncLockState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _lockCache = prefs.getBool('isFaceIdEnabled') ?? false;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      if (_lockCache) {
        setState(() => _showPrivacyBlur = true);
      }
    }

    if (state == AppLifecycleState.resumed) {
      _syncLockState();
      if (!_isAuthenticating && _lockCache) {
        _enforceLockOnResume();
      }
    }
  }

  Future<void> _enforceLockOnResume() async {
    setState(() {
      _isAuthenticating = true;
      _showPrivacyBlur = true;
    });

    bool authenticated = await BiometricService.authenticateUser();

    if (authenticated) {
      await Future.delayed(const Duration(milliseconds: 150));
      setState(() {
        _isAuthenticating = false;
        _showPrivacyBlur = false;
      });
    } else {
      setState(() => _isAuthenticating = false);
    }
  }

  final List<Widget> _pages = [
    const DashboardScreen(),
    const AnalyticsScreen(),
    const ForestScreen(),
    const AchievementsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // --- FIX: Wrapping the entire wrapper in the theme listener ensures
    // ---      that cached pages update instantly when the theme changes!
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, child) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (_selectedIndex != 0) {
              _pageController.animateToPage(
                0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            } else {
              SystemNavigator.pop();
            }
          },
          child: Stack(
            children: [
              Scaffold(
                backgroundColor: AppColors.bgWhite,
                extendBody: true,
                body: Stack(
                  children: [
                    // -------- NAV BACKGROUND IMAGE --------
                    Positioned.fill(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Image.asset(
                          'assets/icons/navbg.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                    // -------- PAGEVIEW --------
                    PageView(
                      controller: _pageController,
                      physics: const BouncingScrollPhysics(),
                      onPageChanged: (index) {
                        setState(() => _selectedIndex = index);
                      },
                      children: _pages,
                    ),
                    _buildNavBackgroundEffect(),

                    // -------- FLOATING NAVBAR --------
                    _buildFloatingNavbar(),
                  ],
                ),
              ),

              // Privacy Overlay
              if (_showPrivacyBlur)
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 35.0, sigmaY: 35.0),
                    child: Container(
                      color: AppColors.bgWhite.withOpacity(0.85),
                      child: const Center(
                        child: Icon(
                          Icons.lock_outline,
                          size: 60,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFloatingNavbar() {
    final media = MediaQuery.of(context);
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final width = media.size.width;
    final horizontalPadding = width * 0.06;

    return Positioned(
      left: horizontalPadding,
      right: horizontalPadding,
      bottom: bottomInset + 16,
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(60),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 16,
              spreadRadius: 0,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(60),
          child: Stack(
            children: [
              // PURE GLASS (ONLY BLUR + COLOR)
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(color: AppColors.navbar.withOpacity(0.20)),
              ),

              // EDGE LIGHT
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(painter: _FigmaEdgeAccuratePainter()),
                ),
              ),

              // NAV ITEMS
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(0, PhosphorIcons.house as PhosphorIconData Function([PhosphorIconsStyle])),
                  _buildNavItem(1, PhosphorIcons.chartPieSlice as PhosphorIconData Function([PhosphorIconsStyle])),
                  _buildNavItem(2, PhosphorIcons.treeEvergreen as PhosphorIconData Function([PhosphorIconsStyle])),
                  _buildNavItem(3, PhosphorIcons.trophy as PhosphorIconData Function([PhosphorIconsStyle])),
                  _buildNavItem(4, PhosphorIcons.user as PhosphorIconData Function([PhosphorIconsStyle])),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    PhosphorIconData Function([PhosphorIconsStyle]) iconBuilder,
  ) {
    bool isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () {
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 48,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              iconBuilder(
                isSelected
                    ? PhosphorIconsStyle.fill
                    : PhosphorIconsStyle.regular,
              ),
              size: 28,
              color: isSelected
                  ? AppColors.primaryGreen
                  // : AppColors.colblack.withOpacity(0.2),
                  : const Color(0xFF666666),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavBackgroundEffect() {
    final media = MediaQuery.of(context);
    final bottomInset = media.padding.bottom;

    const navbarHeight = 64.0;
    const navbarBottomSpacing = 16.0;

    final totalHeight = navbarHeight + navbarBottomSpacing + bottomInset;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      height: totalHeight,
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                AppColors.bgWhite.withOpacity(0.90), // 90%
                AppColors.bgWhite.withOpacity(0.45), // 45%
                AppColors.bgWhite.withOpacity(0.0), // 0%
                Colors.transparent, // transparent top
              ],
              stops: const [0.0, 0.25, 0.50, 1.0],
            ),
          ),
        ),
      ),
    );
  }
}

class _FigmaEdgeAccuratePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final outer = RRect.fromRectAndRadius(rect, const Radius.circular(60));

    final inner = RRect.fromRectAndRadius(
      rect.deflate(0.9),
      const Radius.circular(59.1),
    );

    final rimPath = Path()
      ..addRRect(outer)
      ..addRRect(inner)
      ..fillType = PathFillType.evenOdd;

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height / 2));

    final topEdgeLight = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.topRight,
        colors: [
          Colors.white.withOpacity(0.44),
          Colors.white.withOpacity(0.41),
          Colors.white.withOpacity(0.28),
          Colors.white.withOpacity(0.20),
          Colors.transparent,
        ],
        stops: const [0.0, 0.35, 0.65, 0.88, 0.99],
      ).createShader(rect);

    canvas.drawPath(rimPath, topEdgeLight);
    canvas.restore();

    canvas.save();
    canvas.clipRect(
      Rect.fromLTWH(0, size.height / 2, size.width, size.height / 2),
    );

    final bottomEdgeLight = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomRight,
        end: Alignment.bottomLeft,
        colors: [
          Colors.white.withOpacity(0.38),
          Colors.white.withOpacity(0.35),
          Colors.white.withOpacity(0.22),
          Colors.white.withOpacity(0.14),
          Colors.transparent,
        ],
        stops: const [0.0, 0.30, 0.55, 0.88, 0.95],
      ).createShader(rect);

    canvas.drawPath(rimPath, bottomEdgeLight);
    canvas.restore();
    final bottomCompression = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.95, 0.95),
        radius: 1.0,
        colors: [Colors.black.withOpacity(0.18), Colors.transparent],
      ).createShader(rect);

    canvas.drawPath(rimPath, bottomCompression);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

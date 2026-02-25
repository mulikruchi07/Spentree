// import 'dart:ui';
// import 'package:flutter/material.dart';
// import 'package:phosphor_flutter/phosphor_flutter.dart';
// import 'package:flutter/services.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:spentree/screens/forest/forest_screen.dart';
// import '../core/biometric_service.dart';
// import 'analytics/analytics_screen.dart';
// import 'dashboard/dashboard_screen.dart';
// import 'profile/profile_screen.dart';
// import '../../core/app_style.dart';

// class MainWrapper extends StatefulWidget {
//   const MainWrapper({super.key});

//   @override
//   State<MainWrapper> createState() => _MainWrapperState();
// }

// class _MainWrapperState extends State<MainWrapper> with WidgetsBindingObserver {
//   int _selectedIndex = 0;
//   bool _isAuthenticating = false;
//   bool _showPrivacyBlur = false;
//   bool _lockCache = false;

//   // --- NEW: PageController for swipe navigation ---
//   late PageController _pageController;

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//     _pageController = PageController(initialPage: _selectedIndex);
//     _syncLockState();
//   }

//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     _pageController.dispose();
//     super.dispose();
//   }

//   Future<void> _syncLockState() async {
//     final prefs = await SharedPreferences.getInstance();
//     setState(() {
//       _lockCache = prefs.getBool('isFaceIdEnabled') ?? false;
//     });
//   }

//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     if (state == AppLifecycleState.inactive ||
//         state == AppLifecycleState.paused) {
//       if (_lockCache) {
//         setState(() => _showPrivacyBlur = true);
//       }
//     }

//     if (state == AppLifecycleState.resumed) {
//       _syncLockState();
//       if (!_isAuthenticating && _lockCache) {
//         _enforceLockOnResume();
//       }
//     }
//   }

//   Future<void> _enforceLockOnResume() async {
//     setState(() {
//       _isAuthenticating = true;
//       _showPrivacyBlur = true;
//     });

//     bool authenticated = await BiometricService.authenticateUser();

//     if (authenticated) {
//       await Future.delayed(const Duration(milliseconds: 150));
//       setState(() {
//         _isAuthenticating = false;
//         _showPrivacyBlur = false;
//       });
//     } else {
//       setState(() => _isAuthenticating = false);
//     }
//   }

//   final List<Widget> _pages = [
//     const DashboardScreen(),
//     const AnalyticsScreen(),
//     const ForestScreen(),
//     const ProfileScreen(),
//   ];

//   @override
//   Widget build(BuildContext context) {
//     // --- FIX: Wrapping the entire wrapper in the theme listener ensures
//     // ---      that cached pages update instantly when the theme changes!
//     return ValueListenableBuilder<ThemeMode>(
//       valueListenable: themeNotifier,
//       builder: (context, currentMode, child) {
//         return PopScope(
//           canPop: false,
//           onPopInvokedWithResult: (didPop, result) {
//             if (_selectedIndex != 0) {
//               _pageController.animateToPage(
//                 0,
//                 duration: const Duration(milliseconds: 300),
//                 curve: Curves.easeInOut,
//               );
//             } else {
//               SystemNavigator.pop();
//             }
//           },
//           child: Stack(
//             children: [
//               Scaffold(
//                 backgroundColor: AppColors.bgWhite,
//                 extendBody:
//                     true, // Allows body to scroll behind the transparent navbar
//                 // --- NEW: PageView for swipeable screens ---
//                 body: PageView(
//                   controller: _pageController,
//                   physics:
//                       const BouncingScrollPhysics(), // Smooth swipe physics
//                   onPageChanged: (index) {
//                     setState(() => _selectedIndex = index);
//                   },
//                   children: _pages,
//                 ),
//                 bottomNavigationBar: _buildBottomNavbar(),
//               ),

//               // Privacy Overlay
//               if (_showPrivacyBlur)
//                 Positioned.fill(
//                   child: BackdropFilter(
//                     filter: ImageFilter.blur(sigmaX: 35.0, sigmaY: 35.0),
//                     child: Container(
//                       color: AppColors.bgWhite.withOpacity(0.85),
//                       child: const Center(
//                         child: Icon(
//                           Icons.lock_outline,
//                           size: 60,
//                           color: AppColors.primaryGreen,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildBottomNavbar() {
//     return Container(
//       // --- NEW: Static background image behind the blur ---
//       decoration: const BoxDecoration(
//         image: DecorationImage(
//           image: AssetImage(
//             'assets/navbg.png',
//           ), // Path to your gradient/bg image
//           fit: BoxFit.cover,
//         ),
//       ),
//       child: ClipRect(
//         child: BackdropFilter(
//           // --- NEW: Blur effect applied over the image ---
//           filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
//           child: Container(
//             // Slight color overlay to ensure icons are readable in both themes
//             color: AppColors.bgWhite.withOpacity(0.3),
//             child: SafeArea(
//               child: Container(
//                 height: 65,
//                 decoration: BoxDecoration(
//                   border: Border(
//                     top: BorderSide(
//                       color: AppColors.colblack.withOpacity(0.1),
//                       width: 0.5,
//                     ),
//                   ),
//                 ),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceAround,
//                   children: [
//                     // --- NEW: Phosphor Icons mapping ---
//                     _buildNavItem(0, PhosphorIcons.house),
//                     _buildNavItem(1, PhosphorIcons.chartPieSlice),
//                     _buildNavItem(2, PhosphorIcons.treeEvergreen),
//                     _buildNavItem(3, PhosphorIcons.user),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   // Updated builder takes the PhosphorIcon function directly
//   Widget _buildNavItem(
//     int index,
//     PhosphorIconData Function([PhosphorIconsStyle]) iconBuilder,
//   ) {
//     bool isSelected = _selectedIndex == index;

//     return GestureDetector(
//       onTap: () {
//         // Sync tapping with the PageView swipe animation
//         _pageController.animateToPage(
//           index,
//           duration: const Duration(milliseconds: 300),
//           curve: Curves.easeOutCubic,
//         );
//       },
//       behavior: HitTestBehavior.opaque,
//       child: SizedBox(
//         width: MediaQuery.of(context).size.width / 4,
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               // If selected, use 'fill' weight. If not, use standard 'regular' weight
//               iconBuilder(
//                 isSelected
//                     ? PhosphorIconsStyle.fill
//                     : PhosphorIconsStyle.regular,
//               ),
//               size: 28,
//               color: isSelected ? AppColors.primaryGreen : AppColors.colblack,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spentree/screens/forest/forest_screen.dart';
import '../core/biometric_service.dart';
import 'analytics/analytics_screen.dart';
import 'dashboard/dashboard_screen.dart';
import 'profile/profile_screen.dart';
import '../../core/app_style.dart';
import '../screens/profile/account_screen.dart';
import 'forest/spentwrap_intro_screen.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  bool _isAuthenticating = false;
  bool _showPrivacyBlur = false;
  bool _lockCache = false;


  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pageController = PageController(initialPage: _selectedIndex);
    _syncLockState();
    _preloadAccountData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _preloadAccountData() async {
    final prefs = await SharedPreferences.getInstance();

    // Sync settings to AccountScreen's global cache
    AccountScreen.cachedFaceId = prefs.getBool('isFaceIdEnabled') ?? false;
    AccountScreen.cachedTheme = prefs.getString('app_theme') ?? "System";
    AccountScreen.cachedSoundEffects =
        prefs.getBool('sound_effects') ?? true; // Default to true

    final String? savedImageBase64 = prefs.getString('profile_image');
    if (savedImageBase64 != null) {
      AccountScreen.cachedProfileBytes = base64Decode(savedImageBase64);
    }

    AccountScreen.isDataPreloaded = true;
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

  @override
  Widget build(BuildContext context) {
    // FIX 1: The pages are defined INSIDE the build method and WITHOUT 'const'.
    // This forces all tabs to instantly rebuild and fetch the new theme colors
    // when returning from the Account settings page.
    final List<Widget> pages = [
      DashboardScreen(),
      AnalyticsScreen(),
      SpentWrapScreen(),
      // ForestScreen(isActive: _selectedIndex == 2),
      ProfileScreen(),
    ];

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, child) {
        // FIX 2: Make System Navigation Bar (Bottom) completely opaque
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            systemNavigationBarColor: AppColors.bgWhite, // Opaque solid color
            systemNavigationBarIconBrightness: isDarkMode
                ? Brightness.light
                : Brightness.dark,
            statusBarColor: Colors.transparent, // Let our gradient show through
            statusBarIconBrightness: Brightness
                .light, // Keep status bar icons visible over dark shadow
          ),
          child: PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) {
              if (_selectedIndex != 0) {
                _pageController.animateToPage(
                  0,
                  duration: const Duration(milliseconds: 250),
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

                  // FIX 3: Buttery smooth swipe physics
                  body: PageView(
                    controller: _pageController,
                    physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      onPageChanged: (index) {
                        setState(() => _selectedIndex = index);
                      },
                      children: pages,
                    ),
                    // REMOVE bottomNavigationBar from Scaffold here!
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

                // FIX 4: Top Status Bar Shadow Gradient
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height:
                      MediaQuery.of(context).padding.top +
                      30, // Covers status bar + slight fade
                  child: IgnorePointer(
                    // Don't block taps!
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.45), // Dark top edge
                            Colors.transparent, // Fades out
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Animated Navbar that slides off-screen on index 2 ---
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOutCubic,
                    bottom: _selectedIndex == 2 ? -100 : 0, // Slides out for SpentWrap
                    left: 0,
                    right: 0,
                    child: _buildBottomNavbar(),
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
          ),
        );
      },
    );
  }

  Widget _buildBottomNavbar() {
    return Container(
      // FIX 5: Raw Image background, no extra blur
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(AppImages.navbg),
          fit: BoxFit.cover,
        ),
      ),
      child: SafeArea(
        bottom:
            true, // Prevents navbar from rendering underneath the opaque system keys
        child: Container(
          height: 65,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, PhosphorIcons.house),
              _buildNavItem(1, PhosphorIcons.chartPieSlice),
              _buildNavItem(2, PhosphorIcons.treeEvergreen),
              _buildNavItem(3, PhosphorIcons.user),
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
        // FIX 6: Fast, sensitive, buttery smooth tap animation
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOutQuart,
        );
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: MediaQuery.of(context).size.width / 4,
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
              color: isSelected ? AppColors.primaryGreen : AppColors.colblack,
            ),
          ],
        ),
      ),
    );
  }
}

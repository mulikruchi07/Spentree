import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dashboard/dashboard_screen.dart';
import 'profile/profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/biometric_service.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  bool _isAuthenticating = false; // Prevents the infinite popup loop
  bool _showPrivacyBlur = false; // Controls the immediate blur overlay

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Immediate Lock: Blur the screen as soon as the app starts to move to background
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _enablePrivacyBlur();
    }

    // Trigger authentication when the app comes back to focus
    if (state == AppLifecycleState.resumed && !_isAuthenticating) {
      _enforceLockOnResume();
    }
  }

  Future<void> _enablePrivacyBlur() async {
    final prefs = await SharedPreferences.getInstance();
    bool isLockEnabled = prefs.getBool('isFaceIdEnabled') ?? false;
    if (isLockEnabled) {
      setState(() => _showPrivacyBlur = true);
    }
  }

  Future<void> _enforceLockOnResume() async {
    final prefs = await SharedPreferences.getInstance();
    bool isLockEnabled = prefs.getBool('isFaceIdEnabled') ?? false;

    if (isLockEnabled) {
      if (isLockEnabled) {
        setState(() {
          _isAuthenticating = true;
          _showPrivacyBlur = true; // Ensure UI is hidden while popup shows
        });

        // Local auth allows Fingerprint/Face/PIN based on device settings
        bool authenticated = await BiometricService.authenticateUser();

        if (authenticated) {
          await Future.delayed(const Duration(milliseconds: 200));
          setState(() {
            _isAuthenticating = false;
            _showPrivacyBlur = false; // Reveal UI only on success
          });
        } else {
          // Keep gate open for retry but keep UI blurred
          setState(() => _isAuthenticating = false);
        }
      } else {
        setState(() => _showPrivacyBlur = false);
      }
    }
  }

  final List<Widget> _pages = [
    const DashboardScreen(),
    const Center(child: Text("Analytics")),
    const Center(child: Text("Forest")),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Intercept back button
      onPopInvokedWithResult: (didPop, result) {
        if (_selectedIndex != 0) {
          // If on Profile/Forest, go back to Dashboard first
          setState(() => _selectedIndex = 0);
        } else {
          // If on Dashboard, close the app properly
          SystemNavigator.pop();
        }
      },
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: Colors.white,
            extendBody: true,
            body: IndexedStack(index: _selectedIndex, children: _pages),
            bottomNavigationBar: _buildBottomNavbar(),
          ),

          // Privacy Overlay: Heavy blur that hides content when locked/standby
          if (_showPrivacyBlur)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30.0, sigmaY: 30.0),
                child: Container(
                  color: Colors.white.withValues(alpha: 0.8),
                  child: const Center(
                    child: Icon(
                      Icons.lock_outline,
                      size: 50,
                      color: Color(0xFF34C759),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomNavbar() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
        child: Container(
          color: Colors.white.withValues(alpha: 0.02),
          child: SafeArea(
            child: Container(
              height: 65,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Colors.black.withValues(alpha: 0.05),
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(0, 'home.png', 'home_filled.png'),
                  _buildNavItem(1, 'analytics.png', 'analytics_filled.png'),
                  _buildNavItem(2, 'forest.png', 'forest_filled.png'),
                  _buildNavItem(3, 'profile.png', 'profile_filled.png'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, String outlineIcon, String filledIcon) {
    bool isSelected = _selectedIndex == index;
    String iconPath = "assets/icons/${isSelected ? filledIcon : outlineIcon}";

    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: MediaQuery.of(context).size.width / 4,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              iconPath,
              width: 26,
              height: 26,
              // ACTIVE: Green (34C759) | INACTIVE: Black
              color: isSelected ? const Color(0xFF34C759) : Colors.black,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.image_not_supported,
                size: 26,
                color: isSelected ? const Color(0xFF34C759) : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

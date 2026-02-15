import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spentree/screens/forest/forest_screen.dart';
import '../core/biometric_service.dart';
import 'analytics/analytics_screen.dart';
import 'dashboard/dashboard_screen.dart';
import 'profile/profile_screen.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  bool _isAuthenticating = false;
  bool _showPrivacyBlur = false;
  bool _lockCache = false; // Synchronous cache to prevent UI leaks

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _syncLockState(); // Initial cache load
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Updates the local boolean instantly for zero-latency checks
  Future<void> _syncLockState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _lockCache = prefs.getBool('isFaceIdEnabled') ?? false;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 1. IMMEDIATE BLUR: Triggers on 'inactive' (swiping up or biometric popup)
    // This happens BEFORE SharedPreferences could even be read.
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      if (_lockCache) {
        setState(() => _showPrivacyBlur = true);
      }
    }

    // 2. ENFORCE LOCK: Triggered when user returns to app
    if (state == AppLifecycleState.resumed) {
      _syncLockState(); // Refresh cache for next time
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
      // Small delay to let the OS-level dialog clear the screen
      await Future.delayed(const Duration(milliseconds: 150));
      setState(() {
        _isAuthenticating = false;
        _showPrivacyBlur = false;
      });
    } else {
      setState(() => _isAuthenticating = false);
      // Privacy blur remains true; data is still hidden on failure
    }
  }

  final List<Widget> _pages = [
    const DashboardScreen(),
    const AnalyticsScreen(),
    const ForestScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (_selectedIndex != 0) {
          setState(() => _selectedIndex = 0);
        } else {
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

          // Privacy Overlay: High sigma blur
          if (_showPrivacyBlur)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 35.0, sigmaY: 35.0),
                child: Container(
                  color: Colors.white.withOpacity(0.85),
                  child: const Center(
                    child: Icon(
                      Icons.lock_outline,
                      size: 60,
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

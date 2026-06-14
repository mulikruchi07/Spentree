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
  final int initialIndex;
  final bool openAddExpenseForm;

  const MainWrapper({
    super.key,
    this.initialIndex = 0,
    this.openAddExpenseForm = false,
  });

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> with WidgetsBindingObserver {
  late int _selectedIndex;
  bool _isAuthenticating = false;
  bool _showPrivacyBlur = false;
  bool _lockCache = false;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    WidgetsBinding.instance.addObserver(this);
    _pageController = PageController(initialPage: _selectedIndex);
    _syncLockState();
    // REMOVED SystemChrome logic from here
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateSystemUI();
  }

  void _updateSystemUI() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color navColor = isDark ? const Color(0xFF252525) : Colors.white;

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        systemNavigationBarColor: navColor,
        systemNavigationBarDividerColor: navColor,
        systemNavigationBarIconBrightness: isDark
            ? Brightness.light
            : Brightness.dark,
        systemNavigationBarContrastEnforced: false,
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
    setState(() => _lockCache = prefs.getBool('isFaceIdEnabled') ?? false);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      if (_lockCache) setState(() => _showPrivacyBlur = true);
    }

    if (state == AppLifecycleState.resumed) {
      _syncLockState();
      if (!_isAuthenticating && _lockCache) _enforceLockOnResume();
      _handleWidgetActions();
    }
  }

  Future<void> _handleWidgetActions() async {
    const platform = MethodChannel('spentree_widget_channel');
    try {
      final action = await platform.invokeMethod('getWidgetAction');
      if (action == "OPEN_ADD_EXPENSE") {
        setState(() => _selectedIndex = 1);
        _pageController.jumpToPage(1);
        AnalyticsScreen.triggerOpenForm.value = true;
      } else if (action == "OPEN_DASHBOARD") {
        setState(() => _selectedIndex = 0);
        _pageController.jumpToPage(0);
      }
    } catch (e) {
      debugPrint("Widget intent fetch failed: $e");
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

  List<Widget> get _pages => [
    const DashboardScreen(),
    AnalyticsScreen(startWithAddExpense: widget.openAddExpenseForm),
    const ForestScreen(),
    const AchievementsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, child) {
        final bool isDark = Theme.of(context).brightness == Brightness.dark;
        final Color navColor = isDark ? const Color(0xFF252525) : Colors.white;

        SystemChrome.setSystemUIOverlayStyle(
          SystemUiOverlayStyle(
            systemNavigationBarColor: navColor,
            systemNavigationBarDividerColor: navColor, // Prevents the thin line
            systemNavigationBarIconBrightness: isDark
                ? Brightness.light
                : Brightness.dark,
            systemNavigationBarContrastEnforced: false,
          ),
        );

        return Scaffold(
          backgroundColor: AppColors.bgWhite,
          body: Stack(
            children: [
              PageView(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (index) =>
                    setState(() => _selectedIndex = index),
                children: _pages,
              ),
              if (_showPrivacyBlur) _buildPrivacyOverlay(),
            ],
          ),
          bottomNavigationBar: _buildStandardNavbar(),
        );
      },
    );
  }

  Widget _buildStandardNavbar() {
    // Using your defined renavbar color
    final Color bgColor = AppColors.renavbar;

    return Container(
      height:
          80 +
          MediaQuery.of(context).padding.bottom, // Account for system nav keys
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        // This mimics your Figma linear shadow effect
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
        // Adds a subtle border to separate white navbar from white background in light mode
        border: Border(
          top: BorderSide(
            color: Theme.of(context).brightness == Brightness.light
                ? Colors.black.withOpacity(0.05)
                : Colors.white.withOpacity(0.05),
            width: 1,
          ),
        ),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(0, PhosphorIcons.house, PhosphorIcons.houseFill),
          _buildNavItem(
            1,
            PhosphorIcons.chartPieSlice,
            PhosphorIcons.chartPieSliceFill,
          ),
          _buildNavItem(
            2,
            PhosphorIcons.treeEvergreen,
            PhosphorIcons.treeEvergreenFill,
          ),
          _buildNavItem(3, PhosphorIcons.trophy, PhosphorIcons.trophyFill),
          _buildNavItem(4, PhosphorIcons.user, PhosphorIcons.userFill),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData inactiveIcon, IconData activeIcon) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedIndex = index);
        _pageController.jumpToPage(index);
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 48,
        child: Icon(
          isSelected ? activeIcon : inactiveIcon,
          size: 28,
          color: isSelected ? AppColors.primaryGreen : const Color(0xFF666666),
        ),
      ),
    );
  }

  Widget _buildPrivacyOverlay() {
    return Positioned.fill(
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
    );
  }
}

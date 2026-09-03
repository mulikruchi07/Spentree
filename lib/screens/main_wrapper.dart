import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:spentree/screens/forest/forest_screen.dart';
import '../core/app_style.dart';
import 'analytics/analytics_screen.dart';
import 'dashboard/dashboard_screen.dart';
import 'profile/profile_screen.dart';
import 'achievements/achievements_screen.dart';
import 'write_to_founder_screen.dart'; // Import the new screen
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:spentree/core/auth_landing_screen.dart';

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
  late final PageController _pageController;
  late int _selectedIndex;
  final QuickActions quickActions = const QuickActions();

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _selectedIndex);
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AuthLandingScreen()),
        );
      } else {
        _setupQuickActions();
      }
    });
  }

  void _setupQuickActions() {
    quickActions.initialize((String shortcutType) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        if (shortcutType == 'action_add_expense') {
          setState(() => _selectedIndex = 1);
          _pageController.jumpToPage(1);
          AnalyticsScreen.triggerOpenForm.value = true;
        } else if (shortcutType == 'action_dashboard') {
          setState(() => _selectedIndex = 0);
          _pageController.jumpToPage(0);
        } else if (shortcutType == 'action_write_founder') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const WriteFounderScreen(),
            ),
          );
        }
      });
    });

    quickActions.setShortcutItems(<ShortcutItem>[
      const ShortcutItem(
        type: 'action_add_expense',
        localizedTitle: 'Add Expense',
        icon: 'ic_shortcut_add',
      ),
      const ShortcutItem(
        type: 'action_write_founder',
        localizedTitle: 'Write to Founders',
        icon: 'ic_shortcut_mail',
      ),
    ]);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _handleWidgetActions();
    }
  }

  Future<void> _handleWidgetActions() async {
    const platform = MethodChannel('spentree_widget_channel');
    try {
      final action = await platform.invokeMethod('getWidgetAction');
      if (action == 'OPEN_ADD_EXPENSE') {
        setState(() => _selectedIndex = 1);
        _pageController.jumpToPage(1);
        AnalyticsScreen.triggerOpenForm.value = true;
      } else if (action == 'OPEN_DASHBOARD') {
        setState(() => _selectedIndex = 0);
        _pageController.jumpToPage(0);
      }
    } catch (e) {
      debugPrint('Widget intent fetch failed: $e');
    }
  }

  void _updateSystemUI(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navColor = isDark ? const Color(0xFF252525) : Colors.white;
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        systemNavigationBarColor: navColor,
        systemNavigationBarDividerColor: navColor,
        systemNavigationBarIconBrightness: isDark
            ? Brightness.light
            : Brightness.dark,
        systemNavigationBarContrastEnforced: false,
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
    );
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
    _updateSystemUI(context);

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, _, __) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) {
              SystemNavigator.pop();
            }
          },
          child: Scaffold(
            backgroundColor: AppColors.bgWhite,
            body: PageView(
              controller: _pageController,
              physics: const ClampingScrollPhysics(),
              onPageChanged: (i) => setState(() => _selectedIndex = i),
              children: _pages,
            ),
            bottomNavigationBar: _buildNavbar(),
          ),
        );
      },
    );
  }

  Widget _buildNavbar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 80 + MediaQuery.of(context).padding.bottom,
      decoration: BoxDecoration(
        color: AppColors.renavbar,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.05),
            width: 1,
          ),
        ),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _navItem(0, PhosphorIconsRegular.house, PhosphorIconsFill.house),
          _navItem(
            1,
            PhosphorIconsRegular.chartPieSlice,
            PhosphorIconsFill.chartPieSlice,
          ),
          _navItem(
            2,
            PhosphorIconsRegular.treeEvergreen,
            PhosphorIconsFill.treeEvergreen,
          ),
          _navItem(3, PhosphorIconsRegular.trophy, PhosphorIconsFill.trophy),
          _navItem(4, PhosphorIconsRegular.user, PhosphorIconsFill.user),
        ],
      ),
    );
  }

  Widget _navItem(int index, IconData inactive, IconData active) {
    final selected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedIndex = index);
        _pageController.jumpToPage(index);
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 48,
        child: Icon(
          selected ? active : inactive,
          size: 28,
          color: selected ? AppColors.primaryGreen : const Color(0xFF666666),
        ),
      ),
    );
  }
}

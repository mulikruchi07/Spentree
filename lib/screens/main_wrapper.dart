import 'dart:ui'; // Required for ImageFilter
import 'package:flutter/material.dart';
import 'dashboard/dashboard_screen.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DashboardScreen(),
    const Center(child: Text("Analytics")),
    const Center(child: Text("Forest")),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBody: true,
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
          child: Container(
            color: Colors.white.withOpacity(0.02),
            child: SafeArea(
              child: Container(
                height: 65,
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Colors.black.withOpacity(0.05),
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
              color: isSelected ? Colors.black : const Color(0xFFAAAAAA),
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.image_not_supported,
                size: 26,
                color: isSelected ? Colors.black : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

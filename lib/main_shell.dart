import 'package:flutter/material.dart';
import 'screens/screen1_default/default_timetable_screen.dart';
import 'screens/screen2_schedules/all_schedules_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    DefaultTimetableScreen(),
    AllSchedulesScreen(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: _CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}

class _CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _CustomBottomNavBar({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: Color(0xFFFFFBF7),
        border: Border(
          top: BorderSide(
            color: Color(0xFFE8E8E8), // Very light gray/cream
            width: 1.0,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Center(
                child: _NavItem(
                  isActive: currentIndex == 1,
                  activeIcon: Icons.calendar_today,
                  inactiveIcon: Icons.calendar_today,
                  onTap: () => onTap(1),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: _NavItem(
                  isActive: currentIndex == 0,
                  activeIcon: Icons.push_pin,
                  inactiveIcon: Icons.push_pin_outlined,
                  onTap: () => onTap(0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final bool isActive;
  final IconData activeIcon;
  final IconData inactiveIcon;
  final VoidCallback onTap;

  const _NavItem({
    required this.isActive,
    required this.activeIcon,
    required this.inactiveIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: isActive
          ? Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFF040505),
                shape: BoxShape.circle,
              ),
              child: Icon(
                activeIcon,
                color: Colors.white,
                size: 20,
              ),
            )
          : Icon(
              inactiveIcon,
              color: const Color(0xFF9A9A9A),
              size: 24,
            ),
    );
  }
}

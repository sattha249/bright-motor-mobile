import 'package:flutter/material.dart';
import '../components/bottom_nav_bar.dart';
import 'category_screen.dart';
import 'login_screen.dart';
import 'welcome_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({Key? key}) : super(key: key);

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const WelcomeScreen(username: 'User'), // Replace with actual home screen
    const CategoryScreen(),
    const Center(child: Text('Orders')), // Replace with actual orders screen
    const Center(child: Text('Profile')), // Replace with actual profile screen
  ];

  void _onNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
      ),
    );
  }
} 
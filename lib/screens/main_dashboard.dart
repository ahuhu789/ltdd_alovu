import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'history_screen.dart';
import 'community_screen.dart';
import 'admin_dashboard_screen.dart';

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  int _selectedIndex = 0;
  String? _role;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (mounted) {
        setState(() {
          _role = doc.data()?['role'];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Menu cho User
    final List<Widget> userScreens = [
      const HomeScreen(),
      const HistoryScreen(),
      const CommunityScreen(),
      const ProfileScreen(),
    ];

    // Menu cho Admin/Owner
    final List<Widget> adminScreens = [
      const AdminDashboardScreen(),
      const HistoryScreen(), // Xem lịch tổng
      const ProfileScreen(),
    ];

    final screens = _role == 'owner' ? adminScreens : userScreens;

    return Scaffold(
      body: screens[_selectedIndex >= screens.length ? 0 : _selectedIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex >= screens.length ? 0 : _selectedIndex,
          selectedItemColor: Colors.green[600],
          unselectedItemColor: Colors.grey,
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          onTap: (index) => setState(() => _selectedIndex = index),
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Khám phá',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined),
              activeIcon: Icon(Icons.calendar_month),
              label: 'Lịch',
            ),
            if (_role != 'owner')
              const BottomNavigationBarItem(
                icon: Icon(Icons.groups_outlined),
                activeIcon: Icon(Icons.groups),
                label: 'Cộng đồng',
              ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Tôi',
            ),
          ],
        ),
      ),
    );
  }
}

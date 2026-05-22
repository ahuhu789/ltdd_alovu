import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Các trang của User
import 'home_screen.dart';
import 'history_screen.dart'; // Lịch đặt
import 'community_screen.dart';
import 'profile_screen.dart';
import 'chat_bot_screen.dart';

// Các trang của Admin
import 'admin_dashboard_screen.dart';
import 'static_screen.dart';
import 'chat_list_screen.dart';
import 'admin_profile_screen.dart';

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _ChatDashboardState extends State<MainDashboard> {
  // Not used anymore but left in case
}

class _MainDashboardState extends State<MainDashboard> {
  int _selectedIndex = 0;
  String _role = 'user'; // Mặc định là user
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (mounted) {
          setState(() {
            _role = doc.data()?['role'] ?? 'user';
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Colors.green),
        ),
      );
    }

    final isAdmin = _role == 'owner' || _role == 'admin';

    // 1. Cấu hình Danh sách Màn hình (Screens)
    final List<Widget> screens = isAdmin
        ? [
      const AdminDashboardScreen(),
      const StatisticsScreen(), // Gọi class từ file static_screen.dart
      const ChatListScreen(),
      const AdminProfileScreen(),
      const ProfileScreen(),
    ]
        : [
      const HomeScreen(),
      const HistoryScreen(),
      const CommunityScreen(),
      const ProfileScreen(),
    ];

    // 2. Cấu hình Thanh Menu (Bottom Navigation Bar)
    final List<BottomNavigationBarItem> navItems = isAdmin
        ? [
      const BottomNavigationBarItem(
        icon: Icon(Icons.dashboard_outlined),
        activeIcon: Icon(Icons.dashboard),
        label: 'Trang chủ',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.bar_chart_outlined),
        activeIcon: Icon(Icons.bar_chart),
        label: 'Thống kê',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.forum_outlined),
        activeIcon: Icon(Icons.forum),
        label: 'Giao tiếp',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.person_outline),
        activeIcon: Icon(Icons.person),
        label: 'Tài khoản',
      ),
    ]
        : [
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
    ];

    return Scaffold(
      body: screens[_selectedIndex >= screens.length ? 0 : _selectedIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ChatBotScreen()),
          );
        },
        backgroundColor: Colors.green[600],
        elevation: 4,
        child: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 28),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex >= screens.length ? 0 : _selectedIndex,
          backgroundColor: Colors.green[600],
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white60,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          onTap: (index) => setState(() => _selectedIndex = index),
          items: navItems,
        ),
      ),
    );
  }
}

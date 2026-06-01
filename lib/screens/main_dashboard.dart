import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../services/notification_service.dart';

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

class _MainDashboardState extends State<MainDashboard> {
  int _selectedIndex = 0;
  String _role = 'user'; // Mặc định là user
  bool _isLoading = true;

  StreamSubscription<QuerySnapshot>? _bookingsSubscription;
  final Map<String, String> _lastBookingStatus = {};
  bool _isFirstLoad = true;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  @override
  void dispose() {
    _bookingsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _listenToBookings();
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

  void _listenToBookings() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _bookingsSubscription?.cancel();
    _bookingsSubscription = FirebaseFirestore.instance
        .collection('bookings')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .listen((snapshot) {
      if (_isFirstLoad) {
        // Lần đầu tải: Chỉ ghi nhận trạng thái hiện tại, không thông báo
        for (var doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final id = doc.id;
          final status = data['status'] ?? 'pending';
          _lastBookingStatus[id] = status;
        }
        _isFirstLoad = false;
        return;
      }

      // Các lần cập nhật sau
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final id = doc.id;
        final status = data['status'] ?? 'pending';
        final fieldName = data['fieldName'] ?? 'sân thể thao';
        final time = data['time'] ?? '';

        if (_lastBookingStatus.containsKey(id)) {
          final oldStatus = _lastBookingStatus[id];
          if (oldStatus != status) {
            _lastBookingStatus[id] = status;

            // Nếu có sự thay đổi trạng thái
            String title = '';
            String body = '';
            if (status == 'completed') {
              title = 'Sân của bạn đã hoàn thành!';
              body = 'Lịch đặt $fieldName lúc $time đã được hoàn thành. Hãy đánh giá sân nhé!';
            } else if (status == 'cancelled') {
              title = 'Lịch đặt sân đã bị hủy!';
              body = 'Lịch đặt $fieldName lúc $time đã bị hủy bởi quản trị viên.';
            } else if (status == 'success') {
              title = 'Đặt sân thành công!';
              body = 'Đơn đặt sân $fieldName lúc $time đã được xác nhận.';
            }

            if (title.isNotEmpty) {
              NotificationService.instance.add(
                title: title,
                body: body,
                type: 'booking',
              );
            }
          }
        } else {
          // Đơn mới được đặt
          _lastBookingStatus[id] = status;
          NotificationService.instance.add(
            title: 'Đặt sân thành công!',
            body: 'Lịch đặt $fieldName lúc $time đã được tạo.',
            type: 'booking',
          );
        }
      }
    });
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

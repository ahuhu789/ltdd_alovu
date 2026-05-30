import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'history_screen.dart';
import 'edit_profile_screen.dart';
import 'favorite_screen.dart';
import 'notification_screen.dart';
import 'user_chat_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  ImageProvider? _getAvatarImage(String? avatarUrl, String? avatarLocalPath) {
    // Base64 (ưu tiên cao nhất — đồng bộ mọi thiết bị)
    if (avatarUrl != null && avatarUrl.startsWith('data:image')) {
      try {
        final base64Str = avatarUrl.split(',').last;
        return MemoryImage(base64Decode(base64Str));
      } catch (e) {
        debugPrint('❌ Lỗi decode base64 profile avatar: $e');
        return null;
      }
    }
    // URL thường (avatar cũ dạng http)
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return NetworkImage(avatarUrl);
    }
    // Fallback: ảnh local
    if (avatarLocalPath != null && avatarLocalPath.isNotEmpty) {
      final file = File(avatarLocalPath);
      if (file.existsSync()) {
        return FileImage(file);
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      appBar: AppBar(
        title: const Text(
          'Tài khoản',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green[600],
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: user != null
            ? FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .snapshots()
            : const Stream.empty(),
        builder: (context, snapshot) {
          // XỬ LÝ LỖI CHÍNH: Kiểm tra kết nối mạng và trạng thái dữ liệu an toàn
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.green),
            );
          }

          final snapshotData = snapshot.data;
          Map<String, dynamic>? userData;

          if (snapshotData != null && snapshotData.exists) {
            userData = snapshotData.data() as Map<String, dynamic>?;
          }

          final name = userData?['name'] ?? user?.displayName ?? 'Khách Hàng';
          final emailOrPhone =
              userData?['email'] ?? user?.email ?? 'Chưa cập nhật email';
          final avatarUrl = userData?['avatar'] ?? user?.photoURL;
          final avatarLocalPath = userData?['avatarLocalPath'];
          final avatarImage = _getAvatarImage(avatarUrl, avatarLocalPath);
          final points = userData?['points'] ?? 0;
          final role = userData?['role'] ?? 'user';

          return SingleChildScrollView(
            child: Column(
              children: [
                // Header Profile Card
                Container(
                  color: Colors.green[600],
                  width: double.infinity,
                  padding: const EdgeInsets.only(bottom: 32, top: 16),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: avatarImage,
                        backgroundColor: Colors.white,
                        child: avatarImage == null
                            ? Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.green[600],
                              )
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        emailOrPhone,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      if (role == 'owner')
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'OWNER',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Điểm tích luỹ: $points',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Các tùy chọn chức năng
                if (role == 'owner')
                  _buildListTile(
                    context,
                    Icons.admin_panel_settings,
                    'Bảng điều khiển Quản trị',
                    textColor: Colors.green[700],
                    onTap: () {
                      // Xử lý chuyển hướng đến trang Quản lý sân của Owner
                    },
                  ),
                _buildListTile(
                  context,
                  Icons.person_outline,
                  'Chỉnh sửa thông tin cá nhân',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EditProfileScreen(),
                      ),
                    );
                  },
                ),
                _buildListTile(
                  context,
                  Icons.favorite_border,
                  'Sân yêu thích',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FavoriteScreen(),
                      ),
                    );
                  },
                ),
                _buildListTile(
                  context,
                  Icons.credit_card,
                  'Phương thức thanh toán',
                  onTap: () {
                    // Xử lý chuyển hướng trang thanh toán
                  },
                ),
                _buildListTile(
                  context,
                  Icons.history,
                  'Lịch sử giao dịch',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HistoryScreen(),
                      ),
                    );
                  },
                ),
                _buildListTile(
                  context,
                  Icons.notifications_none,
                  'Cài đặt thông báo',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotificationScreen(),
                      ),
                    );
                  },
                ),
                _buildListTile(
                  context,
                  Icons.support_agent_rounded,
                  'Hỗ trợ khách hàng',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const UserChatScreen(),
                      ),
                    );
                  },
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(height: 24),
                ),

                // Nút Đăng xuất
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text(
                    'Đăng xuất',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () async {
                    // Đóng gói Navigator trước khi sang tác vụ async
                    final navigator = Navigator.of(context);
                    await AuthService().signOut();

                    // TỐI ƯU ĐIỀU HƯỚNG: Xóa toàn bộ stack cũ để quay về Login an toàn
                    navigator.pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                      (route) => false,
                    );
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildListTile(
    BuildContext context,
    IconData icon,
    String title, {
    Color? textColor,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.grey[700]),
        title: Text(
          title,
          style: TextStyle(
            color: textColor ?? Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 14,
          color: Colors.grey,
        ),
        onTap: onTap,
      ),
    );
  }
}

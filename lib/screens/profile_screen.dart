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
    if (avatarLocalPath != null && avatarLocalPath.isNotEmpty) {
      final file = File(avatarLocalPath);
      if (file.existsSync()) {
        return FileImage(file);
      }
    }
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return NetworkImage(avatarUrl);
    }
    return const NetworkImage('https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&q=80&w=200');
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tài khoản', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green[600],
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: user != null
            ? FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots()
            : const Stream.empty(),
        builder: (context, snapshot) {
          final userData = snapshot.data?.data() as Map<String, dynamic>?;
          final name = userData?['name'] ?? user?.displayName ?? 'Khách Hàng';
          final emailOrPhone = userData?['email'] ?? user?.email ?? 'Chưa cập nhật email';
          final avatarUrl = userData?['avatar'] ?? user?.photoURL;
          final avatarLocalPath = userData?['avatarLocalPath'];
          final avatarImage = _getAvatarImage(avatarUrl, avatarLocalPath);
          final points = userData?['points'] ?? 0;
          final role = userData?['role'] ?? 'user';

          return SingleChildScrollView(
            child: Column(
              children: [
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
                      ),
                      const SizedBox(height: 16),
                      Text(
                        name,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(emailOrPhone, style: const TextStyle(color: Colors.white70)),
                      if (role == 'owner')
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(12)),
                          child: const Text('OWNER', style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                        child: Text('Điểm tích luỹ: $points', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (role == 'owner')
                  _buildListTile(context, Icons.admin_panel_settings, 'Bảng điều khiển Quản trị', textColor: Colors.green[700], onTap: () {
                    // Đã có tab Admin trong dashboard, nhưng thêm nút ở đây cho tiện
                  }),
                _buildListTile(context, Icons.person_outline, 'Chỉnh sửa thông tin cá nhân', onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfileScreen()));
                }),
                _buildListTile(context, Icons.favorite, 'Sân yêu thích', onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const FavoriteScreen()));
                }),
                _buildListTile(context, Icons.credit_card, 'Phương thức thanh toán'),
                _buildListTile(context, Icons.history, 'Lịch sử giao dịch', onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryScreen()));
                }),
                _buildListTile(context, Icons.notifications_none, 'Cài đặt thông báo', onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationScreen()));
                }),
                _buildListTile(context, Icons.support_agent_rounded, 'Hỗ trợ', onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const UserChatScreen()),
                  );
                }),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(height: 32),
                ),

                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text(
                    'Đăng xuất',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () async {
                    await AuthService().signOut();
                    if (context.mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                      );
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildListTile(BuildContext context, IconData icon, String title, {Color? textColor, VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[700]),
      title: Text(title, style: TextStyle(color: textColor ?? Colors.black87)),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey,
      ),
      onTap: onTap,
    );
  }
}

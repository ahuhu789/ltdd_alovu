import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'edit_profile_screen.dart';

class AdminProfileScreen extends StatelessWidget {
  const AdminProfileScreen({super.key});

  // Hàm lấy ảnh đại diện tương tự như bên User
  ImageProvider? _getAvatarImage(String? avatarUrl, String? avatarLocalPath) {
    if (avatarLocalPath != null && avatarLocalPath.isNotEmpty) {
      final file = File(avatarLocalPath);
      if (file.existsSync()) return FileImage(file);
    }
    if (avatarUrl != null && avatarUrl.isNotEmpty) return NetworkImage(avatarUrl);
    return const NetworkImage('https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&q=80&w=200');
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Tài khoản Quản trị', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green[600],
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: user != null
            ? FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots()
            : const Stream.empty(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.green));

          final userData = snapshot.data?.data() as Map<String, dynamic>?;
          final name = userData?['name'] ?? 'Admin';
          final email = userData?['email'] ?? user?.email ?? 'Chưa cập nhật email';
          final avatarUrl = userData?['avatar'];
          final avatarLocalPath = userData?['avatarLocalPath'];
          final avatarImage = _getAvatarImage(avatarUrl, avatarLocalPath);

          return Column(
            children: [
              // --- HEADER MÀU XANH LÁ ---
              Container(
                color: Colors.green[600],
                width: double.infinity,
                padding: const EdgeInsets.only(bottom: 40, top: 10),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 55,
                      backgroundImage: avatarImage,
                      backgroundColor: Colors.white,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      name,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(email, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 12),
                    // Nhãn Quản trị viên
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                      child: const Text('QUẢN TRỊ VIÊN',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // --- DANH SÁCH CHỨC NĂNG (CHỈ GIỮ LẠI 2 MỤC) ---

              _buildAdminTile(
                context,
                Icons.person_outline_rounded,
                'Chỉnh sửa thông tin cá nhân',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfileScreen())),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Divider(height: 32, thickness: 0.8),
              ),

              _buildAdminTile(
                context,
                Icons.logout_rounded,
                'Đăng xuất',
                textColor: Colors.red,
                iconColor: Colors.red,
                onTap: () async {
                  await AuthService().signOut();
                  if (context.mounted) {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAdminTile(BuildContext context, IconData icon, String title, {Color? textColor, Color? iconColor, VoidCallback? onTap}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (iconColor ?? Colors.green[600]!).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor ?? Colors.green[700]),
      ),
      title: Text(title, style: TextStyle(
          color: textColor ?? Colors.black87,
          fontWeight: FontWeight.w600,
          fontSize: 16
      )),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }
}
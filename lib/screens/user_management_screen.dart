import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // =========================================================================
  // 1. HÀM XÓA NGƯỜI DÙNG
  // =========================================================================
  void _deleteUser(String userId, String userName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa người dùng'),
        content: Text('Bạn có chắc chắn muốn xóa tài khoản "$userName" không?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy', style: TextStyle(color: Colors.grey))
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _firestore.collection('users').doc(userId).delete();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã xóa thành công!'), backgroundColor: Colors.green)
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red)
                  );
                }
              }
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 2. FORM THÊM / SỬA NGƯỜI DÙNG
  // =========================================================================
  void _showUserForm(BuildContext context, {DocumentSnapshot? userDoc}) {
    final isEditing = userDoc != null;
    final userData = isEditing ? userDoc.data() as Map<String, dynamic> : null;

    final nameController = TextEditingController(text: userData?['name'] ?? '');
    final emailController = TextEditingController(text: userData?['email'] ?? ''); // THÊM EMAIL
    final phoneController = TextEditingController(text: userData?['phone'] ?? '');
    final passwordController = TextEditingController(text: userData?['password'] ?? '');
    final avatarController = TextEditingController(text: userData?['avatar'] ?? '');

    String selectedRole = userData?['role'] ?? 'user';
    final List<String> roles = ['user', 'owner']; // Bạn đang dùng 2 quyền

    bool isObscure = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
              return Padding(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 24
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          isEditing ? 'Cập nhật tài khoản' : 'Thêm người dùng mới',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)
                      ),
                      const SizedBox(height: 24),

                      // 1. Họ và Tên
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Họ và tên', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person, color: Colors.green)),
                      ),
                      const SizedBox(height: 16),

                      // 2. Email (Bắt buộc để đăng nhập)
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email, color: Colors.green)),
                      ),
                      const SizedBox(height: 16),

                      // 3. Số điện thoại
                      TextField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(labelText: 'Số điện thoại', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone, color: Colors.green)),
                      ),
                      const SizedBox(height: 16),

                      // 4. Mật khẩu
                      TextField(
                        controller: passwordController,
                        obscureText: isObscure,
                        decoration: InputDecoration(
                            labelText: 'Mật khẩu',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.lock, color: Colors.green),
                            suffixIcon: IconButton(
                              icon: Icon(isObscure ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                              onPressed: () {
                                setModalState(() { isObscure = !isObscure; });
                              },
                            )
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 5. Link Ảnh đại diện
                      TextField(
                        controller: avatarController,
                        decoration: const InputDecoration(labelText: 'Link ảnh đại diện (URL)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.image, color: Colors.green)),
                      ),
                      const SizedBox(height: 16),

                      // 6. Vai trò
                      DropdownButtonFormField<String>(
                        value: selectedRole,
                        decoration: const InputDecoration(labelText: 'Vai trò', border: OutlineInputBorder(), prefixIcon: Icon(Icons.security, color: Colors.green)),
                        items: roles.map((r) => DropdownMenuItem(
                            value: r,
                            child: Text(r == 'user' ? 'Khách hàng' : 'Quản trị viên')
                        )).toList(),
                        onChanged: (val) => setModalState(() { selectedRole = val!; }),
                      ),
                      const SizedBox(height: 24),

                      // NÚT LƯU
                      SizedBox(
                        width: double.infinity, height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                          ),
                          onPressed: () async {
                            if (nameController.text.trim().isEmpty || emailController.text.trim().isEmpty || passwordController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập đủ Tên, Email và Mật khẩu!')));
                              return;
                            }

                            final dataToSave = {
                              'name': nameController.text.trim(),
                              'email': emailController.text.trim(), // LƯU EMAIL VÀO DB
                              'phone': phoneController.text.trim(),
                              'password': passwordController.text.trim(),
                              'avatar': avatarController.text.trim(),
                              'role': selectedRole,
                              'updatedAt': FieldValue.serverTimestamp(),
                            };

                            try {
                              if (isEditing) {
                                await _firestore.collection('users').doc(userDoc.id).update(dataToSave);
                              } else {
                                dataToSave['createdAt'] = FieldValue.serverTimestamp();
                                await _firestore.collection('users').add(dataToSave);
                              }

                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Đã lưu thành công!'), backgroundColor: Colors.green)
                                );
                              }
                            } catch (e) {
                              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red));
                            }
                          },
                          child: Text(isEditing ? 'CẬP NHẬT' : 'XÁC NHẬN THÊM', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              );
            }
        );
      },
    );
  }

  // =========================================================================
  // 3. GIAO DIỆN CHÍNH
  // =========================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Quản lý người dùng', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.green[700],
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: Colors.green, size: 30),
            tooltip: 'Thêm người dùng',
            onPressed: () => _showUserForm(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('users').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.green));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.group_off, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text('Chưa có người dùng nào.', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                ],
              ),
            );
          }

          final users = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final userDoc = users[index];
              final userData = userDoc.data() as Map<String, dynamic>;

              final name = userData['name'] ?? 'Khách chưa có tên';
              final role = userData['role'] ?? 'user';
              final phone = userData['phone'] ?? 'Chưa cập nhật SĐT';
              final email = userData['email'] ?? 'Chưa cập nhật Email';
              final avatar = userData['avatar'] ?? '';

              final passwordLength = (userData['password']?.toString().length) ?? 0;
              final hiddenPassword = passwordLength > 0 ? List.filled(passwordLength, '*').join() : 'Chưa có MK';

              final roleText = role == 'owner' ? 'Chủ sân' : (role == 'admin' ? 'Quản trị viên' : 'Khách hàng');

              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.green.shade100)
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.green.shade50,
                      backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
                      child: avatar.isEmpty ? Icon(Icons.person, color: Colors.green[700], size: 30) : null,
                    ),
                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$roleText • $phone', style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.w600, fontSize: 13)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.email, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Expanded(child: Text(email, style: const TextStyle(color: Colors.grey, fontSize: 12), overflow: TextOverflow.ellipsis)),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.lock_outline, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text('Mật khẩu: $hiddenPassword', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          )
                        ],
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_note, color: Colors.orange),
                          onPressed: () => _showUserForm(context, userDoc: userDoc),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _deleteUser(userDoc.id, name),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
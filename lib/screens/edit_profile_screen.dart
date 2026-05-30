import 'dart:io';
import 'dart:convert'; // BẮT BUỘC: Thêm thư viện này để dùng hàm base64Encode

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  final User? user = FirebaseAuth.instance.currentUser;
  final ImagePicker _picker = ImagePicker();

  File? _selectedImage;
  String? _avatarLocalPath;

  bool _isLoading = false;

  final Color mainGreen = const Color(0xFF43A047);

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();

    if (doc.exists) {
      final data = doc.data()!;

      _nameController.text = data['name'] ?? user?.displayName ?? '';
      _emailController.text = user?.email ?? '';
      _phoneController.text = data['phone'] ?? '';
      _avatarLocalPath = data['avatarLocalPath'];
    } else {
      _nameController.text = user?.displayName ?? '';
      _emailController.text = user?.email ?? '';
    }

    if (_avatarLocalPath != null && _avatarLocalPath!.isNotEmpty) {
      final file = File(_avatarLocalPath!);
      if (await file.exists()) {
        _selectedImage = file;
      }
    }

    if (mounted) setState(() {});
  }

  Future<File> _saveImageToLocal(File imageFile) async {
    final appDir = await getApplicationDocumentsDirectory();

    final fileName =
        'avatar_${user!.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';

    return await imageFile.copy('${appDir.path}/$fileName');
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Chọn ảnh từ máy'),
              onTap: () async {
                Navigator.pop(context);

                final XFile? image = await _picker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 75,
                );

                if (image == null) return;

                final savedImage = await _saveImageToLocal(File(image.path));

                setState(() {
                  _selectedImage = savedImage;
                  _avatarLocalPath = savedImage.path;
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Chụp ảnh bằng camera'),
              onTap: () async {
                Navigator.pop(context);

                final XFile? image = await _picker.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 75,
                );

                if (image == null) return;

                final savedImage = await _saveImageToLocal(File(image.path));

                setState(() {
                  _selectedImage = savedImage;
                  _avatarLocalPath = savedImage.path;
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Xóa ảnh đại diện'),
              onTap: () {
                Navigator.pop(context);

                setState(() {
                  _selectedImage = null;
                  _avatarLocalPath = null;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      // ĐỒNG BỘ HÓA CHÍNH: Chuyển đổi dữ liệu ảnh trên máy ảo thành chuỗi Base64 đẩy lên mạng
      String base64Image = "";
      if (_selectedImage != null && _selectedImage!.existsSync()) {
        final bytes = await _selectedImage!.readAsBytes();
        base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      }

      await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
        'name': _nameController.text.trim(),
        'email': user!.email, // luôn dùng email thật từ Firebase Auth
        'phone': _phoneController.text.trim(),
        'avatarLocalPath': _avatarLocalPath,
        'avatar':
            base64Image, // BỔ SUNG QUAN TRỌNG: Ghi đè cập nhật trường avatar cho hệ thống Review nhận diện
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật thông tin thành công'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi cập nhật: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: mainGreen),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade500),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: mainGreen, width: 1.5),
      ),
    );
  }

  ImageProvider? _getAvatarImage() {
    if (_selectedImage != null && _selectedImage!.existsSync()) {
      return FileImage(_selectedImage!);
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final avatarImage = _getAvatarImage();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      appBar: AppBar(
        title: const Text(
          'Chỉnh sửa hồ sơ',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: mainGreen,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _isLoading ? null : _pickImage,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 58,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: avatarImage,
                      child: avatarImage == null
                          ? Icon(Icons.person, size: 60, color: mainGreen)
                          : null,
                    ),
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: mainGreen,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'Bấm vào ảnh để chọn ảnh đại diện',
                style: TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 28),

              TextFormField(
                controller: _nameController,
                decoration: _inputDecoration('Họ và tên', Icons.person),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập họ và tên';
                  }
                  if (value.trim().length < 2) {
                    return 'Tên phải có ít nhất 2 ký tự';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _emailController,
                readOnly: true,
                decoration: _inputDecoration('Email', Icons.email),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: _inputDecoration('Số điện thoại', Icons.phone),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập số điện thoại';
                  }
                  if (value.trim().length < 10) {
                    return 'Số điện thoại không hợp lệ';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mainGreen,
                    disabledBackgroundColor: Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Lưu thay đổi',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

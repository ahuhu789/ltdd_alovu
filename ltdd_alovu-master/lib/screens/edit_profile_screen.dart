import 'dart:io';
import 'dart:convert';

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
  String? _currentAvatarUrl;
  bool _avatarChanged = false;
  bool _isLoading = false;

  final Color mainGreen = const Color(0xFF43A047);

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        _nameController.text = data['name'] ?? user?.displayName ?? '';
        _emailController.text = user?.email ?? '';
        _phoneController.text = data['phone'] ?? '';
        _currentAvatarUrl = data['avatar'] ?? '';
        _avatarLocalPath = data['avatarLocalPath'];
      } else {
        _nameController.text = user?.displayName ?? '';
        _emailController.text = user?.email ?? '';
      }

      if ((_currentAvatarUrl == null || _currentAvatarUrl!.isEmpty) &&
          _avatarLocalPath != null &&
          _avatarLocalPath!.isNotEmpty) {
        final file = File(_avatarLocalPath!);
        if (await file.exists()) {
          _selectedImage = file;
        }
      }

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('❌ Lỗi tải dữ liệu user: $e');
    }
  }

  Future<File> _saveImageToLocal(File imageFile) async {
    final appDir = await getApplicationDocumentsDirectory();
    final fileName =
        'avatar_${user!.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    return await imageFile.copy('${appDir.path}/$fileName');
  }

  Future<String> _convertToBase64(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    debugPrint('📦 Kích thước ảnh xử lý Base64: ${bytes.length} bytes');

    if (bytes.length < 500 * 1024) {
      final base64Str = base64Encode(bytes);
      return 'data:image/jpeg;base64,$base64Str';
    }

    throw Exception(
      'Kích thước ảnh quá lớn (${(bytes.length / 1024).toStringAsFixed(0)}KB). Vui lòng thử lại.',
    );
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Chọn ảnh từ thư viện máy'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await _picker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 50,
                  maxWidth: 200,
                  maxHeight: 200,
                );
                _processPickedImage(image);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Chụp ảnh mới bằng Camera'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await _picker.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 50,
                  maxWidth: 200,
                  maxHeight: 200,
                );
                _processPickedImage(image);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Xóa ảnh đại diện hiện tại'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _selectedImage = null;
                  _avatarLocalPath = null;
                  _currentAvatarUrl = '';
                  _avatarChanged = true;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processPickedImage(XFile? image) async {
    if (image == null) return;
    final savedImage = await _saveImageToLocal(File(image.path));
    setState(() {
      _selectedImage = savedImage;
      _avatarLocalPath = savedImage.path;
      _avatarChanged = true;
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (user == null) return;

    setState(() => _isLoading = true);

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      String avatarUrl = _currentAvatarUrl ?? '';

      if (_avatarChanged && _selectedImage != null) {
        avatarUrl = await _convertToBase64(_selectedImage!);
      } else if (_avatarChanged && _selectedImage == null) {
        avatarUrl = '';
      }

      // Cập nhật duy nhất một nơi tại tài liệu của User
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
        'name': _nameController.text.trim(),
        'email': user!.email,
        'phone': _phoneController.text.trim(),
        'avatar': avatarUrl,
        'avatarLocalPath': _avatarLocalPath,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      messenger.showSnackBar(
        const SnackBar(
          content: Text('Cập nhật thông tin hồ sơ thành công'),
          backgroundColor: Colors.green,
        ),
      );

      navigator.pop();
    } catch (e) {
      debugPrint('❌ Lỗi: $e');
      messenger.showSnackBar(
        SnackBar(
          content: Text('Lỗi hệ thống: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
        borderSide: BorderSide(color: Colors.grey.shade400),
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
    if (_currentAvatarUrl != null &&
        _currentAvatarUrl!.startsWith('data:image')) {
      try {
        final base64Str = _currentAvatarUrl!.split(',').last;
        return MemoryImage(base64Decode(base64Str));
      } catch (e) {
        debugPrint('❌ Lỗi decode base64 avatar: $e');
        return null;
      }
    }
    if (_currentAvatarUrl != null && _currentAvatarUrl!.isNotEmpty) {
      return NetworkImage(_currentAvatarUrl!);
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
                  if (value == null || value.trim().isEmpty)
                    return 'Vui lòng nhập họ và tên';
                  if (value.trim().length < 2)
                    return 'Tên phải có ít nhất 2 ký tự';
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
                  if (value == null || value.trim().isEmpty)
                    return 'Vui lòng nhập số điện thoại';
                  if (value.trim().length < 10)
                    return 'Số điện thoại không hợp lệ';
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

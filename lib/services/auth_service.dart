import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../services/seed_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Khởi tạo GoogleSignIn kèm Client ID để tương thích nền tảng Web
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb
        ? '895724269212-mpbge58irn9h9iqpig3s1ln55usfj2af.apps.googleusercontent.com'
        : null,
  );

  // Đăng nhập bằng Google
  Future<UserCredential?> signInWithGoogle() async {
    // Khởi chạy quy trình xác thực Google
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      return null; // Người dùng huỷ bỏ đăng nhập
    }

    // Lấy thông tin xác thực từ yêu cầu xác thực Google
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    // Tạo một chứng chỉ xác thực mới
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Đăng nhập Firebase với chứng chỉ trên
    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user;

    // Lưu trữ thông tin người dùng xuống Firestore nếu là lần đầu đăng nhập
    if (user != null) {
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);
      final docSnap = await userRef.get();

      if (!docSnap.exists) {
        await userRef.set({
          'id': user.uid,
          'name': user.displayName ?? 'Hội viên AloVu',
          'email': user.email ?? '',
          'phone': user.phoneNumber ?? '',
          'avatar': user.photoURL ?? '',
          'role': user.email == 'ngocvcl2005@gmail.com' ? 'owner' : 'user', // Cấp role hệ thống
          'points': 0,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Đảm bảo nâng cấp quyền Owner tự động dù User này đã từng đăng nhập trước đó
        final currentRole = docSnap.data()?['role'];
        if (user.email == 'ngocvcl2005@gmail.com' && currentRole != 'owner') {
          await userRef.update({'role': 'owner'});
        }
      }

      // Khi người dùng đã có Identity Auth hợp lệ, tiến hành nhồi dữ liệu (Seed Data)
      await SeedService().seedSportFields();
    }

    return userCredential;
  }

  // Đăng xuất
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // Quản lý Sân yêu thích
  Future<void> toggleFavorite(String fieldId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final doc = await userRef.get();
    List favorites = doc.data()?['favorites'] ?? [];

    if (favorites.contains(fieldId)) {
      await userRef.update({
        'favorites': FieldValue.arrayRemove([fieldId])
      });
    } else {
      await userRef.update({
        'favorites': FieldValue.arrayUnion([fieldId])
      });
    }
  }

  Stream<List<String>> getUserFavorites() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((doc) => List<String>.from(doc.data()?['favorites'] ?? []));
  }

  // Đăng ký bằng Email và Mật khẩu
  Future<UserCredential?> registerWithEmailAndPassword(String email, String password, String name, String phone) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = userCredential.user;
    if (user != null) {
      await user.updateDisplayName(name);
      
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      await userRef.set({
        'id': user.uid,
        'name': name,
        'email': email,
        'phone': phone,
        'avatar': '',
        'role': email == 'ngocvcl2005@gmail.com' ? 'owner' : 'user',
        'points': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await SeedService().seedSportFields();
    }
    return userCredential;
  }

  // Đăng nhập bằng Email và Mật khẩu
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Gửi email khôi phục mật khẩu
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}

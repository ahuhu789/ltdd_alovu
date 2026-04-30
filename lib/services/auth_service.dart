import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../services/seed_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Google Sign-In cấu hình Web Client ID
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb
        ? '895724269212-mpbge58irn9h9iqpig3s1ln55usfj2af.apps.googleusercontent.com'
        : null,
  );

  // =========================
  // ĐĂNG NHẬP GOOGLE
  // =========================
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Ép hiện màn hình chọn tài khoản mỗi lần
      await _googleSignIn.signOut();

      // Bắt đầu đăng nhập
      final GoogleSignInAccount? googleUser =
      await _googleSignIn.signIn();

      if (googleUser == null) {
        return null; // User huỷ đăng nhập
      }

      // Lấy token xác thực
      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      // Tạo credential Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Đăng nhập Firebase
      final userCredential =
      await _auth.signInWithCredential(credential);

      final user = userCredential.user;

      if (user != null) {
        final userRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid);

        final docSnap = await userRef.get();

        // Nếu lần đầu đăng nhập
        if (!docSnap.exists) {
          await userRef.set({
            'id': user.uid,
            'name': user.displayName ?? 'Hội viên AloVu',
            'email': user.email ?? '',
            'phone': user.phoneNumber ?? '',
            'avatar': user.photoURL ?? '',
            'role': user.email == 'ngocvcl2005@gmail.com'
                ? 'owner'
                : 'user',
            'points': 0,
            'favorites': [],
            'createdAt': FieldValue.serverTimestamp(),
          });
        } else {
          // Cập nhật quyền owner nếu đúng email admin
          final currentRole = docSnap.data()?['role'];

          if (user.email == 'ngocvcl2005@gmail.com' &&
              currentRole != 'owner') {
            await userRef.update({'role': 'owner'});
          }

          // Đồng bộ avatar nếu thiếu
          if ((docSnap.data()?['avatar'] ?? '').toString().isEmpty &&
              user.photoURL != null) {
            await userRef.update({
              'avatar': user.photoURL,
            });
          }
        }

        // Seed dữ liệu sân
        await SeedService().seedSportFields();
      }

      return userCredential;
    } catch (e) {
      debugPrint("Google Sign-In Error: $e");
      return null;
    }
  }

  // =========================
  // ĐĂNG XUẤT
  // =========================
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // =========================
  // YÊU THÍCH SÂN
  // =========================
  Future<void> toggleFavorite(String fieldId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userRef =
    FirebaseFirestore.instance.collection('users').doc(user.uid);

    final doc = await userRef.get();
    List favorites = doc.data()?['favorites'] ?? [];

    if (favorites.contains(fieldId)) {
      await userRef.update({
        'favorites': FieldValue.arrayRemove([fieldId]),
      });
    } else {
      await userRef.update({
        'favorites': FieldValue.arrayUnion([fieldId]),
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
        .map((doc) =>
    List<String>.from(doc.data()?['favorites'] ?? []));
  }

  // =========================
  // ĐĂNG KÝ EMAIL/PASSWORD
  // =========================
  Future<UserCredential?> registerWithEmailAndPassword(
      String email,
      String password,
      String name,
      String phone,
      ) async {
    try {
      final userCredential =
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;

      if (user != null) {
        await user.updateDisplayName(name);

        final userRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid);

        await userRef.set({
          'id': user.uid,
          'name': name,
          'email': email,
          'phone': phone,
          'avatar': '',
          'role': email == 'ngocvcl2005@gmail.com'
              ? 'owner'
              : 'user',
          'points': 0,
          'favorites': [],
          'createdAt': FieldValue.serverTimestamp(),
        });

        await SeedService().seedSportFields();
      }

      return userCredential;
    } catch (e) {
      debugPrint("Register Error: $e");
      return null;
    }
  }

  // =========================
  // ĐĂNG NHẬP EMAIL/PASSWORD
  // =========================
  Future<UserCredential?> signInWithEmailAndPassword(
      String email,
      String password,
      ) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      debugPrint("Email Login Error: $e");
      return null;
    }
  }

  // =========================
  // RESET PASSWORD
  // =========================
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}
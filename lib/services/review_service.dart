import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/sport_field.dart';

class ReviewService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Stream danh sách đánh giá của một sân, sắp xếp theo ngày mới nhất
  Stream<List<Review>> getReviews(String fieldId) {
    return _db
        .collection('sport_fields')
        .doc(fieldId)
        .collection('reviews')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            // Đảm bảo hàm từ json nhận đúng id
            return Review.fromJson(doc.data(), docId: doc.id);
          }).toList();
        });
  }

  /// Kiểm tra xem người dùng hiện tại đã đánh giá sân này chưa
  Stream<bool> hasUserReviewed(String fieldId) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(false);

    return _db
        .collection('sport_fields')
        .doc(fieldId)
        .collection('reviews')
        .doc(user.uid) // Chỉ cần kiểm tra Document ID có tồn tại không
        .snapshots()
        .map((docSnapshot) => docSnapshot.exists);
  }

  /// Thêm đánh giá mới (Mỗi khách chỉ được đánh giá 1 lần duy nhất)
  Future<bool> addReview({
    required String fieldId,
    required double rating,
    required String comment,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    // Đặt ID của review chính là UID của User để chặn đứng spam tạo nhiều review
    final reviewRef = _db
        .collection('sport_fields')
        .doc(fieldId)
        .collection('reviews')
        .doc(user.uid);

    // Kiểm tra nhanh sự tồn tại tài liệu bằng phương thức gọn nhẹ nhất
    final docCheck = await reviewRef.get();
    if (docCheck.exists) {
      debugPrint('⚠️ Người dùng ${user.uid} đã đánh giá sân này trước đó.');
      return false;
    }

    // Lấy thông tin user từ Firestore
    final userDoc = await _db.collection('users').doc(user.uid).get();
    final userData = userDoc.data();
    final userName = userData?['name'] ?? user.displayName ?? 'Khách hàng';

    // TỐI ƯU/SỬA LỖI CHÍNH: Nhận diện nếu avatar đang lưu là giá trị bậy "2",
    // tự động chuyển thành chuỗi chuẩn để hàm _buildAvatarImage bên DetailScreen nhận diện ra ảnh pixel
    String avatarUrl = userData?['avatar'] ?? user.photoURL ?? '';
    if (avatarUrl == "2") {
      avatarUrl =
          "avatar_pixel"; // Chuỗi định danh để DetailScreen kích hoạt AssetImage
    }

    final review = Review(
      id: user.uid,
      userId: user.uid,
      userName: userName,
      avatarUrl: avatarUrl,
      rating: rating,
      comment: comment,
      date: DateTime.now(),
      likes: [],
    );

    // Thực hiện Ghi dữ liệu review
    await reviewRef.set(review.toJson());

    // Cập nhật lại rating trung bình tổng thể cho sân
    await _updateAverageRating(fieldId);

    return true;
  }

  /// Toggle trạng thái Thích / Bỏ thích cho một đánh giá
  Future<void> toggleLike(String fieldId, String reviewId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final reviewRef = _db
        .collection('sport_fields')
        .doc(fieldId)
        .collection('reviews')
        .doc(reviewId);

    final doc = await reviewRef.get();
    if (!doc.exists) return;

    final likes = List<String>.from(doc.data()?['likes'] ?? []);

    if (likes.contains(user.uid)) {
      await reviewRef.update({
        'likes': FieldValue.arrayRemove([user.uid]),
      });
    } else {
      await reviewRef.update({
        'likes': FieldValue.arrayUnion([user.uid]),
      });
    }
  }

  /// Xóa đánh giá (chỉ dùng cho Admin hoặc khi cần thiết)
  Future<void> deleteReview(String fieldId, String reviewId) async {
    await _db
        .collection('sport_fields')
        .doc(fieldId)
        .collection('reviews')
        .doc(reviewId)
        .delete();

    // Tính toán lại rating trung bình cho sân
    await _updateAverageRating(fieldId);
  }

  /// Đã sửa lỗi: Tính toán lại điểm số trung bình an toàn, chống crash 'Null' type cast
  Future<void> _updateAverageRating(String fieldId) async {
    final snapshot = await _db
        .collection('sport_fields')
        .doc(fieldId)
        .collection('reviews')
        .get();

    final fieldRef = _db.collection('sport_fields').doc(fieldId);

    // Nếu không còn đánh giá nào (bị xóa sạch), cập nhật điểm về lại 0.0
    if (snapshot.docs.isEmpty) {
      await fieldRef.update({'rating': 0.0});
      return;
    }

    double totalRating = 0;
    int validReviewsCount = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data();
      // Bổ sung chốt chặn an toàn: Chỉ tính toán khi trường rating tồn tại và không null
      if (data != null && data['rating'] != null) {
        totalRating += (data['rating'] as num).toDouble();
        validReviewsCount++;
      }
    }

    // Trường hợp các bản ghi cũ đều lỗi không chứa điểm số hợp lệ
    if (validReviewsCount == 0) {
      await fieldRef.update({'rating': 0.0});
      return;
    }

    final averageRating = totalRating / validReviewsCount;
    final roundedRating = double.parse(averageRating.toStringAsFixed(1));

    await fieldRef.update({'rating': roundedRating});
    debugPrint('⭐ Đã cập nhật rating sân ($fieldId) thành: $roundedRating');
  }
}

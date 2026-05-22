import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/mock_data.dart';

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
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) => snapshot.docs.isNotEmpty);
  }

  /// Thêm đánh giá mới (mỗi khách chỉ được đánh giá 1 lần)
  Future<bool> addReview({
    required String fieldId,
    required double rating,
    required String comment,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    // Kiểm tra trùng lặp
    final existing = await _db
        .collection('sport_fields')
        .doc(fieldId)
        .collection('reviews')
        .where('userId', isEqualTo: user.uid)
        .get();

    if (existing.docs.isNotEmpty) {
      return false; // Đã đánh giá rồi
    }

    // Lấy thông tin user từ Firestore
    final userDoc = await _db.collection('users').doc(user.uid).get();
    final userData = userDoc.data();
    final userName = userData?['name'] ?? user.displayName ?? 'Khách hàng';
    final avatarUrl = userData?['avatar'] ?? user.photoURL ?? '';

    final docRef = _db
        .collection('sport_fields')
        .doc(fieldId)
        .collection('reviews')
        .doc();

    final review = Review(
      id: docRef.id,
      userId: user.uid,
      userName: userName,
      avatarUrl: avatarUrl,
      rating: rating,
      comment: comment,
      date: DateTime.now(),
      likes: [],
    );

    await docRef.set(review.toJson());

    // Cập nhật rating trung bình cho sân
    await _updateAverageRating(fieldId);

    return true;
  }

  /// Toggle like/unlike cho một đánh giá
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

  /// Tính lại và cập nhật rating trung bình cho sân
  Future<void> _updateAverageRating(String fieldId) async {
    final snapshot = await _db
        .collection('sport_fields')
        .doc(fieldId)
        .collection('reviews')
        .get();

    if (snapshot.docs.isEmpty) return;

    double totalRating = 0;
    for (var doc in snapshot.docs) {
      totalRating += (doc.data()['rating'] as num).toDouble();
    }
    final averageRating = totalRating / snapshot.docs.length;

    // Làm tròn 1 chữ số thập phân
    final rounded = double.parse(averageRating.toStringAsFixed(1));

    await _db.collection('sport_fields').doc(fieldId).update({
      'rating': rounded,
    });
  }
}

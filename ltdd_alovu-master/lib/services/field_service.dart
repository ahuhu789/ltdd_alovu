import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/sport_field.dart';

class FieldService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream lắng nghe thay đổi dữ liệu bảng sport_fields kèm bộ lọc
  Stream<List<SportField>> getSportFields({String? category, String? searchQuery}) {
    Query query = _db.collection('sport_fields');

    // Lọc theo danh mục nếu có
    if (category != null && category != 'Tất cả') {
      query = query.where('category', isEqualTo: category);
    }

    return query.snapshots().map((snapshot) {
      List<SportField> fields = snapshot.docs.map((doc) {
        return SportField.fromJson(doc.data() as Map<String, dynamic>);
      }).toList();

      // Lọc tìm kiếm theo tên (vì Firestore không hỗ trợ tìm kiếm text fuzzy mạnh mẽ không cần Index)
      if (searchQuery != null && searchQuery.isNotEmpty) {
        fields = fields.where((f) => f.name.toLowerCase().contains(searchQuery.toLowerCase())).toList();
      }

      return fields;
    });
  }

  // Thêm sân mới
  Future<void> addField(SportField field) async {
    await _db.collection('sport_fields').doc(field.id).set(field.toJson());
  }

  // Cập nhật sân
  Future<void> updateField(String id, Map<String, dynamic> data) async {
    await _db.collection('sport_fields').doc(id).update(data);
  }

  // Xóa sân
  Future<void> deleteField(String id) async {
    await _db.collection('sport_fields').doc(id).delete();
  }

  // Thêm đánh giá mới
  Future<void> addReview(String fieldId, Review review) async {
    final docRef = _db.collection('sport_fields').doc(fieldId);
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) {
        throw Exception("Sân không tồn tại!");
      }
      
      final data = snapshot.data()!;
      final List<dynamic> reviewsData = data['reviews'] ?? [];
      
      // Kiểm tra xem đã đánh giá chưa
      final hasReviewed = reviewsData.any((r) => r['userId'] == review.userId);
      if (hasReviewed) {
        throw Exception("Bạn đã đánh giá sân này rồi!");
      }
      
      // Thêm đánh giá mới
      reviewsData.add(review.toJson());
      
      // Tính lại rating trung bình
      double totalRating = 0;
      for (var r in reviewsData) {
        totalRating += (r['rating'] as num).toDouble();
      }
      double averageRating = reviewsData.isEmpty ? 0 : totalRating / reviewsData.length;
      
      // Chỉ lấy 1 chữ số thập phân
      averageRating = double.parse(averageRating.toStringAsFixed(1));
      
      transaction.update(docRef, {
        'reviews': reviewsData,
        'rating': averageRating,
      });
    });
  }

  // Toggle Like cho một Review
  Future<void> toggleReviewLike(String fieldId, String reviewUserId, String currentUserId) async {
    final docRef = _db.collection('sport_fields').doc(fieldId);
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;
      
      final data = snapshot.data()!;
      final List<dynamic> reviewsData = data['reviews'] ?? [];
      
      bool updated = false;
      for (var i = 0; i < reviewsData.length; i++) {
        if (reviewsData[i]['userId'] == reviewUserId) {
          List<String> likedBy = (reviewsData[i]['likedBy'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [];
          if (likedBy.contains(currentUserId)) {
            likedBy.remove(currentUserId);
          } else {
            likedBy.add(currentUserId);
          }
          reviewsData[i]['likedBy'] = likedBy;
          updated = true;
          break;
        }
      }
      
      if (updated) {
        transaction.update(docRef, {'reviews': reviewsData});
      }
    });
  }
}

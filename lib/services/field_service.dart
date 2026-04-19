import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/mock_data.dart';

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
    await _db.collection('sport_fields').doc(fieldId).update({
      'reviews': FieldValue.arrayUnion([review.toJson()]),
      'rating': (FieldValue.increment(review.rating) as dynamic) // Thực tế cần chia trung bình, mockup increment tạm
    });
  }
}

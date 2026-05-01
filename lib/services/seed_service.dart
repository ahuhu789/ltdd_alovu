import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/mock_data.dart';

class SeedService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> seedSportFields() async {
    try {
      final snapshot = await _db.collection('sport_fields').limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        debugPrint('SportFields đã tồn tại dữ liệu. Bỏ qua lệnh bơm dữ liệu.');
        return;
      }

      final batch = _db.batch();
      for (final field in mockFields) {
        final docRef = _db.collection('sport_fields').doc(field.id);
        batch.set(docRef, field.toJson());
      }

      await batch.commit();
      debugPrint('Đã bơm (seed) dữ liệu sport_fields thành công!');
    } catch (e) {
      debugPrint('Lỗi nhồi dữ liệu: $e');
    }
  }
}

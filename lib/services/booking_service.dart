import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/sport_field.dart';

class BookingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<bool> createBooking({
    required SportField field,
    required String courtName,
    required String time,
    required String paymentMethod,
    required String totalAmount,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // 1. Tạo bản ghi Booking mới
      final bookingRef = _db.collection('bookings').doc();

      // 2. Cập nhật trạng thái sân thành Hết Chỗ thông qua Transaction để tránh đụng độ (Race Condition)
      final fieldRef = _db.collection('sport_fields').doc(field.id);

      await _db.runTransaction((transaction) async {
        final snapshot = await transaction.get(fieldRef);
        if (!snapshot.exists) throw Exception('Sân thể thao không tồn tại!');

        final currentField = SportField.fromJson(snapshot.data()!);

        bool foundAndUpdated = false;

        // Tìm khe giờ tương ứng và đánh dấu đã được đặt
        for (var i = 0; i < currentField.subCourts.length; i++) {
          if (currentField.subCourts[i].name == courtName) {
            for (var j = 0; j < currentField.subCourts[i].slots.length; j++) {
              if (currentField.subCourts[i].slots[j].time == time) {
                if (!currentField.subCourts[i].slots[j].isAvailable) {
                  throw Exception(
                    'Rất tiếc, sân giờ này vừa có người đặt xong!',
                  );
                }
                currentField.subCourts[i].slots[j] = TimeSlot(
                  time: time,
                  isAvailable: false,
                );
                foundAndUpdated = true;
                break;
              }
            }
          }
        }

        if (!foundAndUpdated)
          throw Exception('Không tìm thấy dữ liệu Sân và Khung giờ yêu cầu');

        // Cập nhật mảng subCourts vào SportField
        transaction.update(fieldRef, {
          'subCourts': currentField.subCourts.map((e) => e.toJson()).toList(),
        });

        // Ghi giao dịch Booking
        transaction.set(bookingRef, {
          'id': bookingRef.id,
          'userId': user.uid,
          'fieldId': field.id,
          'fieldName': field.name,
          'fieldAddress': field.address,
          'courtName': courtName,
          'time': time,
          'totalAmount': totalAmount,
          'paymentMethod': paymentMethod,
          'status': 'success',
          'createdAt': FieldValue.serverTimestamp(),
        });
      });

      return true;
    } catch (e) {
      debugPrint('Lỗi giao dịch đặt sân: $e');
      return false;
    }
  }
}

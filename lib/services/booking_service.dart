import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/sport_field.dart';
import '../models/booking.dart';

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

      final bookingRef = _db.collection('bookings').doc();


      final fieldRef = _db.collection('sport_fields').doc(field.id);

      await _db.runTransaction((transaction) async {
        final snapshot = await transaction.get(fieldRef);
        if (!snapshot.exists) throw Exception('Sân thể thao không tồn tại!');

        final currentField = SportField.fromJson(snapshot.data()!);

        bool foundAndUpdated = false;

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

        transaction.update(fieldRef, {
          'subCourts': currentField.subCourts.map((e) => e.toJson()).toList(),
        });

        transaction.set(bookingRef, {
          'id': bookingRef.id,
          'userId': user.uid,
          'fieldId': field.id,
          'fieldName': field.name,
          'fieldAddress': field.address,
          'courtName': courtName,
          'category': field.category,
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
  Stream<List<Booking>> getAllBookings() {
    return _db
        .collection('bookings')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Booking.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  Future<void> markAsPlayed(String bookingId) async {
    try {
      await _db.collection('bookings').doc(bookingId).update({
        'status': 'completed',
      });
    } catch (e) {
      debugPrint('Lỗi cập nhật trạng thái Đã chơi: $e');
      throw Exception('Không thể cập nhật trạng thái');
    }
  }

  Future<void> cancelBooking(Booking booking, {bool requireRefund = false}) async {
    final bookingRef = _db.collection('bookings').doc(booking.id);
    final fieldRef = _db.collection('sport_fields').doc(booking.fieldId);

    try {
      await _db.runTransaction((transaction) async {
        final snapshot = await transaction.get(fieldRef);

        transaction.update(bookingRef, {
          'status': 'cancelled',
          'refundStatus': requireRefund ? 'pending_refund' : 'none',
          'cancelledAt': FieldValue.serverTimestamp(),
        });

        if (snapshot.exists) {
          final currentField = SportField.fromJson(snapshot.data()!);
          bool isUpdated = false;

          for (var i = 0; i < currentField.subCourts.length; i++) {
            if (currentField.subCourts[i].name == booking.courtName) {
              for (var j = 0; j < currentField.subCourts[i].slots.length; j++) {
                if (currentField.subCourts[i].slots[j].time == booking.time) {
                  currentField.subCourts[i].slots[j] = TimeSlot(
                    time: booking.time,
                    isAvailable: true,
                  );
                  isUpdated = true;
                  break;
                }
              }
            }
          }

          if (isUpdated) {
            transaction.update(fieldRef, {
              'subCourts': currentField.subCourts.map((e) => e.toJson()).toList(),
            });
          }
        }
      });
    } catch (e) {
      debugPrint('Lỗi khi hủy đơn và trả sân: $e');
      throw Exception('Không thể hủy đơn đặt sân');
    }
  }
  Future<void> processRefund(String bookingId) async {
    try {
      await _db.collection('bookings').doc(bookingId).update({
        'refundStatus': 'refunded',
      });
    } catch (e) {
      debugPrint('Lỗi cập nhật hoàn tiền: $e');
      throw Exception('Không thể cập nhật trạng thái hoàn tiền');
    }
  }
}

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
    required String bookingDate,
    required String paymentMethod,
    required String totalAmount,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Query to check if there is an active booking for this exact date, court and time
      final existingBookings = await _db.collection('bookings')
          .where('fieldId', isEqualTo: field.id)
          .where('courtName', isEqualTo: courtName)
          .where('time', isEqualTo: time)
          .where('bookingDate', isEqualTo: bookingDate)
          .get();

      bool isAlreadyBooked = false;
      for (var doc in existingBookings.docs) {
        final status = doc.data()['status'] ?? 'pending';
        if (status != 'cancelled') {
          isAlreadyBooked = true;
          break;
        }
      }

      if (isAlreadyBooked) {
        debugPrint('Lỗi đặt sân: Khung giờ này đã có người đặt trước!');
        return false;
      }

      final bookingRef = _db.collection('bookings').doc();

      // Get user name and phone
      String userName = 'Khách lẻ';
      String userPhone = 'Chưa cập nhật';
      final userDoc = await _db.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data();
        if (data != null) {
          userName = data['name'] ?? 'Khách lẻ';
          userPhone = data['phone'] ?? 'Chưa cập nhật';
        }
      }

      await bookingRef.set({
        'id': bookingRef.id,
        'userId': user.uid,
        'userName': userName,
        'userPhone': userPhone,
        'fieldId': field.id,
        'fieldName': field.name,
        'fieldAddress': field.address,
        'courtName': courtName,
        'category': field.category,
        'time': time,
        'bookingDate': bookingDate,
        'totalAmount': totalAmount,
        'paymentMethod': paymentMethod,
        'status': 'success',
        'createdAt': FieldValue.serverTimestamp(),
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
    try {
      await bookingRef.update({
        'status': 'cancelled',
        'refundStatus': requireRefund ? 'pending_refund' : 'none',
        'cancelledAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Lỗi khi hủy đơn đặt sân: $e');
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

import 'package:cloud_firestore/cloud_firestore.dart';


class Booking {
  final String userName;
  final String userPhone;
  final String refundStatus;
  final String id;
  final String userId;
  final String fieldId;
  final String fieldName;
  final String fieldAddress;
  final String courtName;
  final String time;
  final String totalAmount;
  final String paymentMethod;
  final String status;
  final DateTime createdAt;


  Booking({
    required this.userName,
    required this.userPhone,
    required this.id,
    required this.userId,
    required this.fieldId,
    required this.fieldName,
    required this.fieldAddress,
    required this.courtName,
    required this.time,
    required this.totalAmount,
    required this.paymentMethod,
    required this.status,
    required this.createdAt,
    required this.refundStatus,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {

    // Xử lý an toàn cho kiểu DateTime từ Firebase
    DateTime parsedDate = DateTime.now();
    if (json['createdAt'] != null) {
      if (json['createdAt'] is Timestamp) {
        parsedDate = (json['createdAt'] as Timestamp).toDate();
      }
    }

    return Booking(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      fieldId: json['fieldId'] ?? '',
      fieldName: json['fieldName'] ?? '',
      fieldAddress: json['fieldAddress'] ?? '',
      courtName: json['courtName'] ?? '',
      time: json['time'] ?? '',
      totalAmount: json['totalAmount'] ?? '0',
      paymentMethod: json['paymentMethod'] ?? '',
      status: json['status'] ?? 'pending',
      refundStatus: json['refundStatus'] ?? 'none',
      createdAt: parsedDate,
      userName: json['userName'] ?? 'Khách lẻ',
      userPhone: json['userPhone'] ?? 'Chưa cập nhật',
    );
  }
}
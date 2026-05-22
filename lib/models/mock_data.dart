import 'package:cloud_firestore/cloud_firestore.dart';

class TimeSlot {
  final String time;
  bool isAvailable;

  TimeSlot({required this.time, required this.isAvailable});

  factory TimeSlot.fromJson(Map<String, dynamic> json) => TimeSlot(
        time: json['time'] as String,
        isAvailable: json['isAvailable'] as bool,
      );

  Map<String, dynamic> toJson() => {
        'time': time,
        'isAvailable': isAvailable,
      };
}

class SubCourt {
  final String name;
  final List<TimeSlot> slots;

  SubCourt({required this.name, required this.slots});

  factory SubCourt.fromJson(Map<String, dynamic> json) => SubCourt(
        name: json['name'] as String,
        slots: (json['slots'] as List<dynamic>?)
                ?.map((e) => TimeSlot.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'slots': slots.map((e) => e.toJson()).toList(),
      };
}

class Review {
  final String id;
  final String userId;
  final String userName;
  final String avatarUrl;
  final double rating;
  final String comment;
  final DateTime date;
  final List<String> likes;

  Review({
    required this.id,
    required this.userId,
    required this.userName,
    required this.avatarUrl,
    required this.rating,
    required this.comment,
    required this.date,
    this.likes = const [],
  });

  factory Review.fromJson(Map<String, dynamic> json, {String? docId}) => Review(
        id: docId ?? json['id'] as String? ?? '',
        userId: json['userId'] as String? ?? '',
        userName: json['userName'] as String,
        avatarUrl: json['avatarUrl'] as String? ?? '',
        rating: (json['rating'] as num).toDouble(),
        comment: json['comment'] as String,
        date: json['date'] is Timestamp
            ? (json['date'] as Timestamp).toDate()
            : DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
        likes: List<String>.from(json['likes'] ?? []),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'userName': userName,
        'avatarUrl': avatarUrl,
        'rating': rating,
        'comment': comment,
        'date': Timestamp.fromDate(date),
        'likes': likes,
      };
}

class SportField {
  final String id;
  final String name;
  final String category;
  final String price;
  final String imageUrl;
  final String address;
  final double rating;
  final List<SubCourt> subCourts;

  SportField({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.imageUrl,
    required this.address,
    required this.rating,
    required this.subCourts,
  });

  factory SportField.fromJson(Map<String, dynamic> json) => SportField(
        id: json['id'] as String,
        name: json['name'] as String,
        category: json['category'] as String,
        price: json['price'] as String,
        imageUrl: json['imageUrl'] as String,
        address: json['address'] as String,
        rating: (json['rating'] as num).toDouble(),
        subCourts: (json['subCourts'] as List<dynamic>?)
                ?.map((e) => SubCourt.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'price': price,
        'imageUrl': imageUrl,
        'address': address,
        'rating': rating,
        'subCourts': subCourts.map((e) => e.toJson()).toList(),
      };
}

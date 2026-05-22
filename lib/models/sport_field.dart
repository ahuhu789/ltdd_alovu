import 'package:cloud_firestore/cloud_firestore.dart';

class TimeSlot {
  String time;
  bool isAvailable;

  TimeSlot({required this.time, required this.isAvailable});

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      time: json['time'] ?? '',
      isAvailable: json['isAvailable'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {'time': time, 'isAvailable': isAvailable};
  }
}

class SubCourt {
  String name;
  List<TimeSlot> slots;

  SubCourt({required this.name, required this.slots});

  factory SubCourt.fromJson(Map<String, dynamic> json) {
    var slotsJson = json['slots'] as List? ?? [];
    return SubCourt(
      name: json['name'] ?? '',
      slots: slotsJson.map((e) => TimeSlot.fromJson(e)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'slots': slots.map((e) => e.toJson()).toList()};
  }
}

class Review {
  String id;
  String userId;
  String userName;
  String avatarUrl;
  double rating;
  String comment;
  DateTime date;
  List<String> likes;

  List<String> get likedBy => likes;

  Review({
    this.id = '',
    required this.userId,
    required this.userName,
    required this.avatarUrl,
    required this.rating,
    required this.comment,
    required this.date,
    this.likes = const [],
  });

  factory Review.fromJson(Map<String, dynamic> json, {String? docId}) {
    DateTime parsedDate;
    if (json['date'] is Timestamp) {
      parsedDate = (json['date'] as Timestamp).toDate();
    } else if (json['date'] is String) {
      parsedDate = DateTime.tryParse(json['date']) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    List<String> likesList = [];
    if (json['likes'] != null) {
      likesList = List<String>.from(json['likes']);
    } else if (json['likedBy'] != null) {
      likesList = List<String>.from(json['likedBy']);
    }

    return Review(
      id: docId ?? json['id'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? 'Khách',
      avatarUrl: json['avatarUrl'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      comment: json['comment'] ?? '',
      date: parsedDate,
      likes: likesList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'avatarUrl': avatarUrl,
      'rating': rating,
      'comment': comment,
      'date': date.toIso8601String(),
      'likes': likes,
      'likedBy': likes,
    };
  }
}

class SportField {
  String id;
  String name;
  String category;
  String address;
  String price;
  String imageUrl;
  double rating;
  List<Review> reviews;
  List<SubCourt> subCourts;

  SportField({
    required this.id,
    required this.name,
    required this.category,
    required this.address,
    required this.price,
    required this.imageUrl,
    this.rating = 0.0,
    this.reviews = const [],
    this.subCourts = const [],
  });

  factory SportField.fromJson(Map<String, dynamic> json) {
    var reviewsJson = json['reviews'] as List? ?? [];
    var subCourtsJson = json['subCourts'] as List? ?? [];
    return SportField(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      address: json['address'] ?? '',
      price: json['price'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviews: reviewsJson.map((e) => Review.fromJson(e)).toList(),
      subCourts: subCourtsJson.map((e) => SubCourt.fromJson(e)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'address': address,
      'price': price,
      'imageUrl': imageUrl,
      'rating': rating,
      'reviews': reviews.map((e) => e.toJson()).toList(),
      'subCourts': subCourts.map((e) => e.toJson()).toList(),
    };
  }
}

class TimeSlot {
  final String time;
  final bool isAvailable;

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
  final String userName;
  final String avatarUrl;
  final double rating;
  final String comment;
  final String date;

  Review({
    required this.userName,
    required this.avatarUrl,
    required this.rating,
    required this.comment,
    required this.date,
  });

  factory Review.fromJson(Map<String, dynamic> json) => Review(
        userName: json['userName'] as String,
        avatarUrl: json['avatarUrl'] as String,
        rating: (json['rating'] as num).toDouble(),
        comment: json['comment'] as String,
        date: json['date'] as String,
      );

  Map<String, dynamic> toJson() => {
        'userName': userName,
        'avatarUrl': avatarUrl,
        'rating': rating,
        'comment': comment,
        'date': date,
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
  final List<Review> reviews;

  SportField({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.imageUrl,
    required this.address,
    required this.rating,
    required this.subCourts,
    required this.reviews,
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
        reviews: (json['reviews'] as List<dynamic>?)
                ?.map((e) => Review.fromJson(e as Map<String, dynamic>))
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
        'reviews': reviews.map((e) => e.toJson()).toList(),
      };
}

List<Review> _mockReviews() {
  return [
    Review(
      userName: 'Trần Văn A',
      avatarUrl:
          'https://images.unsplash.com/photo-1599566150163-29194dcaad36?auto=format&fit=crop&q=80&w=150',
      rating: 5.0,
      comment: 'Sân đẹp, đèn sáng, chủ sân nhiệt tình. Sẽ quay lại!',
      date: '12/10/2023',
    ),
    Review(
      userName: 'Lê Thị B',
      avatarUrl:
          'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&q=80&w=150',
      rating: 4.0,
      comment: 'Giá cả hợp lý, tuy nhiên bãi giữ xe hơi nhỏ vào giờ cao điểm.',
      date: '05/10/2023',
    ),
  ];
}

List<SportField> mockFields = [
  SportField(
    id: '1',
    name: 'Sân Bóng Đá Chảo Lửa',
    category: 'Bóng đá',
    price: '250.000đ / giờ',
    imageUrl:
        'https://images.unsplash.com/photo-1574629810360-7efbbc0aa5cb?auto=format&fit=crop&w=800',
    address: 'Quận Tân Bình, TP.HCM',
    rating: 4.8,
    reviews: _mockReviews(),
    subCourts: [
      SubCourt(
        name: 'Sân 5 người (A)',
        slots: [
          TimeSlot(time: '17:00 - 18:00', isAvailable: false),
          TimeSlot(time: '18:00 - 19:00', isAvailable: false),
          TimeSlot(time: '19:00 - 20:00', isAvailable: true),
          TimeSlot(time: '20:00 - 21:00', isAvailable: true),
        ],
      ),
      SubCourt(
        name: 'Sân 7 người (VIP)',
        slots: [
          TimeSlot(time: '17:00 - 18:30', isAvailable: true),
          TimeSlot(time: '18:30 - 20:00', isAvailable: false),
          TimeSlot(time: '20:00 - 21:30', isAvailable: false),
        ],
      ),
    ],
  ),
  SportField(
    id: '2',
    name: 'Sân Cầu Lông Viettel',
    category: 'Cầu lông',
    price: '80.000đ / giờ',
    imageUrl:
        'https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?auto=format&fit=crop&q=80&w=800',
    address: 'Quận 10, TP.HCM',
    rating: 4.5,
    reviews: _mockReviews(),
    subCourts: [
      SubCourt(
        name: 'Sân 1 (Thảm Yonex)',
        slots: [
          TimeSlot(time: '17:00', isAvailable: true),
          TimeSlot(time: '18:00', isAvailable: false),
          TimeSlot(time: '19:00', isAvailable: false),
          TimeSlot(time: '20:00', isAvailable: true),
        ],
      ),
      SubCourt(
        name: 'Sân 2',
        slots: [
          TimeSlot(time: '17:00', isAvailable: false),
          TimeSlot(time: '18:00', isAvailable: false),
          TimeSlot(time: '19:00', isAvailable: false),
          TimeSlot(time: '20:00', isAvailable: false),
        ],
      ),
      SubCourt(
        name: 'Sân 3',
        slots: [
          TimeSlot(time: '17:00', isAvailable: true),
          TimeSlot(time: '18:00', isAvailable: true),
          TimeSlot(time: '19:00', isAvailable: true),
          TimeSlot(time: '20:00', isAvailable: true),
        ],
      ),
    ],
  ),
  SportField(
    id: '3',
    name: 'Cụm Tennis Kỳ Hòa',
    category: 'Tennis',
    price: '150.000đ / giờ',
    imageUrl:
        'https://images.unsplash.com/photo-1595435934249-5df7ed86e1c0?auto=format&fit=crop&q=80&w=800',
    address: 'Quận 10, TP.HCM',
    rating: 4.9,
    reviews: _mockReviews(),
    subCourts: [
      SubCourt(
        name: 'Sân Đất nện',
        slots: [
          TimeSlot(time: '06:00 - 08:00', isAvailable: false),
          TimeSlot(time: '16:00 - 18:00', isAvailable: true),
          TimeSlot(time: '18:00 - 20:00', isAvailable: false),
        ],
      ),
      SubCourt(
        name: 'Sân Cứng',
        slots: [
          TimeSlot(time: '06:00 - 08:00', isAvailable: true),
          TimeSlot(time: '16:00 - 18:00', isAvailable: true),
          TimeSlot(time: '18:00 - 20:00', isAvailable: true),
        ],
      ),
    ],
  ),
  SportField(
    id: '4',
    name: 'Nhà thi đấu Bóng Rổ SSA',
    category: 'Bóng rổ',
    price: '300.000đ / giờ',
    imageUrl:
        'https://images.unsplash.com/photo-1505666287802-931dc83948e9?auto=format&fit=crop&q=80&w=800',
    address: 'Quận 2, TP.HCM',
    rating: 4.7,
    reviews: _mockReviews(),
    subCourts: [
      SubCourt(
        name: 'Full Court (Trong nhà)',
        slots: [
          TimeSlot(time: '15:00 - 17:00', isAvailable: true),
          TimeSlot(time: '17:00 - 19:00', isAvailable: false),
          TimeSlot(time: '19:00 - 21:00', isAvailable: false),
        ],
      ),
    ],
  ),
];

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/sport_field.dart';
import '../services/field_service.dart';
import '../services/review_service.dart';
import 'payment_screen.dart';

class DetailScreen extends StatefulWidget {
  final SportField field;

  const DetailScreen({super.key, required this.field});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  String? selectedCourtName;
  String? selectedTime;
  final ReviewService _reviewService = ReviewService();
  double _currentRating = 0.0;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
  _ratingSubscription;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.field.rating;

    _ratingSubscription = FirebaseFirestore.instance
        .collection('sport_fields')
        .doc(widget.field.id)
        .snapshots()
        .listen((doc) {
      if (doc.exists && mounted) {
        setState(() {
          _currentRating = (doc.data()?['rating'] ?? widget.field.rating).toDouble();
        });
      }
    });
  }

  @override
  void dispose() {
    _ratingSubscription?.cancel();
    super.dispose();
  }

  /// TỐI ƯU HÓA: Bộ lọc xử lý ảnh ĐỘNG 100% cho mọi tài khoản hệ thống (Không viết cứng)
  ImageProvider? _buildAvatarImage(String avatarUrl) {
    if (avatarUrl.isEmpty) return null;

    // 1. Nếu là ảnh Base64 (Ảnh do user chụp camera hoặc chọn từ gallery máy)
    if (avatarUrl.startsWith('data:image')) {
      try {
        final base64Str = avatarUrl.split(',').last;
        return MemoryImage(base64Decode(base64Str));
      } catch (e) {
        debugPrint('❌ Lỗi decode base64 avatar: $e');
        return null;
      }
    }

    // 2. Nếu là ảnh Asset / Hệ thống (Tên file cục bộ hoặc bắt đầu bằng assets/)
    if (avatarUrl.startsWith('assets/') || !avatarUrl.startsWith('http')) {
      if (!avatarUrl.startsWith('assets/')) {
        return AssetImage('assets/images/$avatarUrl');
      }
      return AssetImage(avatarUrl);
    }

    // 3. Nếu là đường dẫn URL mạng internet (http/https)
    return NetworkImage(avatarUrl);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tổng cộng',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  Text(
                    selectedTime != null ? widget.field.price : 'Chưa chọn giờ',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  backgroundColor: selectedTime != null
                      ? Colors.green[600]
                      : Colors.grey[300],
                  foregroundColor: selectedTime != null
                      ? Colors.white
                      : Colors.grey[600],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: selectedTime != null ? 2 : 0,
                ),
                onPressed: selectedTime != null
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PaymentScreen(
                              field: widget.field,
                              courtName: selectedCourtName!,
                              time: selectedTime!,
                            ),
                          ),
                        );
                      }
                    : null,
                child: const Text(
                  'TIẾP TỤC',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  PageView.builder(
                    itemCount: 3, // Mockup 3 ảnh
                    itemBuilder: (context, index) {
                      return Image.network(
                        widget.field.imageUrl,
                        fit: BoxFit.cover,
                      );
                    },
                  ),
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '1/3',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.black45,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.field.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _currentRating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.brown,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.grey,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.field.address,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            InkWell(
                              onTap: () {
                                // Logic mở map
                              },
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.map_outlined,
                                    color: Colors.blue,
                                    size: 16,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Xem trên bản đồ (Google Maps)',
                                    style: TextStyle(
                                      color: Colors.blue,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32, thickness: 1),

                  // Chú thích trạng thái
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildLegend(Colors.white, Colors.green, 'Trống'),
                      _buildLegend(
                        Colors.green[600]!,
                        Colors.green[600]!,
                        'Đang chọn',
                      ),
                      _buildLegend(
                        Colors.grey[200]!,
                        Colors.transparent,
                        'Kín sân',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Lịch ngày hôm nay',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Danh sách sân và khung giờ
                  ListView.builder(
                    padding: EdgeInsets.zero,
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: widget.field.subCourts.length,
                    itemBuilder: (context, index) {
                      final court = widget.field.subCourts[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '📌 ${court.name}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 12),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    childAspectRatio: 2.5,
                                    crossAxisSpacing: 10,
                                    mainAxisSpacing: 10,
                                  ),
                              itemCount: court.slots.length,
                              itemBuilder: (context, slotIndex) {
                                final slot = court.slots[slotIndex];
                                bool isSelected =
                                    selectedCourtName == court.name &&
                                    selectedTime == slot.time;

                                return InkWell(
                                  onTap: slot.isAvailable
                                      ? () {
                                          setState(() {
                                            selectedCourtName = court.name;
                                            selectedTime = slot.time;
                                          });
                                        }
                                      : null,
                                  child: Container(
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: slot.isAvailable
                                          ? (isSelected
                                                ? Colors.green[600]
                                                : Colors.white)
                                          : Colors.grey[200],
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: slot.isAvailable
                                            ? (isSelected
                                                  ? Colors.green[600]!
                                                  : Colors.green[300]!)
                                            : Colors.grey[300]!,
                                      ),
                                    ),
                                    child: Text(
                                      slot.time,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: slot.isAvailable
                                            ? (isSelected
                                                  ? Colors.white
                                                  : Colors.green[800])
                                            : Colors.grey[500],
                                        fontWeight: FontWeight.bold,
                                        decoration: slot.isAvailable
                                            ? TextDecoration.none
                                            : TextDecoration.lineThrough,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const Divider(height: 40, thickness: 1),

                  // Đánh giá của khách hàng
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Đánh giá từ khách hàng',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // Nút viết đánh giá (chỉ hiện nếu chưa đánh giá)
                      StreamBuilder<bool>(
                        stream: _reviewService.hasUserReviewed(widget.field.id),
                        builder: (context, snapshot) {
                          final hasReviewed = snapshot.data ?? false;
                          if (hasReviewed) return const SizedBox.shrink();
                          return TextButton.icon(
                            onPressed: () => _showReviewDialog(),
                            icon: const Icon(Icons.rate_review, size: 18),
                            label: const Text('Viết đánh giá'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.green[700],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  StreamBuilder<List<Review>>(
                    stream: _reviewService.getReviews(widget.field.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final reviews = snapshot.data ?? [];

                      if (reviews.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.reviews_outlined,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Chưa có đánh giá nào.\nHãy là người đầu tiên đánh giá!',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: EdgeInsets.zero,
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: reviews.length,
                        itemBuilder: (context, index) {
                          final review = reviews[index];
                          return _buildReviewCard(review);
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Review review) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isLiked = review.likes.contains(currentUserId);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(review.userId)
                  .get(),
              builder: (context, userSnapshot) {
                String dynamicAvatarUrl = '';
                String dynamicUserName = review.userName;

                if (userSnapshot.hasData && userSnapshot.data!.exists) {
                  final uData =
                      userSnapshot.data!.data() as Map<String, dynamic>?;
                  dynamicAvatarUrl = uData?['avatar'] ?? '';
                  dynamicUserName = uData?['name'] ?? review.userName;
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundImage: _buildAvatarImage(dynamicAvatarUrl),
                      onForegroundImageError: (exception, stackTrace) {
                        debugPrint('⚠️ Không thể load avatar: $exception');
                      },
                      backgroundColor: Colors.green[100],
                      radius: 20,
                      child: dynamicAvatarUrl.isEmpty
                          ? Text(
                              dynamicUserName.isNotEmpty
                                  ? dynamicUserName[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                color: Colors.green[800],
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  dynamicUserName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                _formatDate(review.date),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: List.generate(5, (starIndex) {
                              return Icon(
                                starIndex < review.rating
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.amber,
                                size: 14,
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 10),
            Text(
              review.comment,
              style: const TextStyle(color: Colors.black87, height: 1.4),
            ),
            const SizedBox(height: 8),
            // Nút Like
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                InkWell(
                  onTap: () {
                    _reviewService.toggleLike(widget.field.id, review.id);
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          size: 18,
                          color: isLiked ? Colors.red : Colors.grey,
                        ),
                        if (review.likes.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          Text(
                            '${review.likes.length}',
                            style: TextStyle(
                              fontSize: 13,
                              color: isLiked ? Colors.red : Colors.grey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _showReviewDialog() {
    double selectedRating = 5.0;
    final commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Viết đánh giá',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.field.name,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 20),
                  // Star rating
                  const Text(
                    'Đánh giá của bạn:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return GestureDetector(
                        onTap: () {
                          setModalState(() {
                            selectedRating = index + 1.0;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            index < selectedRating
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                            size: 40,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  // Comment
                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Chia sẻ trải nghiệm của bạn...',
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        if (commentController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Vui lòng nhập nội dung đánh giá!'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                          return;
                        }

                        final navigator = Navigator.of(context);
                        final messenger = ScaffoldMessenger.of(context);
                        navigator.pop();

                        final success = await _reviewService.addReview(
                          fieldId: widget.field.id,
                          rating: selectedRating,
                          comment: commentController.text.trim(),
                        );

                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? 'Cảm ơn bạn đã đánh giá!'
                                  : 'Bạn đã đánh giá sân này rồi.',
                            ),
                            backgroundColor: success
                                ? Colors.green
                                : Colors.orange,
                          ),
                        );
                      },
                      child: const Text(
                        'GỬI ĐÁNH GIÁ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLegend(Color bgColor, Color borderColor, String text) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: bgColor,
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 13, color: Colors.black87)),
      ],
    );
  }
}

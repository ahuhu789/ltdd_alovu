import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/sport_field.dart';
import '../services/field_service.dart';
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
  List<Review> _reviews = [];
  double _currentRating = 0.0;
  final FieldService _fieldService = FieldService();

  @override
  void initState() {
    super.initState();
    _reviews = List.from(widget.field.reviews);
    _currentRating = widget.field.rating;
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
                              '${_currentRating.toStringAsFixed(1)}',
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
                      TextButton.icon(
                        onPressed: () => _showReviewBottomSheet(context),
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Viết đánh giá'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  ListView.builder(
                    padding: EdgeInsets.zero,
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: _reviews.length,
                    itemBuilder: (context, index) {
                      final review = _reviews[index];
                      final currentUser = FirebaseAuth.instance.currentUser;
                      final isLiked =
                          currentUser != null &&
                          review.likedBy.contains(currentUser.uid);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              backgroundImage: review.avatarUrl.isNotEmpty
                                  ? NetworkImage(review.avatarUrl)
                                  : null,
                              backgroundColor: Colors.grey[300],
                              radius: 20,
                              child: review.avatarUrl.isEmpty
                                  ? const Icon(Icons.person, color: Colors.grey)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        review.userName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        review.date,
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
                                  const SizedBox(height: 8),
                                  Text(
                                    review.comment,
                                    style: const TextStyle(
                                      color: Colors.black87,
                                    ),
                                  ),
                                  // Nút chức năng Like
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      InkWell(
                                        onTap: () => _toggleLike(review),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 4.0,
                                            horizontal: 8.0,
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                isLiked
                                                    ? Icons.thumb_up
                                                    : Icons
                                                          .thumb_up_alt_outlined,
                                                size: 14,
                                                color: isLiked
                                                    ? Colors.blue
                                                    : Colors.grey,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${review.likedBy.length}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: isLiked
                                                      ? Colors.blue
                                                      : Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
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

  void _showReviewBottomSheet(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để đánh giá')),
      );
      return;
    }

    if (_reviews.any((r) => r.userId == user.uid)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn đã đánh giá sân này rồi!')),
      );
      return;
    }

    double selectedRating = 5.0;
    final commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Đánh giá của bạn',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              StatefulBuilder(
                builder: (context, setModalState) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < selectedRating
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 32,
                        ),
                        onPressed: () {
                          setModalState(() {
                            selectedRating = index + 1.0;
                          });
                        },
                      );
                    }),
                  );
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Nhập chia sẻ của bạn về sân này...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
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
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    if (commentController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Vui lòng nhập nội dung!'),
                        ),
                      );
                      return;
                    }
                    Navigator.pop(context); // Đóng modal

                    final now = DateTime.now();
                    final formattedDate = DateFormat(
                      'dd/MM/yyyy HH:mm',
                    ).format(now);
                    final newReview = Review(
                      userId: user.uid,
                      userName: user.displayName ?? 'Khách',
                      avatarUrl: user.photoURL ?? '',
                      rating: selectedRating,
                      comment: commentController.text.trim(),
                      date: formattedDate,
                    );

                    try {
                      await _fieldService.addReview(widget.field.id, newReview);

                      setState(() {
                        _reviews.add(newReview);
                        // Tính lại rating local
                        double sum = 0;
                        for (var r in _reviews) {
                          sum += r.rating;
                        }
                        _currentRating = sum / _reviews.length;
                      });

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Cảm ơn bạn đã đánh giá!'),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(e.toString())));
                      }
                    }
                  },
                  child: const Text(
                    'GỬI ĐÁNH GIÁ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Future<void> _toggleLike(Review review) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để thích')),
      );
      return;
    }

    try {
      await _fieldService.toggleReviewLike(
        widget.field.id,
        review.userId,
        user.uid,
      );

      setState(() {
        if (review.likedBy.contains(user.uid)) {
          review.likedBy.remove(user.uid);
        } else {
          review.likedBy.add(user.uid);
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }
}

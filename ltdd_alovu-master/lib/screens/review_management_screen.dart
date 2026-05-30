import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewManagementScreen extends StatefulWidget {
  const ReviewManagementScreen({super.key});

  @override
  State<ReviewManagementScreen> createState() => _ReviewManagementScreenState();
}

class _ReviewManagementScreenState extends State<ReviewManagementScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Quản lý Đánh giá', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.green,
        elevation: 0.5,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // QUAN TRỌNG: Lấy dữ liệu từ bảng chứa các sân (ví dụ là 'fields')
        stream: FirebaseFirestore.instance.collection('sport_fields').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('Lỗi kết nối!'));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          // Gom tất cả đánh giá từ tất cả các sân vào một danh sách duy nhất
          List<Map<String, dynamic>> allReviews = [];
          double totalStars = 0;

          for (var fieldDoc in snapshot.data!.docs) {
            final fieldData = fieldDoc.data() as Map<String, dynamic>;
            final String fieldName = fieldData['name'] ?? 'Sân chưa đặt tên';
            final String fieldId = fieldDoc.id;

            // Lấy mảng reviews từ trong document sân
            List<dynamic> reviewsArray = fieldData['reviews'] ?? [];

            for (var r in reviewsArray) {
              Map<String, dynamic> review = Map<String, dynamic>.from(r);
              // Thêm thông tin sân vào để Admin biết đánh giá này của sân nào
              review['fieldName'] = fieldName;
              review['fieldId'] = fieldId;
              review['originalReview'] = r; // Giữ bản gốc để xóa sau này

              allReviews.add(review);
              totalStars += (review['rating'] ?? 0).toDouble();
            }
          }

          if (allReviews.isEmpty) {
            return const Center(child: Text('Chưa có đánh giá nào được tìm thấy.'));
          }

          double averageRating = totalStars / allReviews.length;

          return Column(
            children: [
              _buildQualityWarning(averageRating),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: allReviews.length,
                  itemBuilder: (context, index) {
                    return _buildReviewCard(allReviews[index]);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Widget hiển thị cảnh báo
  Widget _buildQualityWarning(double avg) {
    bool isLow = avg < 3.0;
    final Color primaryColor = isLow ? Colors.red.shade700 : Colors.green.shade700;
    final Color backgroundColor = isLow ? Colors.red.shade50 : Colors.green.shade50;
    final Color borderColor = isLow ? Colors.red.shade200 : Colors.green.shade200;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isLow ? Icons.report_problem_rounded : Icons.auto_awesome_rounded,
              color: primaryColor,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isLow ? 'Cảnh báo chất lượng' : 'Chất lượng tốt',
                  style: TextStyle(
                    fontSize: 14,
                    color: primaryColor.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Trung bình: ${avg.toStringAsFixed(1)} / 5.0 sao',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget hiển thị thẻ đánh giá
  Widget _buildReviewCard(Map<String, dynamic> review) {
    int star = (review['rating'] ?? 0).toInt();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundImage: review['avatarUrl'] != null && review['avatarUrl'] != ""
                    ? NetworkImage(review['avatarUrl'])
                    : null,
                child: review['avatarUrl'] == null || review['avatarUrl'] == ""
                    ? Text(review['userName']?[0] ?? 'U')
                    : null,
              ),
              title: Text(review['userName'] ?? 'Người dùng', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(review['fieldName'], style: const TextStyle(fontSize: 12, color: Colors.blue)),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: () => _confirmDelete(review['fieldId'], review['originalReview']),
              ),
            ),
            const Divider(),
            Row(children: [
              ...List.generate(5, (i) => Icon(i < star ? Icons.star_rounded : Icons.star_outline_rounded, color: Colors.amber, size: 20)),
              const SizedBox(width: 8),
              Text(review['date'] ?? ''),
            ]),
            const SizedBox(height: 8),
            Text(review['comment'] ?? '', style: const TextStyle(color: Colors.black87)),
          ],
        ),
      ),
    );
  }

  // Hàm xóa đánh giá (Vì là mảng nên phải dùng arrayRemove)
  void _confirmDelete(String fieldId, dynamic reviewObj) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa đánh giá?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('sport_fields').doc(fieldId).update({
                'reviews': FieldValue.arrayRemove([reviewObj])
              });
              Navigator.pop(context);
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
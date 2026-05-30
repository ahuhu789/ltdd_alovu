import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ltdd_alovu/screens/review_management_screen.dart';
import 'package:ltdd_alovu/screens/user_management_screen.dart';
import '../services/field_service.dart';
import '../models/sport_field.dart';
import 'field_management_screen.dart';
import 'booking_management_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ltdd_alovu/screens/static_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});
  DateTime _getStartOfToday() {
    DateTime now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  double _parsePrice(String priceString) {
    try {
      String cleaned = priceString.replaceAll(RegExp(r'[^0-9]'), '');
      return double.parse(cleaned);
    } catch (e) {
      return 0.0;
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Trang Quản Trị', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tổng quan hôm nay', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('bookings')
                  .where('createdAt', isGreaterThanOrEqualTo: _getStartOfToday())
                  .snapshots(),
              builder: (context, snapshot) {
                double revenue = 0;
                int newOrders = 0;

                if (snapshot.hasData) {
                  final docs = snapshot.data!.docs;
                  newOrders = docs.length;

                  for (var doc in docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    String status = (data['status'] ?? '').toString().toLowerCase();

                    if (status == 'completed' || status == 'success') {
                      revenue += _parsePrice(data['totalAmount'] ?? "0");
                    }
                  }
                }

                return Column(
                  children: [
                    Row(
                      children: [
                        _buildStatCard(
                            'Doanh thu', NumberFormat.compactCurrency(locale: 'vi_VN', symbol: '₫').format(revenue),
                            Icons.monetization_on,
                            Colors.green
                        ),
                        const SizedBox(width: 16),
                        _buildStatCard('Đơn mới', '$newOrders', Icons.shopping_cart, Colors.blue),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance.collection('users').snapshots(),
                            builder: (context, userSnap) {
                              return _buildStatCard(
                                  'Người dùng',
                                  userSnap.hasData ? '${userSnap.data!.docs.length}' : '...',
                                  Icons.people,
                                  Colors.orange
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance.collection('sport_fields').snapshots(),
                            builder: (context, fieldSnap) {
                              return _buildStatCard(
                                  'Sân bãi',
                                  fieldSnap.hasData ? '${fieldSnap.data!.docs.length}' : '...',
                                  Icons.stadium,
                                  Colors.purple
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),

            const Text('Công cụ Quản lý', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildAdminMenu(context, 'Quản lý Sân bãi', Icons.edit_location_alt, Colors.blue, () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const FieldManagementScreen()));
            }),
            _buildAdminMenu(context, 'Quản lý Đặt sân', Icons.calendar_month, Colors.green, () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const BookingManagementScreen()));
            }),
            _buildAdminMenu(context, 'Quản lý Người dùng', Icons.person_search, Colors.orange, () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const UserManagementScreen()));
            }),
            _buildAdminMenu(context, 'Quản lý Đánh giá', Icons.reviews_rounded, Colors.purple, () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ReviewManagementScreen()));
            }),

            const SizedBox(height: 32),

            _buildGlobalQualityReport(),

            const SizedBox(height: 24),

          ],
        ),
      ),
    );
  }

  Widget _buildGlobalQualityReport() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('sport_fields').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox();
        }

        double totalStars = 0;
        int totalReviews = 0;

        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          List<dynamic> reviews = data['reviews'] ?? [];

          for (var r in reviews) {
            totalStars += (r['rating'] ?? 0).toDouble();
            totalReviews++;
          }
        }

        if (totalReviews == 0) return const SizedBox();

        double averageRating = totalStars / totalReviews;
        bool isLowQuality = averageRating < 3.0;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isLowQuality ? Colors.red.shade50 : Colors.green.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isLowQuality ? Colors.red.shade200 : Colors.green.shade200,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isLowQuality ? Icons.warning_amber_rounded : Icons.verified_user_rounded,
                color: isLowQuality ? Colors.red : Colors.green,
                size: 30,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isLowQuality ? 'CẢNH BÁO CHẤT LƯỢNG SÂN BÃI' : 'CHẤT LƯỢNG SÂN BÃI TỐT',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isLowQuality ? Colors.red.shade800 : Colors.green.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rating trung bình: ${averageRating.toStringAsFixed(1)} / 5.0 (Dựa trên $totalReviews đánh giá)',
                      style: TextStyle(
                        color: isLowQuality ? Colors.red.shade600 : Colors.green.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 16),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminMenu(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      ),
    );
  }
}
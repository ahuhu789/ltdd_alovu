import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shimmer/shimmer.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _selectedFilter = 'Tất cả';
// ================= STATUS MAPPING =================
  String normalizeStatus(String status) {
    final s = status.toLowerCase().trim();
    if (s == 'pending' || s == 'success' || s == 'đã đặt') {
      return 'Đã đặt';
    }

    if (s == 'completed' || s == 'đã chơi') {
      return 'Đã chơi';
    }

    if (s == 'cancelled' || s == 'đã hủy') {
      return 'Đã hủy';
    }

    return 'Đã đặt';
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'Đã đặt':
        return Colors.orange;
      case 'Đã chơi':
        return Colors.green;
      case 'Đã hủy':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData getStatusIcon(String status) {
    switch (status) {
      case 'Đã đặt':
        return Icons.access_time;
      case 'Đã chơi':
        return Icons.check_circle;
      case 'Đã hủy':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }
  // =================================================

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Lịch sử đặt sân',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: _buildFilterBar(),
        ),
      ),
      body: user == null
          ? const Center(child: Text('Vui lòng đăng nhập để xem lịch sử.'))
          : StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('userId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Đã có lỗi xảy ra.'));
          }

          if (!snapshot.hasData) {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 4,
              itemBuilder: (context, index) =>
                  _buildHistorySkeleton(),
            );
          }

          final bookings = snapshot.data!.docs
              .map((doc) => doc.data() as Map<String, dynamic>)
              .toList();

          bookings.sort((a, b) {
            if (a['createdAt'] == null ||
                b['createdAt'] == null) return 0;
            return (b['createdAt'] as Timestamp)
                .compareTo(a['createdAt'] as Timestamp);
          });

          // ================= FILTER FIX =================
          final filteredBookings = _selectedFilter == 'Tất cả'
              ? bookings
              : bookings.where((b) {
            final rawStatus = b['status'] ?? 'pending';
            final status = normalizeStatus(rawStatus);
            return status == _selectedFilter;
          }).toList();

          if (filteredBookings.isEmpty) {
            return const Center(
              child: Text('Không tìm thấy lịch sử phù hợp.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredBookings.length,
            itemBuilder: (context, index) {
              final booking = filteredBookings[index];

              final fieldName =
                  booking['fieldName'] ?? 'Sân bãi';
              final courtName =
                  booking['courtName'] ?? '';
              final time = booking['time'] ?? '';

              final rawStatus =
                  booking['status'] ?? 'pending';
              final status = normalizeStatus(rawStatus);

              return Card(
                margin:
                const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(12),
                ),
                elevation: 2,
                child: Padding(
                  padding:
                  const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        fieldName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      _buildInfoRow(
                        Icons.calendar_today,
                        'Thời gian',
                        time,
                      ),
                      _buildInfoRow(
                        Icons.pin_drop,
                        'Sân bãi',
                        courtName,
                      ),

                      const Divider(height: 24),

                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment
                            .spaceBetween,
                        children: [
                          _buildStatusChip(status),

                          if (status ==
                              'Đã chơi' ||
                              status ==
                                  'Đã hủy')
                            ElevatedButton(
                              onPressed: () {},
                              style:
                              ElevatedButton
                                  .styleFrom(
                                backgroundColor:
                                Colors
                                    .blue[50],
                                foregroundColor:
                                Colors.blue,
                                elevation: 0,
                              ),
                              child: const Text(
                                  'ĐẶT LẠI'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ================= FILTER =================
  Widget _buildFilterBar() {
    final filters = [
      'Tất cả',
      'Đã đặt',
      'Đã chơi',
      'Đã hủy'
    ];

    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 8),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected =
              _selectedFilter == filter;

          return Padding(
            padding:
            const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (val) =>
                  setState(() =>
                  _selectedFilter = filter),
              selectedColor:
              Colors.green[600],
              labelStyle: TextStyle(
                color: isSelected
                    ? Colors.white
                    : Colors.black,
              ),
            ),
          );
        },
      ),
    );
  }

  // ================= INFO =================
  Widget _buildInfoRow(
      IconData icon, String label, String value) {
    return Padding(
      padding:
      const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon,
              size: 14,
              color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13),
          ),
          Text(
            value,
            style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ================= STATUS CHIP =================
  Widget _buildStatusChip(String status) {
    final color = getStatusColor(status);
    final icon = getStatusIcon(status);

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius:
        BorderRadius.circular(20),
        border: Border.all(
            color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight:
              FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ================= SKELETON =================
  Widget _buildHistorySkeleton() {
    return Card(
      margin:
      const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius:
        BorderRadius.circular(12),
        side: BorderSide(
            color: Colors.grey[200]!),
      ),
      elevation: 0,
      child: Padding(
        padding:
        const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor:
              Colors.grey[100]!,
              child: Container(
                  height: 20,
                  width: 150,
                  color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
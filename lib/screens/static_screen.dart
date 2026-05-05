import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  String _timeRange = 'Tháng';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }
  DateTime _getStartTime() {
    DateTime now = DateTime.now();
    if (_timeRange == 'Tuần') return now.subtract(Duration(days: now.weekday - 1));
    if (_timeRange == 'Tháng') return DateTime(now.year, now.month, 1);
    return DateTime(now.year, 1, 1);
  }
  double _parsePrice(String priceString) {
    try {
      String cleaned = priceString.replaceAll(RegExp(r'[^0-9]'), '');
      return double.parse(cleaned);
    } catch (e) {
      return 0.0;
    }
  }
  String _translateStatus(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'Đã chơi';
      case 'success':
        return 'Đặt thành công';
      case 'cancelled':
      case 'đã hủy':
        return 'Đã hủy';
      default:
        return 'Chưa xác định';
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Thống kê hệ thống', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.green,
        elevation: 0.5,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list_rounded),
            onSelected: (value) => setState(() => _timeRange = value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'Tuần', child: Text('Theo Tuần')),
              const PopupMenuItem(value: 'Tháng', child: Text('Theo Tháng')),
              const PopupMenuItem(value: 'Năm', child: Text('Theo Năm')),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.green,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.green,
          tabs: const [
            Tab(text: 'Doanh thu'),
            Tab(text: 'Sân & Thể thao'),
            Tab(text: 'Khách hàng'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRevenueTab(),
          _buildFieldAndSportTab(),
          _buildCustomerTab(),
        ],
      ),
    );
  }
  Widget _buildRevenueTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('createdAt', isGreaterThanOrEqualTo: _getStartTime())
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text('Lỗi hệ thống!'));
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.green));
        }

        final docs = snapshot.data?.docs ?? [];
        double totalRevenue = 0;

        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          String currentStatus = (data['status'] ?? '').toString().toLowerCase();

          // LOGIC CHUẨN: Tính tiền cho cả 'completed' và 'success'
          if (currentStatus == 'completed' || currentStatus == 'success') {
            totalRevenue += _parsePrice(data['totalAmount'] ?? "0");
          }
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Thẻ Doanh thu tổng
              _buildStatCard(
                'Doanh thu thực tế $_timeRange',
                NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(totalRevenue),
                Icons.monetization_on_rounded,
                Colors.green,
              ),
              const SizedBox(height: 24),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Lịch sử dòng tiền',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
              ),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  String rawStatus = (data['status'] ?? '').toString();
                  String translatedStatus = _translateStatus(rawStatus);

                  bool isCompleted = rawStatus.toLowerCase() == 'completed';
                  bool isSuccess = rawStatus.toLowerCase() == 'success';
                  bool isCancelled = rawStatus.toLowerCase() == 'cancelled' || rawStatus == 'Đã hủy';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.purple.shade50),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isSuccess ? Colors.green.shade50 : (isCancelled ? Colors.red.shade50 : Colors.blue.shade50),
                        child: Icon(
                          isSuccess ? Icons.check_circle_rounded : (isCancelled ? Icons.cancel_rounded : Icons.calendar_today_rounded),
                          color: isSuccess ? Colors.green : (isCancelled ? Colors.red : Colors.blue),
                          size: 20,
                        ),
                      ),
                      title: Text(data['fieldName'] ?? 'Sân bãi', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Thời gian: ${data['time']}', style: const TextStyle(fontSize: 12)),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            data['totalAmount'].toString().split(' ').first,
                            style: TextStyle(
                              color: isCancelled ? Colors.red : Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              decoration: isCancelled ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            translatedStatus,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isSuccess ? Colors.green : (isCancelled ? Colors.red : Colors.blue),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
  Widget _buildFieldAndSportTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('createdAt', isGreaterThanOrEqualTo: _getStartTime())
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text('Lỗi tải dữ liệu'));
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.green));
        }

        final docs = snapshot.data?.docs ?? [];

        Map<String, int> fieldCounts = {};
        Map<String, int> sportCounts = {};

        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          String rawStatus = (data['status'] ?? '').toString().toLowerCase();

          if (rawStatus == 'completed' || rawStatus == 'success') {
            String fName = data['fieldName'] ?? 'Sân chưa xác định';
            fieldCounts[fName] = (fieldCounts[fName] ?? 0) + 1;

            String cate = data['category'] ?? '';

            if (cate.isEmpty) {
              String nameLower = fName.toLowerCase();
              if (nameLower.contains('bóng đá') || nameLower.contains('sân bóng')) {
                cate = 'Bóng đá';
              } else if (nameLower.contains('tennis')) {
                cate = 'Tennis';
              } else if (nameLower.contains('cầu lông')) {
                cate = 'Cầu lông';
              } else if (nameLower.contains('bóng rổ')) {
                cate = 'Bóng rổ';
              } else {
                cate = 'Khác';
              }
            }

            sportCounts[cate] = (sportCounts[cate] ?? 0) + 1;
          }
        }

        var sortedFields = fieldCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
        var sortedSports = sportCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionTitle('Thống kê Sân bãi'),
            if (sortedFields.isNotEmpty) ...[
              _buildRankingItem('Sân được đặt nhiều nhất', sortedFields.first.key,
                  '${sortedFields.first.value} lượt', Icons.trending_up, Colors.green),
              const SizedBox(height: 10),
              _buildRankingItem('Sân ít người đặt nhất', sortedFields.last.key,
                  '${sortedFields.last.value} lượt', Icons.trending_down, Colors.orange),
            ] else _buildEmptyState('sân bãi'),

            const SizedBox(height: 30),

            _buildSectionTitle('Thống kê Môn thể thao'),
            if (sortedSports.isNotEmpty) ...[
              _buildRankingItem('Môn chơi nhiều nhất', sortedSports.first.key,
                  '${sortedSports.first.value} lượt', _getSportIcon(sortedSports.first.key), Colors.green),
              const SizedBox(height: 10),
              _buildRankingItem('Môn chơi ít nhất', sortedSports.last.key,
                  '${sortedSports.last.value} lượt', _getSportIcon(sortedSports.last.key), Colors.orange),
            ] else _buildEmptyState('môn thể thao'),
          ],
        );
      },
    );
  }

  IconData _getSportIcon(String category) {
    switch (category.toLowerCase()) {
      case 'bóng đá': return Icons.sports_soccer;
      case 'tennis': return Icons.sports_tennis;
      case 'cầu lông': return Icons.sports_volleyball;
      case 'bóng rổ': return Icons.sports_basketball;
      default: return Icons.sports_score;
    }
  }

  Widget _buildEmptyState(String label) {
    return Center(child: Text('Chưa có dữ liệu $label trong thời gian này.',
        style: const TextStyle(color: Colors.grey, fontSize: 13)));
  }
  Widget _buildCustomerTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('createdAt', isGreaterThanOrEqualTo: _getStartTime())
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text('Lỗi tải bảng xếp hạng'));
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.purple));
        }

        final docs = snapshot.data?.docs ?? [];

        Map<String, Map<String, dynamic>> customerLeaderboard = {};

        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          String status = (data['status'] ?? '').toString().toLowerCase();

          if (status == 'completed' || status == 'success') {
            String uid = data['userId'] ?? '';
            if (uid.isEmpty) continue;

            double price = _parsePrice(data['totalAmount'] ?? "0");

            if (!customerLeaderboard.containsKey(uid)) {
              customerLeaderboard[uid] = {
                'bookingCount': 0,
                'totalSpent': 0.0,
              };
            }

            customerLeaderboard[uid]!['bookingCount'] += 1;
            customerLeaderboard[uid]!['totalSpent'] += price;
          }
        }

        var sortedRanking = customerLeaderboard.entries.toList()
          ..sort((a, b) => b.value['bookingCount'].compareTo(a.value['bookingCount']));

        if (sortedRanking.isEmpty) {
          return const Center(child: Text('Chưa có dữ liệu cho bảng xếp hạng.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sortedRanking.length > 10 ? 10 : sortedRanking.length,
          itemBuilder: (context, index) {
            final userId = sortedRanking[index].key;
            final stats = sortedRanking[index].value;

            return _buildCustomerRankingCard(
              rank: index + 1,
              userId: userId,
              bookings: stats['bookingCount'],
              amount: stats['totalSpent'],
            );
          },
        );
      },
    );
  }
  Widget _buildCustomerRankingCard({
    required int rank,
    required String userId,
    required int bookings,
    required double amount,
  }) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, userSnapshot) {
        String name = "Người dùng hệ thống";
        String phone = "Chưa cập nhật SĐT";
        String avatar = "";

        if (userSnapshot.hasData && userSnapshot.data!.exists) {
          final userData = userSnapshot.data!.data() as Map<String, dynamic>;
          name = userData['name'] ?? "Người dùng";
          phone = userData['phone'] ?? "Chưa cập nhật";
          avatar = userData['avatar'] ?? "";
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.purple.shade50),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: rank == 1 ? Colors.amber : (rank == 2 ? Colors.grey.shade400 : (rank == 3 ? Colors.brown.shade300 : Colors.purple.shade50)),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text('$rank', style: TextStyle(color: rank <= 3 ? Colors.white : Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ),
              const SizedBox(width: 12),

              CircleAvatar(
                radius: 22,
                backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
                backgroundColor: Colors.green.shade100,
                child: avatar.isEmpty ? Text(name[0].toUpperCase(), style: const TextStyle(color: Colors.green)) : null,
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.phone, size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(phone, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('$bookings lượt', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  Text(
                    NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(amount),
                    style: const TextStyle(fontSize: 11, color: Colors.green),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.green.shade100),
        boxShadow: [BoxShadow(color: Colors.purple.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 40),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.grey)),
              Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
    );
  }

  Widget _buildRankingItem(String title, String name, String stat, IconData icon, Color color) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade100)),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        subtitle: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
        trailing: Text(stat, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      ),
    );
  }

}
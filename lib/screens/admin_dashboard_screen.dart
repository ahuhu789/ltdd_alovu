import 'package:flutter/material.dart';
import '../services/field_service.dart';
import '../models/sport_field.dart';
import 'field_management_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tổng quan hôm nay', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatCard('Doanh thu', '2.5Mđ', Icons.monetization_on, Colors.green),
                const SizedBox(width: 16),
                _buildStatCard('Đơn mới', '12', Icons.shopping_cart, Colors.blue),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatCard('Người dùng', '150', Icons.people, Colors.orange),
                const SizedBox(width: 16),
                _buildStatCard('Sân bãi', '4', Icons.stadium, Colors.purple),
              ],
            ),
            const SizedBox(height: 32),
            const Text('Công cụ Quản lý', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildAdminMenu(context, 'Quản lý Sân bãi', Icons.edit_location_alt, Colors.blue, () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const FieldManagementScreen()));
            }),
            _buildAdminMenu(context, 'Quản lý Đơn hàng', Icons.calendar_month, Colors.green, () {}),
            _buildAdminMenu(context, 'Quản lý Người dùng', Icons.person_search, Colors.orange, () {}),
            _buildAdminMenu(context, 'Báo cáo Thống kê', Icons.bar_chart, Colors.red, () {}),
            
            const SizedBox(height: 32),
            const Text('Cảnh báo chất lượng (Rating < 3)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
            const SizedBox(height: 16),
            _buildWarningList(),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningList() {
    return StreamBuilder<List<SportField>>(
      stream: FieldService().getSportFields(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final lowRatedFields = snapshot.data!.where((f) => f.rating < 3.0).toList();
        
        if (lowRatedFields.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Tất cả sân đều đạt chất lượng tốt ✅', style: TextStyle(color: Colors.green)),
            ),
          );
        }

        return Column(
          children: lowRatedFields.map((field) => Card(
            child: ListTile(
              leading: const Icon(Icons.warning, color: Colors.red),
              title: Text(field.name),
              subtitle: Text('Đánh giá hiện tại: ${field.rating} ⭐'),
            ),
          )).toList(),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminMenu(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: color),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

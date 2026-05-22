import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/booking.dart';
import '../services/booking_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookingManagementScreen extends StatefulWidget {
  const BookingManagementScreen({super.key});

  @override
  State<BookingManagementScreen> createState() => _BookingManagementScreenState();
}

class _BookingManagementScreenState extends State<BookingManagementScreen> {
  final BookingService _bookingService = BookingService();
  String _selectedFilter = 'all';

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'success':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      case 'success':
      default:
        return Colors.green;
    }
  }

  String _translateStatus(String status) {
    switch (status.toLowerCase()) {
      case 'success':
        return 'Đặt thành công';
      case 'completed':
        return 'Đã chơi';
      case 'cancelled':
        return 'Đã hủy';
      case 'success':
      default:
        return 'Đặt thành công';
    }
  }

  Future<void> _executeCancel(BuildContext context, Booking booking, {required bool requireRefund}) async {
    Navigator.pop(context);
    Navigator.pop(context);

    try {
      await _bookingService.cancelBooking(booking, requireRefund: requireRefund);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(requireRefund ? 'Đã hủy đơn và ghi nhận CHỜ HOÀN TIỀN!' : 'Đã hủy đơn và trả sân thành công!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red));
    }
  }

  void _showCancelConfirmation(BuildContext context, Booking booking) {
    bool isOnlinePayment = booking.paymentMethod.toLowerCase() != 'tiền mặt' &&
        booking.paymentMethod.toLowerCase() != 'tại sân';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận Hủy Đơn', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bạn chắc chắn muốn hủy đơn đặt sân của ${booking.fieldName} lúc ${booking.time}?'),
            const SizedBox(height: 16),
            if (isOnlinePayment) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.orange.shade200)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                        SizedBox(width: 8),
                        Text('Lưu ý hoàn tiền', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Khách đã thanh toán qua ${booking.paymentMethod}. Vui lòng xác nhận có ghi nhận đơn này vào danh sách "Chờ hoàn tiền" không?',
                      style: TextStyle(color: Colors.orange.shade800, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng', style: TextStyle(color: Colors.grey))),
          if (isOnlinePayment)
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: () => _executeCancel(context, booking, requireRefund: true),
              child: const Text('Hủy & Chờ Hoàn Tiền', style: TextStyle(color: Colors.white)),
            ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => _executeCancel(context, booking, requireRefund: false),
            child: Text(isOnlinePayment ? 'Chỉ Hủy (Không hoàn)' : 'Xác nhận Hủy đơn', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showBookingDetails(BuildContext context, Booking booking) {
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(booking.createdAt);
    final statusClean = booking.status.toLowerCase().trim();
    final refundStatusClean = booking.refundStatus.toLowerCase().trim();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const Text('Chi tiết đơn đặt sân',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.purple)),
            const SizedBox(height: 24),

            // --- THÔNG TIN TÀI KHOẢN ĐẶT SÂN (LẤY TỪ USERID) ---
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(booking.userId).get(),
              builder: (context, snapshot) {
                String name = "Đang tải...";
                String phone = "Đang tải...";

                if (snapshot.hasData && snapshot.data!.exists) {
                  final userData = snapshot.data!.data() as Map<String, dynamic>;
                  name = userData['name'] ?? "Người dùng";
                  phone = userData['phone'] ?? "Chưa cập nhật SĐT";
                } else if (snapshot.hasError) {
                  name = "Lỗi tải tên";
                  phone = "Lỗi tải SĐT";
                }

                return Column(
                  children: [
                    _buildDetailRow(Icons.person, 'Người đặt:', name),
                    _buildDetailRow(Icons.phone, 'Số điện thoại:', phone),
                  ],
                );
              },
            ),

            const Divider(height: 32),

            // --- THÔNG TIN ĐƠN HÀNG ---
            _buildDetailRow(Icons.stadium, 'Sân bãi:', booking.fieldName),
            _buildDetailRow(Icons.sports, 'Khu vực:', booking.courtName),
            _buildDetailRow(Icons.access_time, 'Thời gian đá:', booking.time),
            _buildDetailRow(Icons.calendar_today, 'Ngày đặt:', dateStr),
            _buildDetailRow(Icons.payment, 'Thanh toán:', booking.paymentMethod),
            _buildDetailRow(Icons.monetization_on, 'Tổng tiền:', booking.totalAmount, color: Colors.green),

            const SizedBox(height: 32),

            // --- PHẦN XỬ LÝ NÚT BẤM (GIỮ NGUYÊN LOGIC CỦA BẠN) ---
            if (statusClean != 'success' && statusClean != 'cancelled' && statusClean != 'completed')
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _showCancelConfirmation(context, booking),
                      child: const Text('Hủy đơn', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.purple, // Đổi sang tím cho hợp gu
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        Navigator.pop(context);
                        try {
                          await _bookingService.markAsPlayed(booking.id);
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Đã xác nhận hoàn thành!'), backgroundColor: Colors.purple));
                        } catch (e) {
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red));
                        }
                      },
                      child: const Text('Đã chơi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              )
            else if (statusClean == 'cancelled' && refundStatusClean == 'pending_refund')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    Navigator.pop(context);
                    try {
                      await _bookingService.processRefund(booking.id);
                    } catch (e) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red));
                    }
                  },
                  label: const Text('Xác nhận Đã hoàn tiền', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              )
            else
              Center(
                child: Column(
                  children: [
                    Text(
                      'Đơn này ${_translateStatus(booking.status).toLowerCase()}',
                      style: TextStyle(color: _getStatusColor(booking.status), fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    if (refundStatusClean == 'refunded')
                      const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: Text('(Đã hoàn tiền đầy đủ)', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
                      )
                  ],
                ),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Quản lý Đặt sân', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.green,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildFilterChip('Tất cả', 'all'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Đặt thành công', 'success'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Đã chơi', 'completed'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Đã hủy', 'cancelled'),
                ],
              ),
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: StreamBuilder<List<Booking>>(
              stream: _bookingService.getAllBookings(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.green)); // Xanh lá
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState();
                }

                var bookings = snapshot.data!;
                if (_selectedFilter != 'all') {
                  bookings = bookings.where((b) => b.status == _selectedFilter).toList();
                }

                if (bookings.isEmpty) return _buildEmptyState();

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {
                    final booking = bookings[index];
                    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(booking.createdAt);

                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: InkWell(
                        onTap: () => _showBookingDetails(context, booking),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      booking.fieldName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      maxLines: 1, overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(booking.status).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      booking.refundStatus == 'pending_refund' ? 'Chờ hoàn tiền' : _translateStatus(booking.status),
                                      style: TextStyle(
                                        color: booking.refundStatus == 'pending_refund' ? Colors.orange : _getStatusColor(booking.status),
                                        fontWeight: FontWeight.bold, fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(Icons.access_time, size: 18, color: Colors.green[600]), // Icon xanh
                                  const SizedBox(width: 8),
                                  Text(booking.time, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                  const SizedBox(width: 24),
                                  const Icon(Icons.stadium, size: 18, color: Colors.orange),
                                  const SizedBox(width: 8),
                                  Text(booking.courtName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text(booking.totalAmount, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 15)),
                                  const Spacer(),
                                  Text(dateStr, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildDetailRow(IconData icon, String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.green[600]),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 15)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: color ?? Colors.black
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildFilterChip(String label, String filterValue) {
    final isSelected = _selectedFilter == filterValue;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        if (selected) setState(() { _selectedFilter = filterValue; });
      },
      selectedColor: Colors.green.withOpacity(0.15), // Xanh nhạt
      labelStyle: TextStyle(
        color: isSelected ? Colors.green[700] : Colors.grey[700], // Chữ xanh
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: Colors.grey[100],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_month_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('Chưa có dữ liệu.', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
        ],
      ),
    );
  }
}
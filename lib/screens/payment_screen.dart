import 'package:flutter/material.dart';
import '../models/sport_field.dart';
import '../services/booking_service.dart';
import 'main_dashboard.dart';

class PaymentScreen extends StatefulWidget {
  final SportField field;
  final String courtName;
  final String time;
  final String bookingDate;

  const PaymentScreen({
    super.key,
    required this.field,
    required this.courtName,
    required this.time,
    required this.bookingDate,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String selectedPaymentMethod = 'MOMO';

  int _parsePrice(String priceStr) {
    String cleaned = priceStr.toLowerCase()
        .replaceAll('k', '000')
        .replaceAll('.', '')
        .replaceAll(',', '')
        .replaceAll('đ', '')
        .replaceAll('vnd', '');
    String digits = cleaned.split('/').first.replaceAll(RegExp(r'\D'), '');
    return int.tryParse(digits) ?? 100000;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh toán', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green[600],
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
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
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.green[600],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Center(child: CircularProgressIndicator()),
              );

              final success = await BookingService().createBooking(
                field: widget.field,
                courtName: widget.courtName,
                time: widget.time,
                bookingDate: widget.bookingDate,
                paymentMethod: selectedPaymentMethod,
                totalAmount: widget.field.price,
              );

              if (context.mounted) Navigator.pop(context); // Tắt loading

              if (success) {
                if (context.mounted) {
                  // Hiển thị Dialog thành công và quay về Home
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 64,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Đặt sân thành công!',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Bạn đã đặt ${widget.courtName} lúc ${widget.time} ngày ${widget.bookingDate}. Vui lòng có mặt đúng giờ!',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[600],
                              ),
                              onPressed: () {
                                // Xóa toàn bộ stack và về màn hình chính
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                    builder: (context) => const MainDashboard(),
                                  ),
                                  (route) => false,
                                );
                              },
                              child: const Text(
                                'VỀ TRANG CHỦ',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đặt sân thất bại (Giờ này đã có người đặt). Vui lòng chọn giờ khác!'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  Navigator.pop(context); // Trở về trang Chọn Giờ
                }
              }
            },
            child: const Text(
              'XÁC NHẬN THANH TOÁN',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thông tin đơn hàng
            const Text(
              'Thông tin đặt sân',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          widget.field.imageUrl,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.field.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.courtName,
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '🕒 ${widget.time}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '📅 Ngày: ${widget.bookingDate}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tạm tính',
                        style: TextStyle(color: Colors.grey),
                      ),
                      Text(
                        widget.field.price,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Mã giảm giá',
                        style: TextStyle(color: Colors.grey),
                      ),
                      Text(
                        '- 0đ',
                        style: TextStyle(
                          color: Colors.green[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'TỔNG TIỀN',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.field.price,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Mã khuyến mãi
            TextField(
              decoration: InputDecoration(
                hintText: 'Nhập mã khuyến mãi (nếu có)',
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                suffixIcon: TextButton(
                  onPressed: () {},
                  child: const Text('ÁP DỤNG'),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Phương thức thanh toán
            const Text(
              'Phương thức thanh toán',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  _buildPaymentMethod(
                    'MOMO',
                    'Ví điện tử MoMo',
                    Icons.account_balance_wallet,
                    Colors.pink,
                  ),
                  const Divider(height: 1),
                  _buildPaymentMethod(
                    'VNPAY',
                    'VNPAY',
                    Icons.qr_code,
                    Colors.blue,
                  ),
                  const Divider(height: 1),
                  _buildPaymentMethod(
                    'BANK',
                    'Chuyển khoản VietQR',
                    Icons.account_balance,
                    Colors.indigo,
                  ),
                  const Divider(height: 1),
                  _buildPaymentMethod(
                    'CASH',
                    'Thanh toán tại sân',
                    Icons.money,
                    Colors.green,
                  ),
                ],
              ),
            ),
            if (selectedPaymentMethod == 'BANK') ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.indigo[100]!),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.indigo.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'Quét mã VietQR để thanh toán',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Ngân hàng: Vietcombank (VCB)\nSố tài khoản: 1234567890\nTên tài khoản: CONG TY TNHH ALOVU',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, height: 1.4, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey[200]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          'https://img.vietqr.io/image/vcb-1234567890-compact.png?amount=${_parsePrice(widget.field.price)}&addInfo=${Uri.encodeComponent("ALOVU ${widget.courtName.replaceAll(' ', '_')} ${widget.time.replaceAll(':', 'h').replaceAll(' ', '_')}")}',
                          width: 200,
                          height: 200,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 200,
                              height: 200,
                              color: Colors.grey[100],
                              alignment: Alignment.center,
                              child: const Text(
                                'Không thể tải mã QR\nVui lòng thử lại sau',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Số tiền: ${widget.field.price}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Nội dung chuyển khoản đã được tích hợp tự động vào mã QR.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethod(
    String value,
    String title,
    IconData icon,
    Color iconColor,
  ) {
    return RadioListTile<String>(
      value: value,
      groupValue: selectedPaymentMethod,
      activeColor: Colors.green[600],
      onChanged: (String? val) {
        if (val != null) setState(() => selectedPaymentMethod = val);
      },
      title: Row(
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

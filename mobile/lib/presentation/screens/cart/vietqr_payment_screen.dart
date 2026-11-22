import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';

class VietQrPaymentScreen extends StatefulWidget {
  final String contractCode;
  final double amount;
  final String unitName;
  final VoidCallback onPaymentCompleted;

  const VietQrPaymentScreen({
    super.key,
    required this.contractCode,
    required this.amount,
    required this.unitName,
    required this.onPaymentCompleted,
  });

  @override
  State<VietQrPaymentScreen> createState() => _VietQrPaymentScreenState();
}

class _VietQrPaymentScreenState extends State<VietQrPaymentScreen> {
  final bool _isConfirming = false;

  final String _bankName = 'MB Bank (Ngân hàng Quân Đội)';
  final String _accountNumber = '0901234567';
  final String _accountHolder = 'CONG TY THIET BI RENTAL VN';

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã sao chép $label: $text'),
        backgroundColor: AppColors.statusAvailable,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _confirmPayment() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Chờ đối soát chuyển khoản'),
        content: const Text(
          'Vui lòng liên hệ quản trị viên để xác nhận tiền đã vào tài khoản. Ứng dụng chưa kết nối dịch vụ kiểm tra giao dịch ngân hàng.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final qrUrl =
        'https://img.vietqr.io/image/MB-$_accountNumber-compact2.png'
        '?amount=${widget.amount.toInt()}'
        '&addInfo=${Uri.encodeComponent(widget.contractCode)}'
        '&accountName=${Uri.encodeComponent(_accountHolder)}';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Thanh toán Cọc qua VietQR'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // VietQR Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Logo Napas247 / VietQR banner
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF005BAA).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'VietQR • NAPAS 247',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF005BAA),
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.statusAvailable.withValues(
                            alpha: 0.15,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.bolt,
                              color: AppColors.statusAvailable,
                              size: 16,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Chuyển tiền tức thì',
                              style: TextStyle(
                                color: AppColors.statusAvailable,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Image VietQR
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Image.network(
                      qrUrl,
                      height: 260,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const SizedBox(
                          height: 260,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 260,
                          alignment: Alignment.center,
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.qr_code_2,
                                size: 100,
                                color: AppColors.primary,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Quét mã qua App Ngân hàng bất kỳ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    currencyFormat.format(widget.amount),
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tiền cọc hợp đồng: ${widget.contractCode}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Bank Information Details Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Thông tin chuyển khoản',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow('Ngân hàng', _bankName, null),
                  const Divider(height: 16),
                  _buildInfoRow(
                    'Số tài khoản',
                    _accountNumber,
                    () => _copyToClipboard(_accountNumber, 'Số tài khoản'),
                  ),
                  const Divider(height: 16),
                  _buildInfoRow('Chủ tài khoản', _accountHolder, null),
                  const Divider(height: 16),
                  _buildInfoRow(
                    'Số tiền',
                    currencyFormat.format(widget.amount),
                    null,
                  ),
                  const Divider(height: 16),
                  _buildInfoRow(
                    'Nội dung CK',
                    widget.contractCode,
                    () => _copyToClipboard(
                      widget.contractCode,
                      'Nội dung chuyển khoản',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Confirm payment button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isConfirming ? null : _confirmPayment,
                icon: _isConfirming
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: Text(
                  _isConfirming
                      ? 'Đang kiểm tra giao dịch...'
                      : 'Tôi đã chuyển khoản thành công',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.statusAvailable,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onPaymentCompleted();
              },
              child: const Text('Thanh toán sau (Lưu hợp đồng chờ cọc)'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, VoidCallback? onCopy) {
    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        if (onCopy != null)
          InkWell(
            onTap: onCopy,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                children: [
                  Icon(Icons.copy, size: 14, color: AppColors.primary),
                  SizedBox(width: 4),
                  Text(
                    'Chép',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

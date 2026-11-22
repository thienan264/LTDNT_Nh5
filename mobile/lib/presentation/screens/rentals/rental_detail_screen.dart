import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/repositories/rental_repository.dart';
import '../../../data/repositories/member_repository.dart';
import '../../../data/models/rental_model.dart';
import '../../widgets/signature_pad_dialog.dart';

class RentalDetailScreen extends StatefulWidget {
  final RentalModel rental;

  const RentalDetailScreen({super.key, required this.rental});

  @override
  State<RentalDetailScreen> createState() => _RentalDetailScreenState();
}

class _RentalDetailScreenState extends State<RentalDetailScreen> {
  late RentalStatus _currentStatus;
  DateTime? _actualEndDate;
  bool _isProcessing = false;
  late Future<List<Map<String, dynamic>>> _handoverLogsFuture;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.rental.status;
    _actualEndDate = widget.rental.actualEndDate;
    _loadLogs();
  }

  void _loadLogs() {
    setState(() {
      _handoverLogsFuture = RentalRepository.getHandoverLogs(widget.rental.id);
    });
  }

  void _openSignatureDialog(String logType) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => SignaturePadDialog(
        title: logType == 'DELIVERY'
            ? 'Biên bản Bàn giao Xuất kho'
            : 'Biên bản Thu hồi Nhập kho',
        logType: logType,
        defaultSignerName: widget.rental.contactPerson,
      ),
    );

    if (result != null) {
      setState(() => _isProcessing = true);
      final success = await RentalRepository.createHandoverLog(
        rentalId: widget.rental.id,
        logType: result['log_type'] as String,
        handledBy: result['handled_by'] as String,
        signerName: result['signer_name'] as String,
        signatureData: result['signature_data'] as String,
        notes: result['notes'] as String?,
      );
      setState(() => _isProcessing = false);

      if (!mounted) return;
      if (success) {
        if (logType == 'RETURN') {
          setState(() {
            _currentStatus = RentalStatus.returned;
            _actualEndDate = DateTime.now();
          });
        }
        if (logType == 'DELIVERY') {
          setState(() => _currentStatus = RentalStatus.active);
        }
        _loadLogs();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                logType == 'RETURN'
                    ? 'Đã lưu chữ ký thu hồi và hoàn tất hợp đồng!'
                    : 'Đã lưu chữ ký bàn giao thiết bị thành công!',
              ),
              backgroundColor: AppColors.statusAvailable,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Không lưu được biên bản. Kiểm tra trạng thái hợp đồng và kết nối.',
            ),
          ),
        );
      }
    }
  }

  Color _getStatusColor(RentalStatus status) {
    switch (status) {
      case RentalStatus.active:
        return AppColors.statusAvailable;
      case RentalStatus.approved:
      case RentalStatus.pending:
        return AppColors.statusRented;
      case RentalStatus.overdue:
        return AppColors.statusBroken;
      case RentalStatus.returned:
        return const Color(0xFF64748B); // Slate Gray
      case RentalStatus.cancelled:
        return Colors.red.shade400;
    }
  }

  void _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận Hủy Hợp đồng'),
        content: Text(
          'Bạn có chắc chắn muốn hủy hợp đồng "${widget.rental.contractCode}" ? Các thiết bị trong hợp đồng sẽ được hoàn trả về Kho.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusBroken,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hủy hợp đồng'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);
    final success = await RentalRepository.deleteRental(widget.rental.id);
    setState(() => _isProcessing = false);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã hủy hợp đồng thành công!'),
          backgroundColor: AppColors.statusAvailable,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không hủy được hợp đồng.'),
          backgroundColor: AppColors.statusBroken,
        ),
      );
    }
  }

  void _handleReturnRental() async {
    if (_currentStatus == RentalStatus.returned) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hợp đồng này đã được thu hồi và hoàn tất trước đó.'),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận Thu hồi thiết bị'),
        content: Text(
          'Bạn có chắc chắn muốn thu hồi toàn bộ thiết bị của hợp đồng "${widget.rental.contractCode}" về Kho tổng và đánh dấu hợp đồng đã hoàn thành?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D9488),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Đồng ý Thu hồi'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);
    final success = await RentalRepository.returnRental(widget.rental.id);
    setState(() => _isProcessing = false);

    if (!mounted) return;

    if (success) {
      setState(() {
        _currentStatus = RentalStatus.returned;
        _actualEndDate = DateTime.now();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Thành công: Đã thu hồi toàn bộ thiết bị về kho và đóng hợp đồng!',
          ),
          backgroundColor: AppColors.statusAvailable,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Có lỗi xảy ra khi thực hiện thu hồi hợp đồng.'),
          backgroundColor: AppColors.statusBroken,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
    );
    final dateFormatter = DateFormat('dd/MM/yyyy');
    final durationDays = widget.rental.expectedEndDate
        .difference(widget.rental.startDate)
        .inDays;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Chi tiết Hợp đồng Thuê'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        actions: [
          if (MemberRepository.isAdmin &&
              (_currentStatus == RentalStatus.pending ||
                  _currentStatus == RentalStatus.approved))
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: AppColors.statusBroken,
              ),
              tooltip: 'Hủy hợp đồng',
              onPressed: _handleDelete,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.rental.contractCode,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(_currentStatus)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _currentStatus.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(_currentStatus),
                          ),
                        ),
                      ),
                      if (widget.rental.isOverdue)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Quá hạn ${widget.rental.daysOverdue} ngày',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Tiền đặt cọc hợp đồng:',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Text(
                        currencyFormatter.format(widget.rental.totalDeposit),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  if (widget.rental.estimatedTotalCost > 0) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'Tiền thuê ước tính:',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Text(
                          currencyFormatter.format(
                            widget.rental.estimatedTotalCost,
                          ),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0D9488),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Unit Information
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
                  const Row(
                    children: [
                      Icon(
                        Icons.business_outlined,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Đơn vị / Khách hàng thuê',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.rental.unitName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          widget.rental.unitAddress,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Người liên hệ: ${widget.rental.contactPerson}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.phone_outlined,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Điện thoại: ${widget.rental.phoneNumber}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Time & Duration
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
                  const Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        color: AppColors.primary,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Thời hạn hợp đồng',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: _buildDateColumn(
                          'Ngày bắt đầu',
                          dateFormatter.format(widget.rental.startDate),
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward,
                        size: 18,
                        color: AppColors.textMuted,
                      ),
                      Expanded(
                        child: _buildDateColumn(
                          _currentStatus == RentalStatus.returned
                              ? 'Ngày đã thu hồi'
                              : 'Ngày dự kiến trả',
                          _actualEndDate != null
                              ? dateFormatter.format(_actualEndDate!)
                              : dateFormatter.format(
                                  widget.rental.expectedEndDate,
                                ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'Thời gian thuê theo thỏa thuận:',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        Text(
                          '$durationDays ngày',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Device List in Contract
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: const Row(
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Thiết bị trong hợp đồng',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${widget.rental.deviceNames.length} máy',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...widget.rental.deviceNames.asMap().entries.map((entry) {
                    final deviceName = entry.value;
                    final isReturned =
                        _currentStatus == RentalStatus.returned ||
                        (entry.key < widget.rental.deviceReturnDates.length &&
                            widget.rental.deviceReturnDates[entry.key] != null);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.white,
                            child: Icon(
                              isReturned
                                  ? Icons.warehouse_outlined
                                  : Icons.build_outlined,
                              size: 16,
                              color: isReturned
                                  ? AppColors.statusAvailable
                                  : AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  deviceName,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  isReturned
                                      ? 'Đã thu hồi về kho tổng'
                                      : 'Đang đặt tại đơn vị thuê',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isReturned
                                        ? AppColors.statusAvailable
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            isReturned ? Icons.check_circle : Icons.schedule,
                            size: 18,
                            color: isReturned
                                ? AppColors.statusAvailable
                                : AppColors.statusRented,
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Handover & Return Logs with Digital Signatures
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: const Row(
                          children: [
                            Icon(
                              Icons.draw_outlined,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Biên bản Bàn giao & Chữ ký',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (MemberRepository.isAdmin &&
                          _currentStatus == RentalStatus.approved)
                        TextButton.icon(
                          onPressed: _currentStatus == RentalStatus.approved
                              ? () => _openSignatureDialog('DELIVERY')
                              : null,
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text(
                            'Ký bàn giao',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _handoverLogsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final logs = snapshot.data ?? [];
                      if (logs.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(16),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Chưa có biên bản ký nhận nào được lưu.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: logs.map((log) {
                          final isReturn = log['log_type'] == 'RETURN';
                          final signData =
                              log['signature_data']?.toString() ?? '';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isReturn
                                    ? const Color(0xFF0D9488)
                                          .withValues(alpha: 0.3)
                                    : AppColors.border,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isReturn
                                            ? const Color(0xFF0D9488)
                                            : AppColors.primary,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        isReturn
                                            ? 'BIÊN BẢN THU HỒI NHẬP KHO'
                                            : 'BIÊN BẢN BÀN GIAO XUẤT KHO',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      log['created_at'] != null
                                          ? log['created_at']
                                                .toString()
                                                .substring(0, 10)
                                          : '',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Người ký đại diện: ${log['signer_name']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  'Người phụ trách: ${log['handled_by']}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                if (log['notes'] != null &&
                                    log['notes'].toString().isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Hiện trạng: ${log['notes']}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 8),
                                const Text(
                                  'Chữ ký xác nhận:',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                SignaturePreviewWidget(
                                  svgPath: signData,
                                  height: 90,
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Notes
            if (widget.rental.notes != null && widget.rental.notes!.isNotEmpty)
              Container(
                width: double.infinity,
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
                      'Ghi chú hợp đồng:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.rental.notes!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: _buildBottomAction(),
      ),
    );
  }

  Future<void> _approveRental() async {
    setState(() => _isProcessing = true);
    final success = await RentalRepository.updateStatus(
      widget.rental.id,
      'Approved',
    );
    if (!mounted) return;
    setState(() {
      _isProcessing = false;
      if (success) _currentStatus = RentalStatus.approved;
    });
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không duyệt được hợp đồng.')),
      );
    }
  }

  Widget _buildBottomAction() {
    if (!MemberRepository.isAdmin) {
      return Text(_currentStatus.label, textAlign: TextAlign.center);
    }
    if (_currentStatus == RentalStatus.cancelled) {
      return const Text('Hợp đồng đã hủy', textAlign: TextAlign.center);
    }
    if (_currentStatus == RentalStatus.pending) {
      return ElevatedButton(
        onPressed: _isProcessing ? null : _approveRental,
        child: const Text('Duyệt hợp đồng'),
      );
    }

    if (_isProcessing) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(8),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_currentStatus == RentalStatus.returned) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified, color: Colors.green.shade700, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Hợp đồng đã hoàn tất & đã thu hồi máy về kho',
                style: TextStyle(
                  color: Colors.green.shade800,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _currentStatus == RentalStatus.approved
                ? () => _openSignatureDialog('DELIVERY')
                : null,
            icon: const Icon(Icons.draw, size: 18),
            label: const Text('Ký Bàn giao'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: _currentStatus == RentalStatus.active
                ? () => _openSignatureDialog('RETURN')
                : null,
            icon: const Icon(Icons.assignment_turned_in_outlined),
            label: const Text('Ký biên bản Thu hồi máy'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D9488),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        IconButton(
          tooltip: 'Thu hồi nhanh không cần ký',
          icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
          onPressed: _currentStatus == RentalStatus.active
              ? _handleReturnRental
              : null,
        ),
      ],
    );
  }

  Widget _buildDateColumn(String label, String date) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        Text(
          date,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/repositories/device_repository.dart';
import '../../../data/repositories/unit_repository.dart';
import '../../../data/repositories/member_repository.dart';
import '../../../data/datasources/cart_service.dart';
import '../../../data/models/device_model.dart';
import '../../../data/models/unit_model.dart';
import '../../widgets/cart_badge_icon.dart';
import '../../widgets/device_card.dart';
import '../cart/cart_screen.dart';
import 'device_form_screen.dart';

class DeviceDetailScreen extends StatefulWidget {
  final DeviceModel device;

  const DeviceDetailScreen({super.key, required this.device});

  @override
  State<DeviceDetailScreen> createState() => _DeviceDetailScreenState();
}

class _DeviceDetailScreenState extends State<DeviceDetailScreen> {
  late DeviceStatus _currentStatus;
  String? _currentUnitName;
  late String _name;
  late String _serialNumber;
  late double _rentalPricePerDay;
  late String _categoryName;
  String? _imageUrl;
  bool _isProcessing = false;
  late Future<List<Map<String, dynamic>>> _historyFuture;

  // Sản phẩm liên quan (có phân trang)
  int _relatedPage = 1;
  int _relatedTotalPages = 1;
  int _relatedTotalItems = 0;
  List<DeviceModel> _relatedDevices = [];
  bool _isLoadingRelated = false;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.device.status;
    _currentUnitName = widget.device.currentUnitName;
    _name = widget.device.name;
    _serialNumber = widget.device.serialNumber;
    _rentalPricePerDay = widget.device.rentalPricePerDay;
    _categoryName = widget.device.categoryName;
    _imageUrl = widget.device.imageUrl;
    _loadHistory();
    _fetchRelatedDevices(1);
  }

  Future<void> _fetchRelatedDevices(int page) async {
    setState(() {
      _isLoadingRelated = true;
      _relatedPage = page;
    });

    try {
      final res = await DeviceRepository.getRelatedDevicesPaged(
        deviceId: widget.device.id,
        page: page,
        limit: 3,
      );
      if (!mounted) return;
      setState(() {
        _relatedDevices = res['devices'] as List<DeviceModel>;
        _relatedTotalPages = res['total_pages'] as int;
        _relatedTotalItems = res['total_items'] as int;
        _isLoadingRelated = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingRelated = false);
    }
  }

  void _loadHistory() {
    setState(() {
      _historyFuture = DeviceRepository.getDeviceHistory(widget.device.id);
    });
  }

  Color _getStatusColor(DeviceStatus status) {
    switch (status) {
      case DeviceStatus.available:
        return AppColors.statusAvailable;
      case DeviceStatus.rented:
        return AppColors.statusRented;
      case DeviceStatus.maintenance:
        return AppColors.statusMaintenance;
      case DeviceStatus.broken:
        return AppColors.statusBroken;
    }
  }

  void _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận Xóa Thiết bị'),
        content: Text(
          'Bạn có chắc chắn muốn xóa thiết bị "$_name" (Serial: $_serialNumber) khỏi hệ thống?',
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
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);
    final result = await DeviceRepository.deleteDeviceWithError(
      widget.device.id,
    );
    setState(() => _isProcessing = false);

    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã xóa thiết bị thành công!'),
          backgroundColor: AppColors.statusAvailable,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] ?? 'Lỗi khi xóa thiết bị.'),
          backgroundColor: AppColors.statusBroken,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _handleEdit() async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => DeviceFormScreen(
          device: DeviceModel(
            id: widget.device.id,
            serialNumber: _serialNumber,
            name: _name,
            categoryName: _categoryName,
            categoryId: widget.device.categoryId,
            status: _currentStatus,
            rentalPricePerDay: _rentalPricePerDay,
            qrCode: widget.device.qrCode,
            imageUrl: widget.device.imageUrl,
            currentUnitName: _currentUnitName,
          ),
        ),
      ),
    );

    if (updated == true) {
      // Tải lại thông tin mới nhất
      final device = await DeviceRepository.lookupDevice(
        widget.device.id.toString(),
      );
      if (device != null && mounted) {
        setState(() {
          _name = device.name;
          _serialNumber = device.serialNumber;
          _categoryName = device.categoryName;
          _rentalPricePerDay = device.rentalPricePerDay;
          _currentStatus = device.status;
          _currentUnitName = device.currentUnitName;
          _imageUrl = device.imageUrl;
        });
      }
    }
  }

  void _handleStatusChange(
    DeviceStatus newStatus,
    String actionName,
    String? newUnit,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Xác nhận $actionName'),
        content: Text(
          newStatus == DeviceStatus.rented
              ? 'Xác nhận xuất kho bàn giao thiết bị "$_name" cho đơn vị thuê?'
              : (newStatus == DeviceStatus.available
                    ? 'Xác nhận thu hồi thiết bị "$_name" về Kho tổng?'
                    : 'Xác nhận chuyển trạng thái thiết bị sang ${newStatus.label}?'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: newStatus == DeviceStatus.available
                  ? AppColors.statusAvailable
                  : AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Đồng ý'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);
    final result = await DeviceRepository.updateDeviceStatus(
      widget.device.id,
      newStatus,
    );
    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (result['success'] == true) {
      setState(() {
        _currentStatus = newStatus;
        _currentUnitName = newUnit;
      });
      _loadHistory();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Thành công: Đã $actionName!'),
          backgroundColor: AppColors.statusAvailable,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] as String),
          backgroundColor: AppColors.statusBroken,
        ),
      );
    }
  }

  void _handleHandoverToUnit() async {
    final units = await UnitRepository.getUnits();
    if (!mounted) return;

    if (units.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Chưa có danh sách đơn vị. Vui lòng thêm đơn vị trước.',
          ),
        ),
      );
      return;
    }

    final selectedUnit = await showDialog<UnitModel>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Chọn Đơn vị Bàn giao'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: units.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (ctx, i) {
              final u = units[i];
              return ListTile(
                leading: const Icon(Icons.business, color: AppColors.primary),
                title: Text(
                  u.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  u.address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
                onTap: () => Navigator.pop(ctx, u),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
        ],
      ),
    );

    if (selectedUnit != null && mounted) {
      _handleStatusChange(
        DeviceStatus.rented,
        'Bàn giao cho ${selectedUnit.name}',
        selectedUnit.name,
      );
    }
  }

  void _showStatusBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Cập nhật trạng thái thiết bị',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Chọn trạng thái cần cập nhật cho thiết bị:',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(
                  Icons.check_circle_outline,
                  color: AppColors.statusAvailable,
                ),
                title: const Text(
                  'Sẵn sàng trong kho',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Thiết bị hoạt động tốt, sẵn sàng cho thuê',
                ),
                trailing: _currentStatus == DeviceStatus.available
                    ? const Icon(Icons.check, color: AppColors.statusAvailable)
                    : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                tileColor: _currentStatus == DeviceStatus.available
                    ? AppColors.statusAvailable.withValues(alpha: 0.1)
                    : null,
                onTap: () {
                  Navigator.pop(ctx);
                  if (_currentStatus != DeviceStatus.available) {
                    _handleStatusChange(
                      DeviceStatus.available,
                      'Đưa thiết bị về Sẵn sàng',
                      null,
                    );
                  }
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(
                  Icons.build_circle_outlined,
                  color: AppColors.statusMaintenance,
                ),
                title: const Text(
                  'Đang bảo trì / Kiểm định',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Tạm ngưng cho thuê để bảo dưỡng hoặc kiểm định',
                ),
                trailing: _currentStatus == DeviceStatus.maintenance
                    ? const Icon(
                        Icons.check,
                        color: AppColors.statusMaintenance,
                      )
                    : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                tileColor: _currentStatus == DeviceStatus.maintenance
                    ? AppColors.statusMaintenance.withValues(alpha: 0.1)
                    : null,
                onTap: () {
                  Navigator.pop(ctx);
                  if (_currentStatus != DeviceStatus.maintenance) {
                    _handleStatusChange(
                      DeviceStatus.maintenance,
                      'Chuyển sang Đang bảo trì',
                      null,
                    );
                  }
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.statusBroken,
                ),
                title: const Text(
                  'Hỏng hóc / Chờ sửa chữa',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Thiết bị lỗi hỏng linh kiện hoặc gặp sự cố kỹ thuật',
                ),
                trailing: _currentStatus == DeviceStatus.broken
                    ? const Icon(Icons.check, color: AppColors.statusBroken)
                    : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                tileColor: _currentStatus == DeviceStatus.broken
                    ? AppColors.statusBroken.withValues(alpha: 0.1)
                    : null,
                onTap: () {
                  Navigator.pop(ctx);
                  if (_currentStatus != DeviceStatus.broken) {
                    _handleStatusChange(
                      DeviceStatus.broken,
                      'Báo hỏng thiết bị',
                      null,
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Chi tiết Thiết bị'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        actions: [
          const CartBadgeIcon(),
          if (MemberRepository.isAdmin) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
              tooltip: 'Chỉnh sửa (Admin)',
              onPressed: _handleEdit,
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: AppColors.statusBroken,
              ),
              tooltip: 'Xóa thiết bị (Admin)',
              onPressed: _handleDelete,
            ),
          ],
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
                  if (_imageUrl != null && _imageUrl!.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        _imageUrl!.startsWith('http')
                            ? _imageUrl!
                            : '${ApiConstants.baseHost}$_imageUrl',
                        height: 190,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const SizedBox.shrink(),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _categoryName,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: MemberRepository.isAdmin
                            ? _showStatusBottomSheet
                            : null,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(_currentStatus)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _getStatusColor(_currentStatus)
                                  .withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                MemberRepository.isAdmin
                                    ? _currentStatus.label
                                    : widget.device.rentalLabel,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: _getStatusColor(_currentStatus),
                                ),
                              ),
                              if (MemberRepository.isAdmin)
                                Icon(
                                  Icons.arrow_drop_down,
                                  size: 18,
                                  color: _getStatusColor(_currentStatus),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Số Serial: $_serialNumber',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Đơn giá thuê:',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        '${currencyFormatter.format(_rentalPricePerDay)} / ngày',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // QR & Barcode Section
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
                    'Mã định danh quét (QR/Barcode)',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.qr_code_2,
                            size: 100,
                            color: AppColors.primary,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.device.qrCode,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Location / Unit Section (admin only)
            if (MemberRepository.isAdmin)
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
                      'Vị trí & Đơn vị đang sử dụng',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          _currentStatus == DeviceStatus.rented
                              ? Icons.business
                              : Icons.warehouse_outlined,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _currentStatus == DeviceStatus.rented
                                ? (_currentUnitName ??
                                      'Đang cho đơn vị bên ngoài thuê')
                                : 'Hiện đang ở Kho tổng trung tâm (Sẵn sàng)',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // Rental History Timeline
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
                    children: [
                      const Icon(
                        Icons.history_outlined,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        MemberRepository.isAdmin
                            ? 'Lịch sử thuê & Luân chuyển máy'
                            : 'Lịch sử thuê của bạn',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _historyFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return TextButton(
                          onPressed: _loadHistory,
                          child: const Text(
                            'Không tải được lịch sử. Nhấn để thử lại',
                          ),
                        );
                      }
                      final history = snapshot.data ?? [];
                      if (history.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(16),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            MemberRepository.isAdmin
                                ? 'Thiết bị chưa có lịch sử cho thuê nào.'
                                : 'Bạn chưa thuê thiết bị này.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: history.map((item) {
                          final isActive = item['rental_status'] == 'ACTIVE';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isActive
                                    ? AppColors.statusRented.withValues(
                                        alpha: 0.3,
                                      )
                                    : AppColors.border,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      item['contract_code']?.toString() ?? '',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isActive
                                            ? AppColors.statusRented
                                            : const Color(0xFF64748B),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        const {
                                              'ACTIVE': 'ĐANG THUÊ',
                                              'PENDING': 'CHỜ DUYỆT',
                                              'APPROVED': 'CHỜ BÀN GIAO',
                                              'CANCELLED': 'ĐÃ HỦY',
                                              'RETURNED': 'ĐÃ HOÀN TRẢ',
                                            }[item['rental_status']] ??
                                            'KHÔNG XÁC ĐỊNH',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  item['unit_name']?.toString() ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Thời hạn: ${item['start_date']?.toString().substring(0, 10)} -> ${item['actual_end_date']?.toString().substring(0, 10) ?? item['expected_end_date']?.toString().substring(0, 10)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                if (item['condition_on_delivery'] != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'Ghi chú giao: ${item['condition_on_delivery']}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontStyle: FontStyle.italic,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
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

            // Sản phẩm liên quan cùng danh mục (có phân trang)
            _buildRelatedDevicesSection(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: _buildActionButton(),
      ),
    );
  }

  Widget _buildRelatedDevicesSection() {
    return Container(
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
              Row(
                children: [
                  const Icon(
                    Icons.recommend_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Sản phẩm liên quan',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (_relatedTotalItems > 0)
                Text(
                  '$_relatedTotalItems thiết bị',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoadingRelated)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_relatedDevices.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                  'Không có sản phẩm liên quan trong cùng danh mục.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
            )
          else ...[
            ..._relatedDevices.map(
              (relatedDev) => DeviceCard(
                device: relatedDev,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DeviceDetailScreen(device: relatedDev),
                    ),
                  );
                },
              ),
            ),
            if (_relatedTotalPages > 1)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: _relatedPage > 1
                          ? () => _fetchRelatedDevices(_relatedPage - 1)
                          : null,
                      color: _relatedPage > 1
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                    Text(
                      'Trang $_relatedPage / $_relatedTotalPages',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: _relatedPage < _relatedTotalPages
                          ? () => _fetchRelatedDevices(_relatedPage + 1)
                          : null,
                      color: _relatedPage < _relatedTotalPages
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    if (!MemberRepository.isAdmin && _currentStatus != DeviceStatus.available) {
      return Text(
        widget.device.isRentedByMe
            ? '${widget.device.rentalLabel}. Xem tiến độ trong Đơn thuê của bạn.'
            : _currentStatus == DeviceStatus.rented
            ? 'Thiết bị đã có khách khác thuê. Vui lòng chọn thiết bị sẵn sàng.'
            : 'Thiết bị hiện chưa sẵn sàng cho thuê.',
        textAlign: TextAlign.center,
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

    switch (_currentStatus) {
      case DeviceStatus.available:
        return ValueListenableBuilder(
          valueListenable: CartService.cartNotifier,
          builder: (context, _, _) {
            final isInCart = CartService.isInCart(widget.device.id);

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (isInCart) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CartScreen()),
                        );
                      } else {
                        CartService.addToCart(widget.device);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Đã thêm "${widget.device.name}" vào giỏ thuê!',
                            ),
                            backgroundColor: AppColors.statusAvailable,
                            action: SnackBarAction(
                              label: 'Xem giỏ',
                              textColor: Colors.white,
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const CartScreen(),
                                ),
                              ),
                            ),
                          ),
                        );
                      }
                    },
                    icon: Icon(
                      isInCart
                          ? Icons.shopping_cart_checkout
                          : Icons.add_shopping_cart,
                    ),
                    label: Text(
                      isInCart
                          ? 'Đã có trong giỏ hàng (Xem giỏ)'
                          : 'Thêm vào Giỏ thiết bị thuê',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isInCart
                          ? Colors.teal
                          : AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                if (MemberRepository.isAdmin)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _handleHandoverToUnit,
                          icon: const Icon(Icons.outbox_rounded, size: 18),
                          label: const Text('Bàn giao ngay'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _handleStatusChange(
                            DeviceStatus.maintenance,
                            'Chuyển sang Đang bảo trì',
                            null,
                          ),
                          icon: const Icon(
                            Icons.build_circle_outlined,
                            size: 18,
                          ),
                          label: const Text('Bảo trì'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.statusMaintenance,
                            side: const BorderSide(
                              color: AppColors.statusMaintenance,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _handleStatusChange(
                            DeviceStatus.broken,
                            'Báo hỏng thiết bị',
                            null,
                          ),
                          icon: const Icon(
                            Icons.warning_amber_rounded,
                            size: 18,
                          ),
                          label: const Text('Báo hỏng'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.statusBroken,
                            side: const BorderSide(
                              color: AppColors.statusBroken,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            );
          },
        );

      case DeviceStatus.rented:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _handleStatusChange(
                  DeviceStatus.available,
                  'Thu hồi thiết bị về kho',
                  null,
                ),
                icon: const Icon(Icons.assignment_return_outlined),
                label: const Text('Thu hồi thiết bị (Nhập lại vào kho)'),
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
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _handleStatusChange(
                  DeviceStatus.broken,
                  'Thu hồi & Báo hỏng thiết bị',
                  null,
                ),
                icon: const Icon(Icons.warning_amber_rounded, size: 18),
                label: const Text('Thu hồi & Báo hỏng (Cần bảo dưỡng)'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.statusBroken,
                  side: const BorderSide(color: AppColors.statusBroken),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        );

      case DeviceStatus.maintenance:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _handleStatusChange(
                  DeviceStatus.available,
                  'Hoàn tất bảo trì',
                  null,
                ),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Hoàn tất bảo trì (Đưa về Sẵn sàng)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.statusAvailable,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _handleStatusChange(
                  DeviceStatus.broken,
                  'Báo hỏng (Không sửa được)',
                  null,
                ),
                icon: const Icon(Icons.cancel_outlined, size: 18),
                label: const Text('Báo hỏng nặng (Không sửa chữa được)'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.statusBroken,
                  side: const BorderSide(color: AppColors.statusBroken),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        );

      case DeviceStatus.broken:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _handleStatusChange(
                  DeviceStatus.maintenance,
                  'Gửi bảo trì sửa chữa',
                  null,
                ),
                icon: const Icon(Icons.build_circle_outlined),
                label: const Text('Gửi đi sửa chữa / Bảo dưỡng'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.statusRented,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _handleStatusChange(
                  DeviceStatus.available,
                  'Khắc phục xong đưa vào kho',
                  null,
                ),
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text('Đã khắc phục xong (Đưa về Sẵn sàng)'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.statusAvailable,
                  side: const BorderSide(color: AppColors.statusAvailable),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        );
    }
  }
}

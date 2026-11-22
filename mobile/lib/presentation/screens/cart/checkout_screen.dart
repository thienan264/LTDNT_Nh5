import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/repositories/rental_repository.dart';
import '../../../data/repositories/unit_repository.dart';
import '../../../data/datasources/cart_service.dart';
import '../../../data/models/cart_item_model.dart';
import '../../../data/models/unit_model.dart';
import '../rentals/rental_detail_screen.dart';
import 'vietqr_payment_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final List<CartItemModel> cartItems;

  const CheckoutScreen({super.key, required this.cartItems});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _codeController;
  late TextEditingController _depositController;
  late TextEditingController _notesController;

  int? _selectedUnitId;
  DateTime _startDate = DateTime.now();
  late DateTime _expectedEndDate;
  String _paymentMethod = 'VIETQR'; // 'VIETQR' | 'CASH'

  List<UnitModel> _units = [];
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: 'Server tự cấp sau khi lưu');

    // Mặc định ngày trả theo số ngày dài nhất trong giỏ hàng
    final maxDays = widget.cartItems.fold<int>(
      1,
      (max, i) => i.rentalDays > max ? i.rentalDays : max,
    );
    _expectedEndDate = DateTime.now().add(Duration(days: maxDays));

    final totalDeposit = widget.cartItems.fold<double>(
      0.0,
      (sum, i) => sum + i.depositEstimated,
    );
    _depositController = TextEditingController(
      text: totalDeposit.toStringAsFixed(0),
    );
    _notesController = TextEditingController(
      text: 'Đặt thuê qua Giỏ hàng thiết bị',
    );

    _loadUnits();
  }

  void _loadUnits() async {
    try {
      final units = await UnitRepository.getUnits();
      if (!mounted) return;
      setState(() {
        _units = units;
        if (_units.isNotEmpty) _selectedUnitId = _units.first.id;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không tải được đơn vị thuê. Kiểm tra kết nối API.'),
        ),
      );
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _depositController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedUnitId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn đơn vị thuê')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final deviceIds = widget.cartItems.map((e) => e.device.id).toList();

    final createdRental = await RentalRepository.createRental(
      unitId: _selectedUnitId!,
      startDate: _startDate,
      expectedEndDate: _expectedEndDate,
      deviceIds: deviceIds,
      cartItems: widget.cartItems,
      notes: '${_notesController.text.trim()} (PTTT: $_paymentMethod)',
    );

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    if (createdRental != null) {
      // Xóa sạch giỏ hàng sau khi đặt thành công
      CartService.clearCart();

      if (_paymentMethod == 'VIETQR' && createdRental.totalDeposit > 0) {
        // Chuyển sang màn hình quét mã VietQR thanh toán
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => VietQrPaymentScreen(
              contractCode: createdRental.contractCode,
              amount: createdRental.totalDeposit,
              unitName: createdRental.unitName,
              onPaymentCompleted: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RentalDetailScreen(rental: createdRental),
                  ),
                );
              },
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tạo Hợp đồng thuê thành công!'),
            backgroundColor: AppColors.statusAvailable,
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => RentalDetailScreen(rental: createdRental),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Có lỗi xảy ra khi tạo hợp đồng thuê.'),
          backgroundColor: AppColors.statusBroken,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final dateFormat = DateFormat('dd/MM/yyyy');
    final totalRentAmount = widget.cartItems.fold<double>(
      0.0,
      (sum, i) => sum + i.itemTotal,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Xác nhận Đặt thuê (Checkout)'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Danh sách thiết bị trong giỏ
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
                              const Text(
                                'Thiết bị đặt thuê',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${widget.cartItems.length} thiết bị',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          Column(
                            children: widget.cartItems.map((item) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle_outline,
                                      color: AppColors.statusAvailable,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.device.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                          ),
                                          Text(
                                            '${item.device.serialNumber} • ${item.rentalDays} ngày',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      currencyFormat.format(item.itemTotal),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Thông tin Hợp đồng & Đơn vị thuê
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
                            'Thông tin Hợp đồng & Đơn vị',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Mã hợp đồng
                          TextFormField(
                            controller: _codeController,
                            readOnly: true,
                            decoration: InputDecoration(
                              labelText: 'Mã hợp đồng',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Vui lòng nhập mã'
                                : null,
                          ),
                          const SizedBox(height: 14),

                          // Chọn đơn vị
                          DropdownButtonFormField<int>(
                            initialValue: _selectedUnitId,
                            decoration: InputDecoration(
                              labelText: 'Đơn vị / Khách thuê *',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items: _units.map((u) {
                              return DropdownMenuItem<int>(
                                value: u.id,
                                child: Text(
                                  u.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (val) =>
                                setState(() => _selectedUnitId = val),
                          ),
                          const SizedBox(height: 14),

                          // Ngày thuê & trả
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () async {
                                    final now = DateTime.now();
                                    final today = DateTime(
                                      now.year,
                                      now.month,
                                      now.day,
                                    );
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: _startDate,
                                      firstDate: today,
                                      lastDate: DateTime(2035),
                                    );
                                    if (picked != null) {
                                      setState(() {
                                        _startDate = picked;
                                        if (_expectedEndDate.isBefore(
                                          _startDate,
                                        )) {
                                          _expectedEndDate = _startDate.add(
                                            const Duration(days: 7),
                                          );
                                        }
                                      });
                                    }
                                  },
                                  child: InputDecorator(
                                    decoration: InputDecoration(
                                      labelText: 'Ngày bắt đầu',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text(dateFormat.format(_startDate)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: InkWell(
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: _expectedEndDate,
                                      firstDate: _startDate,
                                      lastDate: DateTime(2035),
                                    );
                                    if (picked != null) {
                                      setState(() => _expectedEndDate = picked);
                                    }
                                  },
                                  child: InputDecorator(
                                    decoration: InputDecoration(
                                      labelText: 'Ngày dự kiến trả',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                      dateFormat.format(_expectedEndDate),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Tiền cọc
                          TextFormField(
                            controller: _depositController,
                            readOnly: true,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Tiền cọc ước tính 30% (VNĐ)',
                              suffixText: 'đ',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Vui lòng nhập tiền cọc'
                                : null,
                          ),
                          const SizedBox(height: 14),

                          // Ghi chú
                          TextFormField(
                            controller: _notesController,
                            decoration: InputDecoration(
                              labelText: 'Ghi chú thêm',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Phương thức thanh toán cọc
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
                            'Phương thức thanh toán cọc',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          RadioGroup<String>(
                            groupValue: _paymentMethod,
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _paymentMethod = val);
                              }
                            },
                            child: Column(
                              children: const [
                                RadioListTile<String>(
                                  value: 'VIETQR',
                                  activeColor: AppColors.primary,
                                  contentPadding: EdgeInsets.zero,
                                  title: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.qr_code_scanner,
                                        color: AppColors.primary,
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Quét mã VietQR (Napas247)',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: Text(
                                    'Tạo mã QR chuyển khoản ngân hàng ngay lập tức',
                                  ),
                                ),
                                Divider(height: 1),
                                RadioListTile<String>(
                                  value: 'CASH',
                                  activeColor: AppColors.primary,
                                  contentPadding: EdgeInsets.zero,
                                  title: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.payments_outlined,
                                        color: Colors.teal,
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Thanh toán tiền mặt / Chuyển khoản sau',
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: Text(
                                    'Thanh toán trực tiếp khi nhận bàn giao máy',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Tóm tắt tổng tiền & Nút tạo hợp đồng
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Tổng giá trị thuê ước tính:',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                currencyFormat.format(totalRentAmount),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Tiền cọc cần thanh toán:',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                currencyFormat.format(
                                  double.tryParse(_depositController.text) ??
                                      0.0,
                                ),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _isSubmitting ? null : _submitOrder,
                              child: _isSubmitting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      _paymentMethod == 'VIETQR'
                                          ? 'Tiếp tục Thanh toán VietQR'
                                          : 'Xác nhận Tạo Hợp đồng',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/repositories/device_repository.dart';
import '../../../data/repositories/rental_repository.dart';
import '../../../data/repositories/unit_repository.dart';
import '../../../data/models/device_model.dart';
import '../../../data/models/unit_model.dart';

class RentalFormScreen extends StatefulWidget {
  const RentalFormScreen({super.key});

  @override
  State<RentalFormScreen> createState() => _RentalFormScreenState();
}

class _RentalFormScreenState extends State<RentalFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _codeController;
  late TextEditingController _depositController;
  late TextEditingController _notesController;

  int? _selectedUnitId;
  Set<int> _selectedDeviceIds = {};
  DateTime _startDate = DateTime.now();
  DateTime _expectedEndDate = DateTime.now().add(const Duration(days: 30));

  List<UnitModel> _units = [];
  List<DeviceModel> _availableDevices = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: 'Server tự cấp sau khi lưu');
    _depositController = TextEditingController(text: '0');
    _notesController = TextEditingController();
    _loadInitialData();
  }

  void _updateDeposit() {
    final days = _expectedEndDate.difference(_startDate).inDays;
    final total = _availableDevices
        .where((d) => _selectedDeviceIds.contains(d.id))
        .fold<double>(0, (sum, d) => sum + d.rentalPricePerDay * days);
    _depositController.text = (total * 0.3).toStringAsFixed(0);
  }

  void _loadInitialData() async {
    try {
      final units = await UnitRepository.getUnits();
      final devices = await DeviceRepository.getDevices(status: 'AVAILABLE');
      if (!mounted) return;
      setState(() {
        _units = units;
        _availableDevices = devices;
        if (_units.isNotEmpty) _selectedUnitId = _units.first.id;
        if (_availableDevices.isNotEmpty) {
          _selectedDeviceIds = {_availableDevices.first.id};
        }
        _updateDeposit();
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không tải được dữ liệu. Kiểm tra kết nối API.'),
        ),
      );
    }
  }

  void _showQuickAddUnitDialog() {
    final nameCtrl = TextEditingController();
    final addrCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final personCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thêm Nhanh Đơn Vị Thuê'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tên Công ty / Đơn vị *',
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Vui lòng nhập tên'
                    : null,
              ),
              TextFormField(
                controller: addrCtrl,
                decoration: const InputDecoration(
                  labelText: 'Địa chỉ công trình *',
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Vui lòng nhập địa chỉ'
                    : null,
              ),
              TextFormField(
                controller: personCtrl,
                decoration: const InputDecoration(
                  labelText: 'Người đại diện liên hệ *',
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Vui lòng nhập người liên hệ'
                    : null,
              ),
              TextFormField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Số điện thoại *'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Vui lòng nhập SĐT'
                    : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(ctx);

              final created = await UnitRepository.createUnit(
                name: nameCtrl.text.trim(),
                address: addrCtrl.text.trim(),
                phoneNumber: phoneCtrl.text.trim(),
                contactPerson: personCtrl.text.trim(),
              );

              if (created != null) {
                final updatedUnits = await UnitRepository.getUnits();
                setState(() {
                  _units = updatedUnits;
                  _selectedUnitId = created.id;
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Đã thêm đơn vị "${created.name}" thành công!',
                      ),
                      backgroundColor: AppColors.statusAvailable,
                    ),
                  );
                }
              }
            },
            child: const Text('Lưu & Chọn'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    _depositController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _saveRental() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedUnitId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn đơn vị thuê')),
      );
      return;
    }
    if (_selectedDeviceIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Vui lòng chọn ít nhất 1 thiết bị sẵn sàng để cho thuê',
          ),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    _updateDeposit();

    final success = await RentalRepository.createRental(
      unitId: _selectedUnitId!,
      startDate: _startDate,
      expectedEndDate: _expectedEndDate,
      deviceIds: _selectedDeviceIds.toList(),
      notes: _notesController.text.trim(),
    );

    setState(() => _isSaving = false);

    if (!mounted) return;

    if (success != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tạo hợp đồng cho thuê mới thành công!'),
          backgroundColor: AppColors.statusAvailable,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Có lỗi xảy ra khi tạo hợp đồng.'),
          backgroundColor: AppColors.statusBroken,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('dd/MM/yyyy');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tạo Hợp Đồng Cho Thuê'),
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
                  children: [
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
                          const Text(
                            'Thông tin Hợp đồng & Bên thuê',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Mã hợp đồng
                          TextFormField(
                            controller: _codeController,
                            readOnly: true,
                            decoration: InputDecoration(
                              labelText: 'Mã hợp đồng *',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (val) =>
                                (val == null || val.trim().isEmpty)
                                ? 'Vui lòng nhập mã hợp đồng'
                                : null,
                          ),
                          const SizedBox(height: 16),

                          // Chọn Đơn vị thuê kèm nút Thêm mới
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  initialValue: _selectedUnitId,
                                  decoration: InputDecoration(
                                    labelText: 'Đơn vị / Chi nhánh thuê *',
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
                              ),
                              const SizedBox(width: 8),
                              IconButton.filledTonal(
                                tooltip: 'Thêm đơn vị thuê mới',
                                icon: const Icon(Icons.add_business),
                                onPressed: _showQuickAddUnitDialog,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Chọn Thiết bị rảnh (Hỗ trợ chọn nhiều thiết bị)
                          if (_availableDevices.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.amber.shade300,
                                ),
                              ),
                              child: const Text(
                                'Hiện không có thiết bị nào đang Sẵn sàng trong kho để cho thuê.',
                                style: TextStyle(
                                  color: Colors.amber,
                                  fontSize: 13,
                                ),
                              ),
                            )
                          else
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Chọn thiết bị cho thuê *',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      'Đã chọn: ${_selectedDeviceIds.length}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: AppColors.border),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    children: _availableDevices.map((d) {
                                      final isSelected = _selectedDeviceIds
                                          .contains(d.id);
                                      return CheckboxListTile(
                                        value: isSelected,
                                        dense: true,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 12,
                                            ),
                                        activeColor: AppColors.primary,
                                        title: Text(
                                          d.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                        subtitle: Text(
                                          '${d.serialNumber} • ${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(d.rentalPricePerDay)}/ngày',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        onChanged: (val) {
                                          setState(() {
                                            if (val == true) {
                                              _selectedDeviceIds.add(d.id);
                                            } else {
                                              _selectedDeviceIds.remove(d.id);
                                            }
                                            _updateDeposit();
                                          });
                                        },
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 16),

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
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Vui lòng nhập tiền cọc';
                              }
                              final num = double.tryParse(val.trim());
                              if (num == null) return 'Tiền cọc phải là số';
                              if (num < 0) {
                                return 'Tiền cọc không được là số âm';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Ngày bắt đầu & Ngày kết thúc
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
                                      initialDate: _startDate.isBefore(today)
                                          ? today
                                          : _startDate,
                                      firstDate: today,
                                      lastDate: DateTime(2035),
                                    );
                                    if (picked != null) {
                                      setState(() {
                                        _startDate = picked;
                                        _updateDeposit();
                                        if (_expectedEndDate.isBefore(
                                          _startDate,
                                        )) {
                                          _expectedEndDate = _startDate.add(
                                            const Duration(days: 30),
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
                                    child: Text(
                                      dateFormatter.format(_startDate),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: InkWell(
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate:
                                          _expectedEndDate.isBefore(_startDate)
                                          ? _startDate
                                          : _expectedEndDate,
                                      firstDate: _startDate,
                                      lastDate: DateTime(2035),
                                    );
                                    if (picked != null) {
                                      setState(() {
                                        _expectedEndDate = picked;
                                        _updateDeposit();
                                      });
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
                                      dateFormatter.format(_expectedEndDate),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Ghi chú
                          TextFormField(
                            controller: _notesController,
                            maxLines: 2,
                            decoration: InputDecoration(
                              labelText: 'Ghi chú hợp đồng',
                              hintText:
                                  'VD: Thuê máy phục vụ dự án công trình A...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveRental,
                        icon: _isSaving
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
                          _isSaving
                              ? 'Đang tạo...'
                              : 'Ký duyệt & Xuất kho bàn giao',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

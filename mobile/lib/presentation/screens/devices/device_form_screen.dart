import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/repositories/category_repository.dart';
import '../../../data/repositories/device_repository.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/device_model.dart';

class DeviceFormScreen extends StatefulWidget {
  final DeviceModel? device;

  const DeviceFormScreen({super.key, this.device});

  @override
  State<DeviceFormScreen> createState() => _DeviceFormScreenState();
}

class _DeviceFormScreenState extends State<DeviceFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _serialController;
  late TextEditingController _priceController;
  int _selectedCategoryId = 1;
  late DeviceStatus _selectedStatus;
  bool _isSaving = false;

  List<CategoryModel> _categories = [];
  File? _pickedImageFile;
  String? _base64Image;
  String? _existingImageUrl;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.device?.name ?? '');
    _serialController = TextEditingController(
      text: widget.device?.serialNumber ?? '',
    );
    _priceController = TextEditingController(
      text: widget.device != null
          ? widget.device!.rentalPricePerDay.toStringAsFixed(0)
          : '',
    );
    _selectedStatus = widget.device?.status ?? DeviceStatus.available;
    _existingImageUrl = widget.device?.imageUrl;
    _loadCategories();
  }

  void _loadCategories() async {
    final cats = await CategoryRepository.getCategories();
    if (!mounted) return;
    setState(() {
      _categories = cats;
      if (widget.device != null) {
        // Ưu tiên khớp theo category_id nếu có
        final categoryId = widget.device!.categoryId;
        if (categoryId != null && categoryId > 0) {
          final match = _categories.firstWhere(
            (c) => c.id == categoryId,
            orElse: () => _categories.isNotEmpty
                ? _categories.first
                : const CategoryModel(id: 1, name: ''),
          );
          _selectedCategoryId = match.id;
        } else {
          final match = _categories.firstWhere(
            (c) => c.name == widget.device!.categoryName,
            orElse: () => _categories.isNotEmpty
                ? _categories.first
                : const CategoryModel(id: 1, name: ''),
          );
          _selectedCategoryId = match.id;
        }
      } else if (_categories.isNotEmpty) {
        _selectedCategoryId = _categories.first.id;
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _serialController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 75,
      );
      if (picked == null) return;

      final file = File(picked.path);
      final bytes = await file.readAsBytes();
      final base64Str = base64Encode(bytes);

      setState(() {
        _pickedImageFile = file;
        _base64Image = base64Str;
        _existingImageUrl = null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi chọn ảnh: $e'),
          backgroundColor: AppColors.statusBroken,
        ),
      );
    }
  }

  void _saveDevice() async {
    if (!_formKey.currentState!.validate()) return;

    if (widget.device == null &&
        _base64Image == null &&
        (_existingImageUrl == null || _existingImageUrl!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn hình ảnh cho thiết bị (Bắt buộc)'),
          backgroundColor: AppColors.statusBroken,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final name = _nameController.text.trim();
    final serial = _serialController.text.trim();
    final price = double.tryParse(_priceController.text.trim()) ?? 0.0;

    bool success;
    if (widget.device == null) {
      success = await DeviceRepository.createDevice(
        name: name,
        serialNumber: serial,
        categoryId: _selectedCategoryId,
        rentalPricePerDay: price,
        status: _selectedStatus,
        imageBase64: _base64Image,
      );
    } else {
      success = await DeviceRepository.updateDevice(
        id: widget.device!.id,
        name: name,
        serialNumber: serial,
        categoryId: _selectedCategoryId,
        rentalPricePerDay: price,
        status: _selectedStatus,
        imageBase64: _base64Image,
        imageUrl: _existingImageUrl,
      );
    }

    setState(() => _isSaving = false);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.device == null
                ? 'Thêm mới thiết bị thành công!'
                : 'Cập nhật thiết bị thành công!',
          ),
          backgroundColor: AppColors.statusAvailable,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lỗi khi lưu thông tin thiết bị.'),
          backgroundColor: AppColors.statusBroken,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.device != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEditing ? 'Chỉnh sửa Thiết bị' : 'Thêm Thiết bị mới'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // -- Ảnh thiết bị --
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
                      'Hình ảnh Thiết bị',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: double.infinity,
                          height: 180,
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.border,
                              width: 1.5,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: _buildImagePreview(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(
                            Icons.photo_library_outlined,
                            size: 18,
                          ),
                          label: Text(
                            _pickedImageFile != null ||
                                    _existingImageUrl != null
                                ? 'Đổi ảnh'
                                : 'Chọn ảnh từ thư viện',
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                          ),
                        ),
                        if (_pickedImageFile != null ||
                            _existingImageUrl != null)
                          TextButton.icon(
                            onPressed: () => setState(() {
                              _pickedImageFile = null;
                              _base64Image = null;
                              _existingImageUrl = null;
                            }),
                            icon: const Icon(Icons.delete_outline, size: 18),
                            label: const Text('Xóa ảnh'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.statusBroken,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // -- Thông tin cơ bản --
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
                      'Thông tin Cơ bản',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Tên thiết bị *',
                        hintText: 'VD: Máy toàn đạc điện tử Leica TS07',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (val) => (val == null || val.trim().isEmpty)
                          ? 'Vui lòng nhập tên thiết bị'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _serialController,
                      decoration: InputDecoration(
                        labelText: 'Số Serial / Mã máy *',
                        hintText: 'VD: TB-DL-001',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (val) => (val == null || val.trim().isEmpty)
                          ? 'Vui lòng nhập số Serial'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // Danh mục
                    DropdownButtonFormField<int>(
                      initialValue:
                          _categories.any((c) => c.id == _selectedCategoryId)
                          ? _selectedCategoryId
                          : null,
                      decoration: InputDecoration(
                        labelText: 'Nhóm danh mục *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      hint: _categories.isEmpty
                          ? const Text('Đang tải danh mục...')
                          : null,
                      items: _categories.map((c) {
                        return DropdownMenuItem<int>(
                          value: c.id,
                          child: Text(c.name, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedCategoryId = val);
                        }
                      },
                      validator: (val) =>
                          val == null ? 'Vui lòng chọn danh mục' : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Đơn giá thuê (VNĐ/ngày) *',
                        hintText: 'VD: 350000',
                        suffixText: 'đ/ngày',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Vui lòng nhập đơn giá';
                        }
                        final num = double.tryParse(val.trim());
                        if (num == null) return 'Giá tiền phải là số';
                        if (num <= 0) return 'Đơn giá thuê phải lớn hơn 0đ';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<DeviceStatus>(
                      initialValue: _selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Trạng thái thiết bị *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                      ),
                      items: [
                        _statusItem(
                          DeviceStatus.available,
                          'Sẵn sàng trong kho',
                          AppColors.statusAvailable,
                        ),
                        if (widget.device?.status == DeviceStatus.rented)
                          _statusItem(
                            DeviceStatus.rented,
                            'Đang cho thuê',
                            AppColors.statusRented,
                          ),
                        _statusItem(
                          DeviceStatus.maintenance,
                          'Đang bảo trì / Kiểm định',
                          AppColors.statusMaintenance,
                        ),
                        _statusItem(
                          DeviceStatus.broken,
                          'Hỏng hóc / Chờ sửa chữa',
                          AppColors.statusBroken,
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedStatus = val);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveDevice,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(
                    _isSaving
                        ? 'Đang lưu...'
                        : (isEditing ? 'Lưu thay đổi' : 'Thêm vào kho'),
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

  Widget _buildImagePreview() {
    if (_pickedImageFile != null) {
      return Image.file(
        _pickedImageFile!,
        fit: BoxFit.cover,
        width: double.infinity,
      );
    }
    if (_existingImageUrl != null && _existingImageUrl!.isNotEmpty) {
      final url = _existingImageUrl!.startsWith('http')
          ? _existingImageUrl!
          : '${ApiConstants.baseHost}$_existingImageUrl';
      return Image.network(
        url,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) => _imagePlaceholder(),
      );
    }
    return _imagePlaceholder();
  }

  Widget _imagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate_outlined,
          size: 48,
          color: AppColors.textSecondary.withValues(alpha: 0.5),
        ),
        const SizedBox(height: 8),
        Text(
          'Nhấn để chọn ảnh thiết bị',
          style: TextStyle(
            color: AppColors.textSecondary.withValues(alpha: 0.7),
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  DropdownMenuItem<DeviceStatus> _statusItem(
    DeviceStatus status,
    String label,
    Color color,
  ) {
    return DropdownMenuItem(
      value: status,
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}

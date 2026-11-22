import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/repositories/unit_repository.dart';
import '../../../data/models/unit_model.dart';

class UnitListScreen extends StatefulWidget {
  const UnitListScreen({super.key});

  @override
  State<UnitListScreen> createState() => _UnitListScreenState();
}

class _UnitListScreenState extends State<UnitListScreen> {
  late Future<List<UnitModel>> _unitsFuture;

  @override
  void initState() {
    super.initState();
    _loadUnits();
  }

  void _loadUnits() {
    setState(() {
      _unitsFuture = UnitRepository.getUnits();
    });
  }

  void _showAddUnitDialog() {
    final nameCtrl = TextEditingController();
    final addrCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final personCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thêm Đơn vị / Chi nhánh thuê'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Tên Công ty / Chi nhánh *',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Vui lòng nhập tên đơn vị'
                      : null,
                ),
                TextFormField(
                  controller: addrCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Địa chỉ công trình/chi nhánh *',
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
                  decoration: const InputDecoration(
                    labelText: 'Số điện thoại *',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Vui lòng nhập số điện thoại'
                      : null,
                ),
                TextFormField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email liên hệ'),
                ),
              ],
            ),
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

              final newUnit = await UnitRepository.createUnit(
                name: nameCtrl.text.trim(),
                address: addrCtrl.text.trim(),
                phoneNumber: phoneCtrl.text.trim(),
                contactPerson: personCtrl.text.trim(),
                email: emailCtrl.text.trim(),
              );

              if (newUnit != null) {
                _loadUnits();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã thêm đơn vị thuê mới thành công!'),
                      backgroundColor: AppColors.statusAvailable,
                    ),
                  );
                }
              }
            },
            child: const Text('Lưu đơn vị'),
          ),
        ],
      ),
    );
  }

  void _deleteUnit(UnitModel unit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận Xóa đơn vị'),
        content: Text(
          'Bạn có chắc muốn xóa đơn vị "${unit.name}" khỏi danh sách?',
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

    if (confirmed == true) {
      final success = await UnitRepository.deleteUnit(unit.id);
      _loadUnits();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Đã xóa đơn vị thành công' : 'Không xóa được đơn vị đang có thiết bị/hợp đồng hoặc mất kết nối.',
            ),
            backgroundColor: AppColors.statusAvailable,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Đơn vị / Chi nhánh thuê'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: _loadUnits,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddUnitDialog,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_business),
        label: const Text('Thêm đơn vị thuê'),
      ),
      body: FutureBuilder<List<UnitModel>>(
        future: _unitsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final units = snapshot.data ?? [];
          if (units.isEmpty) {
            return const Center(
              child: Text(
                'Chưa có đơn vị thuê nào',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: units.length,
            itemBuilder: (context, index) {
              final unit = units[index];

              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.border),
                ),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            backgroundColor: AppColors.primary.withValues(
                              alpha: 0.1,
                            ),
                            child: const Icon(
                              Icons.business,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  unit.name,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on_outlined,
                                      size: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        unit.address,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: AppColors.statusBroken,
                              size: 20,
                            ),
                            onPressed: () => _deleteUnit(unit),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Người liên hệ: ${unit.contactPerson}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'SĐT: ${unit.phoneNumber}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

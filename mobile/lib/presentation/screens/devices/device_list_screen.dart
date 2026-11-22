import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/repositories/category_repository.dart';
import '../../../data/repositories/device_repository.dart';
import '../../../data/repositories/member_repository.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/device_model.dart';
import '../../widgets/device_card.dart';
import '../../widgets/cart_badge_icon.dart';
import 'device_detail_screen.dart';
import 'device_form_screen.dart';

class DeviceListScreen extends StatefulWidget {
  const DeviceListScreen({super.key});

  @override
  State<DeviceListScreen> createState() => _DeviceListScreenState();
}

class _DeviceListScreenState extends State<DeviceListScreen> {
  String _selectedStatusFilter = 'ALL';
  int? _selectedCategoryId;
  String _searchQuery = '';

  // Phân trang
  int _currentPage = 1;
  static const int _pageSize = 10;
  int _totalPages = 1;
  int _totalItems = 0;

  List<DeviceModel> _devices = [];
  List<CategoryModel> _categories = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _fetchDevices();
  }

  Future<void> _loadCategories() async {
    final cats = await CategoryRepository.getCategories();
    if (!mounted) return;
    setState(() => _categories = cats);
  }

  Future<void> _fetchDevices({int page = 1}) async {
    setState(() {
      _isLoading = true;
      _currentPage = page;
    });

    try {
      final result = await DeviceRepository.getDevicesPaged(
        status: _selectedStatusFilter,
        search: _searchQuery,
        categoryId: _selectedCategoryId,
        page: page,
        limit: _pageSize,
      );

      if (!mounted) return;
      setState(() {
        _devices = result['devices'] as List<DeviceModel>;
        _totalPages = result['total_pages'] as int;
        _totalItems = result['total_items'] as int;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _onFilterChange() {
    _fetchDevices(page: 1);
  }

  Future<void> _deleteDevice(DeviceModel device) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa thiết bị\n"${device.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final result = await DeviceRepository.deleteDeviceWithError(device.id);
    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã xóa thiết bị thành công'),
          backgroundColor: AppColors.statusAvailable,
        ),
      );
      _fetchDevices(page: _currentPage);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] ?? 'Không thể xóa thiết bị'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Danh sách Thiết bị'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: () => _fetchDevices(page: 1),
          ),
          const CartBadgeIcon(),
        ],
      ),
      floatingActionButton: MemberRepository.isAdmin
          ? FloatingActionButton.extended(
              onPressed: () async {
                final created = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => const DeviceFormScreen()),
                );
                if (created == true) _fetchDevices(page: 1);
              },
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Thêm thiết bị'),
            )
          : null,
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              onChanged: (val) {
                _searchQuery = val;
                _onFilterChange();
              },
              decoration: InputDecoration(
                hintText: 'Tìm theo tên hoặc số serial...',
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.textSecondary,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
          ),

          // Lọc theo Danh mục
          if (_categories.isNotEmpty)
            SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildCategoryChip(null, 'Tất cả DM'),
                  ..._categories.map((c) => _buildCategoryChip(c.id, c.name)),
                ],
              ),
            ),

          const SizedBox(height: 6),

          // Lọc theo Trạng thái
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildStatusChip('Tất cả', 'ALL'),
                _buildStatusChip('Sẵn sàng', 'AVAILABLE'),
                if (!MemberRepository.isAdmin)
                  _buildStatusChip('Của tôi', 'MINE'),
                _buildStatusChip(
                  MemberRepository.isAdmin
                      ? 'Đang cho thuê'
                      : 'Đã có khách thuê',
                  'RENTED',
                ),
                _buildStatusChip('Bảo trì', 'MAINTENANCE'),
                _buildStatusChip('Hỏng', 'BROKEN'),
              ],
            ),
          ),

          // Tổng số kết quả
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                Text(
                  'Tìm thấy $_totalItems thiết bị',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Danh sách
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _devices.isEmpty
                ? const Center(
                    child: Text(
                      'Không tìm thấy thiết bị phù hợp',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    itemCount: _devices.length,
                    itemBuilder: (context, index) {
                      final device = _devices[index];
                      return DeviceCard(
                        device: device,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  DeviceDetailScreen(device: device),
                            ),
                          );
                          _fetchDevices(page: _currentPage);
                        },
                        adminActions: MemberRepository.isAdmin
                            ? _buildAdminActions(device)
                            : null,
                      );
                    },
                  ),
          ),

          // Phân trang
          if (_totalPages > 1)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _currentPage > 1
                        ? () => _fetchDevices(page: _currentPage - 1)
                        : null,
                    color: _currentPage > 1
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                  Text(
                    'Trang $_currentPage / $_totalPages',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _currentPage < _totalPages
                        ? () => _fetchDevices(page: _currentPage + 1)
                        : null,
                    color: _currentPage < _totalPages
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildAdminActions(DeviceModel device) {
    return [
      IconButton(
        icon: const Icon(
          Icons.edit_outlined,
          color: AppColors.primary,
          size: 20,
        ),
        tooltip: 'Chỉnh sửa',
        onPressed: () async {
          final updated = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => DeviceFormScreen(device: device)),
          );
          if (updated == true) _fetchDevices(page: _currentPage);
        },
      ),
      IconButton(
        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
        tooltip: 'Xóa thiết bị',
        onPressed: () => _deleteDevice(device),
      ),
    ];
  }

  Widget _buildCategoryChip(int? categoryId, String label) {
    final isSelected = _selectedCategoryId == categoryId;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: isSelected,
        onSelected: (_) {
          setState(() => _selectedCategoryId = categoryId);
          _onFilterChange();
        },
        selectedColor: AppColors.primary.withValues(alpha: 0.15),
        checkmarkColor: AppColors.primary,
        labelStyle: TextStyle(
          color: isSelected ? AppColors.primary : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        backgroundColor: Colors.white,
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.border,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
    );
  }

  Widget _buildStatusChip(String label, String value) {
    final isSelected = _selectedStatusFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: isSelected,
        onSelected: (_) {
          setState(() => _selectedStatusFilter = value);
          _onFilterChange();
        },
        selectedColor: AppColors.primary,
        checkmarkColor: Colors.white,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        backgroundColor: Colors.white,
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.border,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
    );
  }
}

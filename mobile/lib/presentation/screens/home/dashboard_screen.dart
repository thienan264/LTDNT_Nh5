import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/repositories/category_repository.dart';
import '../../../data/repositories/dashboard_repository.dart';
import '../../../data/repositories/device_repository.dart';
import '../../../data/repositories/member_repository.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/device_model.dart';
import '../../../data/models/user_model.dart';
import '../../widgets/cart_badge_icon.dart';
import '../../widgets/device_card.dart';
import '../admin/category_management_screen.dart';
import '../admin/user_management_screen.dart';
import '../auth/change_password_dialog.dart';
import '../devices/device_detail_screen.dart';
import '../devices/device_list_screen.dart';
import '../rentals/rental_list_screen.dart';
import '../scanner/qr_scanner_demo_screen.dart';
import '../units/unit_list_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<Map<String, dynamic>> _statsFuture;

  // Danh mục sản phẩm trên trang chủ
  List<CategoryModel> _categories = [];
  bool _isLoadingCategories = false;
  int? _selectedCategoryId;

  // Tìm kiếm & Sản phẩm mới nhất có phân trang trên trang chủ
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _productPage = 1;
  static const int _productLimit = 4;
  int _productTotalPages = 1;
  int _productTotalItems = 0;
  List<DeviceModel> _latestProducts = [];
  bool _isLoadingProducts = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadCategories();
    _fetchHomeProducts(page: 1);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadData() {
    setState(() {
      _statsFuture = DashboardRepository.getDashboardStats();
    });
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoadingCategories = true);
    try {
      final cats = await CategoryRepository.getCategories();
      if (!mounted) return;
      setState(() {
        _categories = cats;
        _isLoadingCategories = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingCategories = false);
    }
  }

  Future<void> _fetchHomeProducts({int page = 1}) async {
    setState(() {
      _isLoadingProducts = true;
      _productPage = page;
    });

    try {
      final res = await DeviceRepository.getDevicesPaged(
        search: _searchQuery,
        categoryId: _selectedCategoryId,
        page: page,
        limit: _productLimit,
      );

      if (!mounted) return;
      setState(() {
        _latestProducts = res['devices'] as List<DeviceModel>;
        _productTotalPages = res['total_pages'] as int;
        _productTotalItems = res['total_items'] as int;
        _isLoadingProducts = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingProducts = false);
    }
  }

  Future<void> _navigateTo(Widget screen) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    if (mounted) {
      _loadData();
      _loadCategories();
      _fetchHomeProducts(page: _productPage);
    }
  }

  void _showAccountBottomSheet(BuildContext context) {
    final user = MemberRepository.currentUser;
    if (user == null) return;
    final isAdmin = user.isAdmin;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: isAdmin
                        ? Colors.orange.withValues(alpha: 0.15)
                        : AppColors.primary.withValues(alpha: 0.15),
                    child: Icon(
                      isAdmin ? Icons.admin_panel_settings : Icons.person,
                      size: 30,
                      color: isAdmin ? Colors.orange : AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.fullName,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user.email,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isAdmin
                                ? Colors.orange.withValues(alpha: 0.15)
                                : AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isAdmin
                                ? '👑 VAI TRÒ: QUẢN TRỊ VIÊN (ADMIN)'
                                : '👤 VAI TRÒ: THÀNH VIÊN (MEMBER)',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isAdmin
                                  ? Colors.orange.shade800
                                  : AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 28),
              if (isAdmin) ...[
                ListTile(
                  leading: const Icon(
                    Icons.manage_accounts,
                    color: Colors.orange,
                  ),
                  title: const Text('Quản lý Thành viên & Phân quyền'),
                  subtitle: const Text(
                    'Xem danh sách, phân quyền Admin / Member',
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  contentPadding: EdgeInsets.zero,
                  onTap: () {
                    Navigator.pop(ctx);
                    _navigateTo(const UserManagementScreen());
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.category, color: AppColors.primary),
                  title: const Text('Quản lý Danh mục Thiết bị'),
                  subtitle: const Text('Thêm, sửa, xóa danh mục & upload ảnh'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  contentPadding: EdgeInsets.zero,
                  onTap: () {
                    Navigator.pop(ctx);
                    _navigateTo(const CategoryManagementScreen());
                  },
                ),
              ],
              ListTile(
                leading: const Icon(Icons.lock_reset, color: AppColors.primary),
                title: const Text('Đổi Mật Khẩu'),
                subtitle: const Text('Cập nhật mật khẩu đăng nhập mới'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                contentPadding: EdgeInsets.zero,
                onTap: () {
                  Navigator.pop(ctx);
                  showDialog(
                    context: context,
                    builder: (_) => const ChangePasswordDialog(),
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.logout,
                  color: AppColors.statusBroken,
                ),
                title: const Text(
                  'Đăng Xuất (Logout)',
                  style: TextStyle(
                    color: AppColors.statusBroken,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                contentPadding: EdgeInsets.zero,
                onTap: () {
                  Navigator.pop(ctx);
                  MemberRepository.logout();
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Quản lý Cho thuê Thiết bị'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.business_outlined, color: AppColors.primary),
            tooltip: 'Đơn vị thuê',
            onPressed: () => _navigateTo(const UnitListScreen()),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: AppColors.primary),
            onPressed: () => _navigateTo(const QrScannerDemoScreen()),
          ),
          const CartBadgeIcon(),
          IconButton(
            icon: const Icon(Icons.account_circle, color: AppColors.primary),
            tooltip: 'Tài khoản & Phân quyền',
            onPressed: () => _showAccountBottomSheet(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Greeting Banner
              ValueListenableBuilder<UserModel?>(
                valueListenable: MemberRepository.currentUserNotifier,
                builder: (context, user, _) {
                  if (user == null) return const SizedBox.shrink();
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: user.isAdmin
                              ? Colors.orange.withValues(alpha: 0.15)
                              : AppColors.primary.withValues(alpha: 0.15),
                          child: Icon(
                            user.isAdmin
                                ? Icons.admin_panel_settings
                                : Icons.person,
                            size: 20,
                            color: user.isAdmin
                                ? Colors.orange
                                : AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Xin chào, ${user.fullName}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                user.email,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: user.isAdmin
                                ? Colors.orange.withValues(alpha: 0.15)
                                : AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: user.isAdmin
                                  ? Colors.orange
                                  : AppColors.primary,
                            ),
                          ),
                          child: Text(
                            user.isAdmin ? '👑 ADMIN' : '👤 MEMBER',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: user.isAdmin
                                  ? Colors.orange.shade800
                                  : AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),

              // Thanh tìm kiếm sản phẩm trên trang chủ (có phân trang)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    _searchQuery = val.trim();
                    _fetchHomeProducts(page: 1);
                  },
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm sản phẩm, thiết bị, serial...',
                    hintStyle: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.primary,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear,
                              size: 20,
                              color: AppColors.textSecondary,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              _searchQuery = '';
                              _fetchHomeProducts(page: 1);
                              setState(() {});
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),

              // Welcome Banner
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hệ thống Điều phối & Quản lý Kho',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Công ty Cổ phần Xây lắp & Kỹ thuật',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () =>
                              _navigateTo(const QrScannerDemoScreen()),
                          icon: const Icon(Icons.qr_code_scanner, size: 18),
                          label: const Text('Quét mã kiểm kê'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () =>
                              _navigateTo(const CategoryManagementScreen()),
                          icon: const Icon(Icons.category_outlined, size: 18),
                          label: const Text('Danh mục thiết bị'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.25,
                            ),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Hiển thị danh mục sản phẩm (Bắt buộc)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Danh mục sản phẩm',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (MemberRepository.isAdmin)
                    TextButton.icon(
                      onPressed: () =>
                          _navigateTo(const CategoryManagementScreen()),
                      icon: const Icon(Icons.edit_note, size: 16),
                      label: const Text('Quản lý'),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              _buildCategorySelector(),
              const SizedBox(height: 20),

              // Statistics Grid & Alerts
              FutureBuilder<Map<String, dynamic>>(
                future: _statsFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Text(
                      'Không tải được thống kê từ API. Kiểm tra kết nối và đăng nhập lại.',
                    );
                  }
                  final stats =
                      snapshot.data ??
                      {
                        'total_devices': 0,
                        'rented_count': 0,
                        'available_count': 0,
                        'maintenance_count': 0,
                        'overdue_count': 0,
                        'due_soon_count': 0,
                        'total_deposit_holding': 0.0,
                        'estimated_revenue': 0.0,
                      };

                  final overdueCount = stats['overdue_count'] as int? ?? 0;
                  final dueSoonCount = stats['due_soon_count'] as int? ?? 0;
                  final totalDeposit =
                      (stats['total_deposit_holding'] as num?)?.toDouble() ??
                      0.0;
                  final estimatedRevenue =
                      (stats['estimated_revenue'] as num?)?.toDouble() ?? 0.0;
                  final currencyFmt = NumberFormat.currency(
                    locale: 'vi_VN',
                    symbol: 'đ',
                  );

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cảnh báo quá hạn
                      if (overdueCount > 0)
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RentalListScreen(),
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.red,
                                  size: 28,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Cảnh báo: Có $overdueCount hợp đồng thuê đã quá hạn!',
                                        style: const TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      const Text(
                                        'Chạm để xem và lập biên bản thu hồi thiết bị về kho.',
                                        style: TextStyle(
                                          color: Colors.black87,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right,
                                  color: Colors.red,
                                ),
                              ],
                            ),
                          ),
                        )
                      else if (dueSoonCount > 0)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.amber.shade300),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.timer_outlined,
                                color: Colors.orange,
                                size: 24,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Có $dueSoonCount hợp đồng sắp hết hạn trong 3 ngày tới.',
                                  style: const TextStyle(
                                    color: Colors.brown,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      const Text(
                        'Tổng quan Trạng thái Kho máy',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              title: 'Tổng thiết bị',
                              value: '${stats['total_devices']}',
                              color: AppColors.primary,
                              icon: Icons.inventory_2_outlined,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              title: 'Đang cho thuê',
                              value: '${stats['rented_count']}',
                              color: AppColors.statusRented,
                              icon: Icons.outbox,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              title: 'Sẵn sàng trong kho',
                              value: '${stats['available_count']}',
                              color: AppColors.statusAvailable,
                              icon: Icons.check_circle_outline,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              title: 'Bảo trì / Hỏng',
                              value: '${stats['maintenance_count']}',
                              color: AppColors.statusBroken,
                              icon: Icons.build_circle_outlined,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Chỉ số tài chính & tiền cọc
                      const Text(
                        'Tài chính & Tiền cọc dự án',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Doanh thu tạm tính',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      Icon(
                                        Icons.trending_up,
                                        color: Color(0xFF0D9488),
                                        size: 18,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    currencyFmt.format(estimatedRevenue),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0D9488),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Tiền cọc đang giữ',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      Icon(
                                        Icons.account_balance_wallet_outlined,
                                        color: AppColors.secondary,
                                        size: 18,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    currencyFmt.format(totalDeposit),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.secondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // Hiển thị sản phẩm mới nhất có phân trang trên trang chủ (Bắt buộc)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedCategoryId == null
                              ? 'Sản phẩm mới nhất'
                              : 'Sản phẩm: ${_categories.firstWhere((c) => c.id == _selectedCategoryId, orElse: () => const CategoryModel(id: 0, name: '')).name}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (_searchQuery.isNotEmpty)
                          Text(
                            'Kết quả tìm kiếm cho "$_searchQuery"',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                              fontStyle: FontStyle.italic,
                            ),
                          )
                        else
                          Text(
                            'Tìm thấy $_productTotalItems sản phẩm',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _navigateTo(const DeviceListScreen()),
                    icon: const Icon(Icons.list_alt, size: 16),
                    label: const Text('Xem tất cả'),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              if (_isLoadingProducts)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 36),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_latestProducts.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 40,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Không tìm thấy sản phẩm phù hợp.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _latestProducts.length,
                  itemBuilder: (context, index) {
                    final device = _latestProducts[index];
                    return DeviceCard(
                      device: device,
                      onTap: () =>
                          _navigateTo(DeviceDetailScreen(device: device)),
                    );
                  },
                ),

                // Phân trang sản phẩm trên trang chủ
                if (_productTotalPages > 1)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: _productPage > 1
                              ? () => _fetchHomeProducts(page: _productPage - 1)
                              : null,
                          color: _productPage > 1
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                        Text(
                          'Trang $_productPage / $_productTotalPages',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: _productPage < _productTotalPages
                              ? () => _fetchHomeProducts(page: _productPage + 1)
                              : null,
                          color: _productPage < _productTotalPages
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    if (_isLoadingCategories) {
      return const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // Ảnh, hai dòng chữ và padding cần đủ chỗ cả khi tăng cỡ chữ iPhone.
    final textScaler = MediaQuery.textScalerOf(context);
    final cardHeight =
        70 + textScaler.scale(12) * 1.4 + textScaler.scale(10) * 1.4;
    return SizedBox(
      height: cardHeight,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildCategoryCard(
            id: null,
            name: 'Tất cả DM',
            count: null,
            icon: Icons.grid_view_rounded,
          ),
          ..._categories.map(
            (c) => _buildCategoryCard(
              id: c.id,
              name: c.name,
              count: c.deviceCount,
              imageUrl: c.imageUrl,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard({
    required int? id,
    required String name,
    int? count,
    IconData? icon,
    String? imageUrl,
  }) {
    final isSelected = _selectedCategoryId == id;

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: () {
          setState(() => _selectedCategoryId = id);
          _fetchHomeProducts(page: 1);
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 110,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (imageUrl != null && imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrl.startsWith('http')
                        ? imageUrl
                        : '${ApiConstants.baseHost}$imageUrl',
                    width: 32,
                    height: 32,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.category_outlined,
                      size: 26,
                      color: isSelected ? Colors.white : AppColors.primary,
                    ),
                  ),
                )
              else
                Icon(
                  icon ?? Icons.category_outlined,
                  size: 28,
                  color: isSelected ? Colors.white : AppColors.primary,
                ),
              const SizedBox(height: 6),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              ),
              if (count != null)
                Text(
                  '$count thiết bị',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    height: 1.4,
                    color: isSelected
                        ? Colors.white70
                        : AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

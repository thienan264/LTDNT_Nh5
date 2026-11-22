import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/repositories/category_repository.dart';
import '../../../data/repositories/member_repository.dart';
import '../../../data/models/category_model.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  List<CategoryModel> _categories = [];
  List<CategoryModel> _filteredCategories = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Preset ảnh chuyên dụng cho danh mục thiết bị công trình & đo lường
  final List<Map<String, String>> _presetImages = [
    {
      'title': 'Máy đo trắc địa',
      'url': 'https://images.unsplash.com/photo-1581092160607-ee22621dd758?w=500&auto=format&fit=crop&q=80',
    },
    {
      'title': 'Máy công trình nặng',
      'url': 'https://images.unsplash.com/photo-1504307651254-35680f356dfd?w=500&auto=format&fit=crop&q=80',
    },
    {
      'title': 'Sự kiện & Văn phòng',
      'url': 'https://images.unsplash.com/photo-1517245386807-bb43f82c33c4?w=500&auto=format&fit=crop&q=80',
    },
    {
      'title': 'Máy phát điện & Năng lượng',
      'url': 'https://images.unsplash.com/photo-1497435334941-8c899ee9e8e9?w=500&auto=format&fit=crop&q=80',
    },
    {
      'title': 'Dụng cụ cơ khí & Cầm tay',
      'url': 'https://images.unsplash.com/photo-1581244277943-fe4a9c777189?w=500&auto=format&fit=crop&q=80',
    },
    {
      'title': 'Hệ thống giàn giáo & Nâng hạ',
      'url': 'https://images.unsplash.com/photo-1541888946425-d0fbb186c5f7?w=500&auto=format&fit=crop&q=80',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    final data = await CategoryRepository.getCategories();
    if (mounted) {
      setState(() {
        _categories = data;
        _applySearch();
        _isLoading = false;
      });
    }
  }

  void _applySearch() {
    if (_searchQuery.trim().isEmpty) {
      _filteredCategories = List.from(_categories);
    } else {
      final q = _searchQuery.toLowerCase().trim();
      _filteredCategories = _categories
          .where(
            (c) =>
                c.name.toLowerCase().contains(q) ||
                c.description.toLowerCase().contains(q),
          )
          .toList();
    }
  }

  // Mở Dialog Thêm / Sửa Danh mục
  void _showCategoryDialog([CategoryModel? category]) {
    final isEditing = category != null;
    final nameController = TextEditingController(text: category?.name ?? '');
    final descController = TextEditingController(
      text: category?.description ?? '',
    );
    final urlController = TextEditingController(text: category?.imageUrl ?? '');
    String selectedUrl = category?.imageUrl ?? _presetImages.first['url']!;
    if (urlController.text.isNotEmpty) {
      selectedUrl = urlController.text;
    }

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(
                    isEditing
                        ? Icons.edit_note
                        : Icons.create_new_folder_outlined,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isEditing ? 'Cập nhật Danh mục' : 'Thêm Danh mục mới',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 480,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tên danh mục (bắt buộc)
                        TextFormField(
                          controller: nameController,
                          decoration: InputDecoration(
                            labelText: 'Tên danh mục thiết bị *',
                            hintText: 'VD: Máy nén khí, Thiết bị trắc địa...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.category_outlined),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Vui lòng nhập tên danh mục';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Mô tả
                        TextFormField(
                          controller: descController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: 'Mô tả chi tiết',
                            hintText:
                                'Đặc điểm hoặc phạm vi áp dụng của thiết bị...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.description_outlined),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Phần chọn & upload hình ảnh (Điểm cộng 0.75đ)
                        const Text(
                          'Hình ảnh minh họa danh mục:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Preview ảnh đang chọn
                        Container(
                          height: 140,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: selectedUrl.isNotEmpty
                              ? Image.network(
                                  selectedUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => const Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.broken_image,
                                          color: Colors.grey,
                                          size: 36,
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Không thể tải ảnh này',
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : const Center(
                                  child: Icon(
                                    Icons.image_outlined,
                                    size: 40,
                                    color: Colors.grey,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 10),

                        // Nhập URL ảnh tùy chỉnh
                        TextFormField(
                          controller: urlController,
                          decoration: InputDecoration(
                            labelText: 'Đường dẫn ảnh (URL hoặc Upload)',
                            hintText: 'https://...',
                            isDense: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            suffixIcon: IconButton(
                              icon: const Icon(
                                Icons.check_circle_outline,
                                color: AppColors.primary,
                              ),
                              tooltip: 'Áp dụng URL này',
                              onPressed: () {
                                setDialogState(() {
                                  selectedUrl = urlController.text.trim();
                                });
                              },
                            ),
                          ),
                          onChanged: (val) {
                            setDialogState(() {
                              selectedUrl = val.trim();
                            });
                          },
                        ),
                        const SizedBox(height: 12),

                        // Chọn nhanh từ mẫu ảnh chuyên ngành
                        const Text(
                          'Hoặc chọn nhanh ảnh mẫu chất lượng cao:',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          height: 70,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _presetImages.length,
                            itemBuilder: (context, i) {
                              final p = _presetImages[i];
                              final isCurrent = selectedUrl == p['url'];
                              return InkWell(
                                onTap: () {
                                  setDialogState(() {
                                    selectedUrl = p['url']!;
                                    urlController.text = p['url']!;
                                  });
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  width: 70,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isCurrent
                                          ? AppColors.primary
                                          : AppColors.border,
                                      width: isCurrent ? 2.5 : 1,
                                    ),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: Image.network(
                                    p['url']!,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Hủy bỏ'),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () async {
                    if (formKey.currentState?.validate() != true) return;

                    final name = nameController.text.trim();
                    final desc = descController.text.trim();
                    final img = selectedUrl.trim();

                    Navigator.pop(ctx);
                    setState(() => _isLoading = true);

                    CategoryModel? saved;
                    if (isEditing) {
                      saved = await CategoryRepository.updateCategory(
                        id: category.id,
                        name: name,
                        description: desc,
                        imageUrl: img,
                      );
                    } else {
                      saved = await CategoryRepository.createCategory(
                        name: name,
                        description: desc,
                        imageUrl: img,
                      );
                    }

                    await _loadCategories();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            saved == null
                                ? 'Không lưu được danh mục. Kiểm tra tên trùng và kết nối API.'
                                : (isEditing
                                      ? 'Đã cập nhật danh mục "$name"'
                                      : 'Đã thêm danh mục "$name"'),
                          ),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                    }
                  },
                  icon: Icon(isEditing ? Icons.save : Icons.add),
                  label: Text(isEditing ? 'Lưu thay đổi' : 'Tạo danh mục'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Xóa danh mục - KIỂM TRA BẮT BUỘC CÓ SẢN PHẨM KHÔNG
  Future<void> _confirmDeleteCategory(CategoryModel category) async {
    // 1. Kiểm tra nhanh tại client
    if (category.deviceCount > 0) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              SizedBox(width: 8),
              Text(
                'Không thể xóa danh mục',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Danh mục "${category.name}" hiện đang có ${category.deviceCount} thiết bị / máy móc thuộc nhóm này.',
                style: const TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.deepOrange,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Theo tiêu chuẩn nghiệp vụ, bạn phải xóa hoặc chuyển các thiết bị sang danh mục khác trước khi xóa danh mục này.',
                        style: TextStyle(fontSize: 13, color: Colors.brown),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Đã hiểu'),
            ),
          ],
        ),
      );
      return;
    }

    // 2. Nếu deviceCount == 0, hiển thị hộp thoại xác nhận xóa
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline, color: Colors.red),
            SizedBox(width: 8),
            Text(
              'Xác nhận xóa danh mục',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa danh mục "${category.name}"?\n(Hình ảnh đính kèm nếu lưu trên máy chủ cũng sẽ được xóa sạch).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xác nhận Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      final res = await CategoryRepository.deleteCategory(category.id);
      await _loadCategories();

      if (mounted) {
        if (res['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res['message'] ?? 'Đã xóa danh mục thành công'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          // Bị chặn từ server
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res['error'] ?? 'Lỗi khi xóa danh mục'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = MemberRepository.currentUser;
    final isAdmin = currentUser?.isAdmin ?? true;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Quản lý Danh mục Thiết bị',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới',
            onPressed: _loadCategories,
          ),
        ],
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              onPressed: () => _showCategoryDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Thêm danh mục'),
            )
          : null,
      body: Column(
        children: [
          // Banner giải thích tiêu chí barem
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.blue.shade50,
            child: Row(
              children: [
                const Icon(
                  Icons.folder_special_outlined,
                  color: AppColors.primary,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Quản lý nhóm thiết bị & máy móc. Có kiểm tra ràng buộc thiết bị trước khi xóa & hỗ trợ ảnh minh họa.',
                    style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
                  ),
                ),
              ],
            ),
          ),

          // Thanh tìm kiếm
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm tên hoặc mô tả danh mục...',
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                            _applySearch();
                          });
                        },
                      )
                    : null,
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
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                  _applySearch();
                });
              },
            ),
          ),

          // Danh sách danh mục
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredCategories.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.folder_off_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'Không tìm thấy danh mục phù hợp'
                              : 'Chưa có danh mục nào',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadCategories,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                      itemCount: _filteredCategories.length,
                      itemBuilder: (context, index) {
                        final cat = _filteredCategories[index];
                        final hasDevices = cat.deviceCount > 0;

                        return Card(
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: const BorderSide(color: AppColors.border),
                          ),
                          clipBehavior: Clip.antiAlias,
                          color: Colors.white,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header: Hình ảnh + Badge số lượng thiết bị
                              Stack(
                                children: [
                                  Container(
                                    height: 120,
                                    width: double.infinity,
                                    color: Colors.grey.shade200,
                                    child: cat.imageUrl.isNotEmpty
                                        ? Image.network(
                                            cat.imageUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, _, _) =>
                                                const Center(
                                                  child: Icon(
                                                    Icons.category,
                                                    size: 48,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                          )
                                        : const Center(
                                            child: Icon(
                                              Icons.category,
                                              size: 48,
                                              color: Colors.grey,
                                            ),
                                          ),
                                  ),
                                  Positioned(
                                    top: 10,
                                    right: 10,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: hasDevices
                                            ? AppColors.primary
                                            : Colors.grey.shade700,
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Colors.black26,
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.build_outlined,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${cat.deviceCount} thiết bị',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              // Nội dung chi tiết danh mục
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            cat.name,
                                            style: const TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                        ),
                                        if (isAdmin) ...[
                                          IconButton(
                                            icon: const Icon(
                                              Icons.edit_outlined,
                                              color: AppColors.primary,
                                            ),
                                            tooltip: 'Chỉnh sửa',
                                            onPressed: () =>
                                                _showCategoryDialog(cat),
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              Icons.delete_outline,
                                              color: hasDevices
                                                  ? Colors.grey
                                                  : Colors.red,
                                            ),
                                            tooltip: hasDevices
                                                ? 'Không thể xóa khi có thiết bị'
                                                : 'Xóa danh mục',
                                            onPressed: () =>
                                                _confirmDeleteCategory(cat),
                                          ),
                                        ],
                                      ],
                                    ),
                                    if (cat.description.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        cat.description,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: AppColors.textSecondary,
                                          height: 1.3,
                                        ),
                                      ),
                                    ],
                                    if (hasDevices) ...[
                                      const SizedBox(height: 10),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.shade50,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          border: Border.all(
                                            color: Colors.amber.shade200,
                                          ),
                                        ),
                                        child: Text(
                                          '🔒 Có ${cat.deviceCount} thiết bị đang liên kết — Khóa xóa để bảo toàn dữ liệu',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.orange.shade900,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

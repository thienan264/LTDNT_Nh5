import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/repositories/member_repository.dart';
import '../../../data/models/user_model.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<UserModel> _users = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  void _loadUsers() async {
    setState(() => _isLoading = true);
    final users = await MemberRepository.getUsers();
    if (!mounted) return;
    setState(() {
      _users = users;
      _isLoading = false;
    });
  }

  void _changeRole(UserModel user, String newRole) async {
    final success = await MemberRepository.updateUserRole(user.id, newRole);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã cập nhật quyền của ${user.fullName} thành $newRole!',
          ),
          backgroundColor: AppColors.statusAvailable,
        ),
      );
      _loadUsers();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Có lỗi xảy ra khi cập nhật phân quyền.'),
          backgroundColor: AppColors.statusBroken,
        ),
      );
    }
  }

  void _deleteUser(UserModel user) async {
    if (user.id == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể xóa Quản trị viên gốc!'),
          backgroundColor: AppColors.statusBroken,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận Xóa Thành viên'),
        content: Text(
          'Bạn có chắc chắn muốn xóa thành viên "${user.fullName}" (${user.username}) khỏi hệ thống?',
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

    final success = await MemberRepository.deleteUser(user.id);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã xóa thành viên thành công!'),
          backgroundColor: AppColors.statusAvailable,
        ),
      );
      _loadUsers();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredUsers = _users.where((u) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return u.fullName.toLowerCase().contains(q) ||
          u.username.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Quản lý Thành viên & Phân quyền'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: _loadUsers,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm kiếm theo tên, username hoặc email...',
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.textSecondary,
                ),
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
            ),
          ),
          const Divider(height: 1),

          // User list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredUsers.isEmpty
                ? const Center(child: Text('Không tìm thấy thành viên nào.'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index];
                      final isAdmin = user.isAdmin;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: CircleAvatar(
                            radius: 24,
                            backgroundColor: isAdmin
                                ? Colors.orange.withValues(alpha: 0.15)
                                : AppColors.primary.withValues(alpha: 0.15),
                            child: Icon(
                              isAdmin
                                  ? Icons.admin_panel_settings
                                  : Icons.person,
                              color: isAdmin
                                  ? Colors.orange
                                  : AppColors.primary,
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  user.fullName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: isAdmin
                                      ? Colors.orange.withValues(alpha: 0.15)
                                      : AppColors.primary.withValues(
                                          alpha: 0.1,
                                        ),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isAdmin
                                        ? Colors.orange
                                        : AppColors.primary,
                                  ),
                                ),
                                child: Text(
                                  isAdmin ? '👑 ADMIN' : '👤 MEMBER',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isAdmin
                                        ? Colors.orange.shade800
                                        : AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Username: ${user.username} • SĐT: ${user.phoneNumber.isEmpty ? "Chưa có" : user.phoneNumber}',
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Email: ${user.email}',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          trailing: PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert),
                            onSelected: (action) {
                              if (action == 'SET_ADMIN') {
                                _changeRole(user, 'ADMIN');
                              } else if (action == 'SET_MEMBER') {
                                _changeRole(user, 'MEMBER');
                              } else if (action == 'DELETE') {
                                _deleteUser(user);
                              }
                            },
                            itemBuilder: (ctx) => [
                              if (!isAdmin)
                                const PopupMenuItem(
                                  value: 'SET_ADMIN',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.shield,
                                        color: Colors.orange,
                                        size: 20,
                                      ),
                                      SizedBox(width: 8),
                                      Text('Nâng cấp thành Admin'),
                                    ],
                                  ),
                                )
                              else
                                const PopupMenuItem(
                                  value: 'SET_MEMBER',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.person,
                                        color: AppColors.primary,
                                        size: 20,
                                      ),
                                      SizedBox(width: 8),
                                      Text('Hạ quyền về Member'),
                                    ],
                                  ),
                                ),
                              const PopupMenuDivider(),
                              const PopupMenuItem(
                                value: 'DELETE',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete_outline,
                                      color: AppColors.statusBroken,
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Xóa tài khoản',
                                      style: TextStyle(
                                        color: AppColors.statusBroken,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

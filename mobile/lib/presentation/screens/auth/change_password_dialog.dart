import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/repositories/member_repository.dart';

class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({super.key});

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isSaving = false;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleChangePassword() async {
    if (!_formKey.currentState!.validate()) return;

    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mật khẩu mới xác nhận không khớp!'),
          backgroundColor: AppColors.statusBroken,
        ),
      );
      return;
    }

    final currentUser = MemberRepository.currentUser;
    if (currentUser == null) return;

    setState(() => _isSaving = true);
    final res = await MemberRepository.changePassword(
      userId: currentUser.id,
      oldPassword: _oldPasswordController.text.trim(),
      newPassword: _newPasswordController.text.trim(),
    );
    setState(() => _isSaving = false);

    if (!mounted) return;

    if (res['success'] == true) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            res['message'] as String? ?? 'Đổi mật khẩu thành công!',
          ),
          backgroundColor: AppColors.statusAvailable,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] as String? ?? 'Đổi mật khẩu thất bại'),
          backgroundColor: AppColors.statusBroken,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.password_rounded, color: AppColors.primary),
          SizedBox(width: 8),
          Text('Đổi Mật Khẩu'),
        ],
      ),
      content: SizedBox(
        width: 380,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _oldPasswordController,
                obscureText: _obscureOld,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu hiện tại *',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureOld ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () => setState(() => _obscureOld = !_obscureOld),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (val) => (val == null || val.trim().isEmpty)
                    ? 'Vui lòng nhập mật khẩu cũ'
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _newPasswordController,
                obscureText: _obscureNew,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu mới *',
                  prefixIcon: const Icon(Icons.lock_reset),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNew ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () => setState(() => _obscureNew = !_obscureNew),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Vui lòng nhập mật khẩu mới';
                  }
                  if (val.length < 6) return 'Mật khẩu mới từ 6 ký tự trở lên';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  labelText: 'Xác nhận mật khẩu mới *',
                  prefixIcon: const Icon(Icons.check_circle_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (val) => (val == null || val.trim().isEmpty)
                    ? 'Vui lòng xác nhận mật khẩu mới'
                    : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          onPressed: _isSaving ? null : _handleChangePassword,
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text('Lưu thay đổi'),
        ),
      ],
    );
  }
}

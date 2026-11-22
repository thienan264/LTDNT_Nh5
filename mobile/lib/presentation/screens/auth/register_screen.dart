import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/repositories/member_repository.dart';

class RegisterScreen extends StatefulWidget {
  final VoidCallback onRegisterSuccess;

  const RegisterScreen({super.key, required this.onRegisterSuccess});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mật khẩu xác nhận không khớp!'),
          backgroundColor: AppColors.statusBroken,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await MemberRepository.register(
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      fullName: _fullNameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message'] as String? ?? 'Đăng ký tài khoản thành công!',
          ),
          backgroundColor: AppColors.statusAvailable,
        ),
      );
      Navigator.pop(context);
      widget.onRegisterSuccess();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] as String? ?? 'Đăng ký thất bại'),
          backgroundColor: AppColors.statusBroken,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Đăng ký Tài khoản'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Thông tin Người dùng / Đơn vị',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Tài khoản mới sẽ được cấp quyền Member (Khách thuê / Kỹ thuật viên đơn vị)',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Họ tên
                      TextFormField(
                        controller: _fullNameController,
                        decoration: InputDecoration(
                          labelText: 'Họ và tên *',
                          hintText: 'VD: Nguyễn Văn An',
                          prefixIcon: const Icon(Icons.badge_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (val) => (val == null || val.trim().isEmpty)
                            ? 'Vui lòng nhập họ và tên'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // Username
                      TextFormField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: 'Tên đăng nhập *',
                          hintText: 'VD: nguyenvana',
                          prefixIcon: const Icon(Icons.person_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (val) => (val == null || val.trim().isEmpty)
                            ? 'Vui lòng nhập tên đăng nhập'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // Email
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Địa chỉ Email *',
                          hintText: 'VD: an.nguyen@example.com',
                          prefixIcon: const Icon(Icons.email_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Vui lòng nhập email';
                          }
                          if (!val.contains('@') || !val.contains('.')) {
                            return 'Email không hợp lệ';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Số điện thoại
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Số điện thoại *',
                          hintText: 'VD: 0901234567',
                          prefixIcon: const Icon(Icons.phone_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (val) => (val == null || val.trim().isEmpty)
                            ? 'Vui lòng nhập số điện thoại'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // Mật khẩu
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Mật khẩu *',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Vui lòng nhập mật khẩu';
                          }
                          if (val.length < 6) {
                            return 'Mật khẩu phải từ 6 ký tự trở lên';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Xác nhận Mật khẩu
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        decoration: InputDecoration(
                          labelText: 'Xác nhận lại mật khẩu *',
                          prefixIcon: const Icon(Icons.lock_reset),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () => setState(
                              () => _obscureConfirmPassword =
                                  !_obscureConfirmPassword,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (val) => (val == null || val.trim().isEmpty)
                            ? 'Vui lòng xác nhận mật khẩu'
                            : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Nút Đăng ký
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Đăng ký tài khoản',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

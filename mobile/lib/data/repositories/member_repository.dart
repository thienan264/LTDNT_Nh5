import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../core/constants/api_constants.dart';
import '../models/user_model.dart';

class MemberRepository {
  static final http.Client _client = http.Client();

  // Observable user state for reactive UI updates
  static final ValueNotifier<UserModel?> currentUserNotifier =
      ValueNotifier<UserModel?>(null);

  static UserModel? get currentUser => currentUserNotifier.value;
  static bool get isAdmin => currentUser?.isAdmin ?? false;

  static Map<String, String> get authHeaders {
    final headers = {'Content-Type': 'application/json'};
    if (currentUser?.token != null && currentUser!.token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer ${currentUser!.token}';
    }
    return headers;
  }

  // 1. ĐĂNG NHẬP
  static Future<Map<String, dynamic>> login(
    String usernameOrEmail,
    String password,
  ) async {
    String email = usernameOrEmail.trim();
    if (!email.contains('@')) {
      if (email.toLowerCase() == 'admin') {
        email = 'admin@rental.com';
      } else if (email.toLowerCase() == 'member') {
        email = 'member@rental.com';
      } else {
        email = '$email@rental.com';
      }
    }

    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/auth/login');
      final response = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password.trim()}),
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final token = data['token'] as String?;
        final userJson = data['user'] as Map<String, dynamic>;
        final user = UserModel.fromJson(userJson, token: token);
        currentUserNotifier.value = user;
        return {
          'success': true,
          'message': 'Đăng nhập thành công',
          'user': user,
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message':
              data['message'] ?? 'Đăng nhập thất bại (${response.statusCode})',
        };
      }
    } catch (e) {
      debugPrint('[MemberRepository] Login failed: $e');
    }

    return {
      'success': false,
      'message': 'Không kết nối được API. Kiểm tra server và mạng.',
    };
  }

  // 2. ĐĂNG KÝ
  static Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
    String? address,
  }) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/auth/register');
      final response = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'fullName': fullName.trim(),
              'email': email.trim().toLowerCase(),
              'password': password.trim(),
              'phoneNumber': phoneNumber.trim(),
              'address': address ?? 'Hà Nội',
            }),
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final token = data['token'] as String?;
        final userJson = data['user'] as Map<String, dynamic>;
        final user = UserModel.fromJson(userJson, token: token);
        currentUserNotifier.value = user;
        return {'success': true, 'message': 'Đăng ký thành công', 'user': user};
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Đăng ký thất bại',
        };
      }
    } catch (e) {
      debugPrint('[MemberRepository] Live register failed: $e');
    }

    return {
      'success': false,
      'message': 'Không kết nối được API, chưa tạo tài khoản.',
    };
  }

  // 3. ĐỔI MẬT KHẨU
  static Future<Map<String, dynamic>> changePassword({
    required int userId,
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/auth/change-password');
      final response = await _client
          .post(
            uri,
            headers: authHeaders,
            body: jsonEncode({
              'currentPassword': oldPassword.trim(),
              'newPassword': newPassword.trim(),
            }),
          )
          .timeout(const Duration(seconds: 4));

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200,
        'message':
            data['message'] ??
            (response.statusCode == 200
                ? 'Đổi mật khẩu thành công'
                : 'Đổi mật khẩu thất bại'),
      };
    } catch (_) {}

    return {
      'success': false,
      'message': 'Không kết nối được API, chưa đổi mật khẩu.',
    };
  }

  // 4. LẤY DANH SÁCH USER (ADMIN)
  static Future<List<UserModel>> getUsers() async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/users?pageSize=50');
      final response = await _client
          .get(uri, headers: authHeaders)
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = (data['items'] ?? data['data'] ?? data) as List;
        return list
            .map((item) => UserModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('[MemberRepository] getUsers error: $e');
    }

    return [];
  }

  // 5. CẬP NHẬT ROLE (ADMIN)
  static Future<bool> updateUserRole(int userId, String newRole) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/users/$userId/roles');
      final response = await _client
          .put(
            uri,
            headers: authHeaders,
            body: jsonEncode({
              'roles': [newRole.toUpperCase() == 'ADMIN' ? 'Admin' : 'Member'],
            }),
          )
          .timeout(const Duration(seconds: 4));

      return response.statusCode == 200;
    } catch (_) {}
    return false;
  }

  // 6. KHÓA / MỞ KHÓA USER (ADMIN)
  static Future<bool> updateUserStatus(int userId, bool isActive) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/users/$userId/status');
      final response = await _client
          .put(
            uri,
            headers: authHeaders,
            body: jsonEncode({'isActive': isActive}),
          )
          .timeout(const Duration(seconds: 4));

      return response.statusCode == 200;
    } catch (_) {}
    return false;
  }

  // 7. XÓA / VÔ HIỆU HÓA USER (ADMIN)
  static Future<bool> deleteUser(int userId) async {
    return await updateUserStatus(userId, false);
  }

  // 8. QUÊN MẬT KHẨU
  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    return {
      'success': false,
      'message': 'Chức năng khôi phục qua email chưa được triển khai.',
    };
  }

  // 9. ĐĂNG XUẤT
  static void logout() {
    currentUserNotifier.value = null;
  }
}

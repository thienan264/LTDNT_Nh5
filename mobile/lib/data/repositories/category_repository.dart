import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/constants/api_constants.dart';
import 'member_repository.dart';
import '../models/category_model.dart';
import '../datasources/local_db_helper.dart';
import 'file_repository.dart';

class CategoryRepository {
  static Future<List<CategoryModel>> getCategories() async {
    try {
      var response = await http
          .get(
            Uri.parse('${ApiConstants.baseUrl}/categories'),
            headers: MemberRepository.authHeaders,
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        throw Exception('Không tải được danh mục');
      }
      List data = jsonDecode(response.body);
      var list = data.map((p) => CategoryModel.fromJson(p)).toList();
      await LocalDbHelper.instance.cacheCategories(list);
      return list;
    } catch (_) {
      return LocalDbHelper.instance.getCachedCategories();
    }
  }

  static Future<CategoryModel?> createCategory({
    required String name,
    required String description,
    String? imageUrl,
    String? imageBase64,
  }) async {
    try {
      var response = await http
          .post(
            Uri.parse('${ApiConstants.baseUrl}/categories'),
            headers: MemberRepository.authHeaders,
            body: jsonEncode({
              'name': name,
              'description': description,
              'imageUrl': imageUrl,
            }),
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 201) return null;
      var data = jsonDecode(response.body);
      if (imageBase64 != null) {
        data['imageUrl'] = await FileRepository.upload(
          'categories',
          data['id'],
          imageBase64,
        );
      }
      return CategoryModel.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  static Future<CategoryModel?> updateCategory({
    required int id,
    required String name,
    required String description,
    String? imageUrl,
    String? imageBase64,
  }) async {
    try {
      var response = await http
          .put(
            Uri.parse('${ApiConstants.baseUrl}/categories/$id'),
            headers: MemberRepository.authHeaders,
            body: jsonEncode({
              'name': name,
              'description': description,
              'imageUrl': FileRepository.relativeUrl(imageUrl),
              'isActive': true,
            }),
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;
      var data = jsonDecode(response.body);
      if (imageBase64 != null) {
        data['imageUrl'] = await FileRepository.upload(
          'categories',
          id,
          imageBase64,
        );
      }
      return CategoryModel.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>> deleteCategory(int id) async {
    try {
      var response = await http
          .delete(
            Uri.parse('${ApiConstants.baseUrl}/categories/$id'),
            headers: MemberRepository.authHeaders,
          )
          .timeout(const Duration(seconds: 10));
      var data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200,
        'error': data['message'],
        'message': data['message'],
      };
    } catch (_) {
      return {'success': false, 'error': 'Không kết nối được API'};
    }
  }
}

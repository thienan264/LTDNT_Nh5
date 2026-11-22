import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/constants/api_constants.dart';
import 'member_repository.dart';
import '../models/device_model.dart';
import 'file_repository.dart';

class DeviceRepository {
  static Future<Map<String, dynamic>> getDevicesPaged({
    String? status,
    String? search,
    int? categoryId,
    int page = 1,
    int limit = 10,
  }) async {
    var query = {'pageIndex': '$page', 'pageSize': '$limit'};
    if (status == 'MINE') {
      query['onlyMine'] = 'true';
    } else if (status != null && status != 'ALL') {
      query['status'] = status;
    }
    if (search != null && search.isNotEmpty) query['keyword'] = search;
    if (categoryId != null) query['categoryId'] = '$categoryId';
    var uri = Uri.parse('${ApiConstants.baseUrl}/devices')
        .replace(queryParameters: query);
    var response = await http
        .get(uri, headers: MemberRepository.authHeaders)
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw Exception('Không tải được thiết bị (${response.statusCode})');
    }
    var data = jsonDecode(response.body);
    return {
      'devices': (data['items'] as List)
          .map((p) => DeviceModel.fromJson(p))
          .toList(),
      'total_pages': data['totalPages'],
      'total_items': data['totalCount'],
      'current_page': page,
    };
  }

  static Future<List<DeviceModel>> getDevices({
    String? status,
    String? search,
  }) async {
    var data = await getDevicesPaged(
      status: status,
      search: search,
      limit: 100,
    );
    return data['devices'] as List<DeviceModel>;
  }

  static Future<Map<String, dynamic>> getRelatedDevicesPaged({
    required int deviceId,
    int page = 1,
    int limit = 5,
  }) async {
    var response = await http
        .get(
          Uri.parse(
            '${ApiConstants.baseUrl}/devices/$deviceId/related?pageIndex=$page&pageSize=$limit',
          ),
          headers: MemberRepository.authHeaders,
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw Exception('Không tải được thiết bị liên quan');
    }
    var data = jsonDecode(response.body);
    return {
      'devices': (data['items'] as List)
          .map((p) => DeviceModel.fromJson(p))
          .toList(),
      'total_pages': data['totalPages'],
      'total_items': data['totalCount'],
      'current_page': page,
    };
  }

  static Future<bool> createDevice({
    required String name,
    required String serialNumber,
    required int categoryId,
    required double rentalPricePerDay,
    DeviceStatus? status,
    String? qrCode,
    String? imageBase64,
    String? imageUrl,
  }) async {
    try {
      var response = await http
          .post(
            Uri.parse('${ApiConstants.baseUrl}/devices'),
            headers: MemberRepository.authHeaders,
            body: jsonEncode({
              'name': name,
              'serialNumber': serialNumber,
              'categoryId': categoryId,
              'rentalPricePerDay': rentalPricePerDay,
              'status': (status ?? DeviceStatus.available).name,
              'qrCode': qrCode ?? 'DEV-$serialNumber',
              'imageUrl': imageUrl,
            }),
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 201) return false;
      if (imageBase64 != null) {
        int id = jsonDecode(response.body)['id'];
        try {
          await FileRepository.upload('devices', id, imageBase64);
        } catch (_) {
          await http.delete(
            Uri.parse('${ApiConstants.baseUrl}/devices/$id'),
            headers: MemberRepository.authHeaders,
          );
          return false;
        }
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> updateDevice({
    required int id,
    required String name,
    required String serialNumber,
    required int categoryId,
    required double rentalPricePerDay,
    DeviceStatus? status,
    String? imageBase64,
    String? imageUrl,
  }) async {
    try {
      // Giữ ảnh cũ tới khi ảnh mới upload thành công.
      var oldResponse = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/devices/$id'),
        headers: MemberRepository.authHeaders,
      );
      if (oldResponse.statusCode != 200) return false;
      var old = jsonDecode(oldResponse.body);
      var response = await http
          .put(
            Uri.parse('${ApiConstants.baseUrl}/devices/$id'),
            headers: MemberRepository.authHeaders,
            body: jsonEncode({
              'name': name,
              'serialNumber': serialNumber,
              'categoryId': categoryId,
              'unitId': old['unitId'],
              'rentalPricePerDay': rentalPricePerDay,
              'status': (status ?? DeviceStatus.available).name,
              'qrCode': old['qrCode'],
              'imageUrl': imageBase64 != null
                  ? old['imageUrl']
                  : FileRepository.relativeUrl(imageUrl),
              'isActive': true,
            }),
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return false;
      if (imageBase64 != null) {
        await FileRepository.upload('devices', id, imageBase64);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> deleteDeviceWithError(int id) async {
    try {
      var response = await http
          .delete(
            Uri.parse('${ApiConstants.baseUrl}/devices/$id'),
            headers: MemberRepository.authHeaders,
          )
          .timeout(const Duration(seconds: 10));
      var data = jsonDecode(response.body);
      return {'success': response.statusCode == 200, 'error': data['message']};
    } catch (_) {
      return {'success': false, 'error': 'Không kết nối được API'};
    }
  }

  static Future<Map<String, dynamic>> updateDeviceStatus(
    int deviceId,
    DeviceStatus newStatus,
  ) async {
    try {
      final response = await http
          .put(
            Uri.parse('${ApiConstants.baseUrl}/devices/$deviceId/status'),
            headers: MemberRepository.authHeaders,
            body: jsonEncode({'status': newStatus.name}),
          )
          .timeout(const Duration(seconds: 15));
      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200,
        'message':
            data['message'] ??
            (response.statusCode == 200
                ? 'Đã cập nhật thiết bị'
                : 'Không cập nhật được thiết bị (${response.statusCode}).'),
      };
    } catch (_) {
      return {
        'success': false,
        'message': 'Không kết nối được API. Kiểm tra backend và thử lại.',
      };
    }
  }

  static Future<DeviceModel?> lookupDevice(String codeOrId) async {
    try {
      if (int.tryParse(codeOrId) != null) {
        var response = await http
            .get(
              Uri.parse('${ApiConstants.baseUrl}/devices/$codeOrId'),
              headers: MemberRepository.authHeaders,
            )
            .timeout(const Duration(seconds: 10));
        return response.statusCode == 200
            ? DeviceModel.fromJson(jsonDecode(response.body))
            : null;
      }
      var response = await http
          .get(
            Uri.parse('${ApiConstants.baseUrl}/devices/lookup')
                .replace(queryParameters: {'code': codeOrId}),
            headers: MemberRepository.authHeaders,
          )
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200
          ? DeviceModel.fromJson(jsonDecode(response.body))
          : null;
    } catch (_) {
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getDeviceHistory(
    int deviceId,
  ) async {
    var response = await http
        .get(
          Uri.parse('${ApiConstants.baseUrl}/devices/$deviceId/history'),
          headers: MemberRepository.authHeaders,
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw Exception('Không tải được lịch sử thiết bị');
    }
    return (jsonDecode(response.body) as List)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
}

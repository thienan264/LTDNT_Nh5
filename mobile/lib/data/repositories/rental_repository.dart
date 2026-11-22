import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/constants/api_constants.dart';
import 'member_repository.dart';
import '../models/rental_model.dart';
import '../models/cart_item_model.dart';

class RentalRepository {
  static Future<List<RentalModel>> getRentals() async {
    String route = MemberRepository.isAdmin
        ? 'rentals?pageSize=100'
        : 'rentals/my';
    var response = await http
        .get(
          Uri.parse('${ApiConstants.baseUrl}/$route'),
          headers: MemberRepository.authHeaders,
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw Exception('Không tải được hợp đồng (${response.statusCode})');
    }
    var data = jsonDecode(response.body);
    List list = data is List ? data : data['items'];
    return list.map((p) => RentalModel.fromJson(p)).toList();
  }

  static Future<RentalModel?> createRental({
    required int unitId,
    required DateTime startDate,
    required DateTime expectedEndDate,
    required List<int> deviceIds,
    String? notes,
    List<CartItemModel>? cartItems,
  }) async {
    try {
      final days = expectedEndDate.difference(startDate).inDays;
      var items = cartItems != null
          ? cartItems
                .map(
                  (i) => {'deviceId': i.device.id, 'rentalDays': i.rentalDays},
                )
                .toList()
          : deviceIds
                .map((id) => {'deviceId': id, 'rentalDays': days})
                .toList();
      var response = await http
          .post(
            Uri.parse('${ApiConstants.baseUrl}/rentals/checkout'),
            headers: MemberRepository.authHeaders,
            body: jsonEncode({
              'unitId': unitId,
              'startDate': startDate.toIso8601String(),
              'expectedEndDate': expectedEndDate.toIso8601String(),
              'shippingAddress': 'Giao tại đơn vị thuê',
              'phoneNumber':
                  MemberRepository.currentUser?.phoneNumber.isNotEmpty == true
                  ? MemberRepository.currentUser!.phoneNumber
                  : '0901234567',
              'notes': notes,
              'items': items,
            }),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 201) return null;
      return RentalModel.fromJson(jsonDecode(response.body));
    } catch (_) {
      return null;
    }
  }

  static Future<bool> updateStatus(int id, String status) async {
    try {
      var response = await http
          .put(
            Uri.parse('${ApiConstants.baseUrl}/rentals/$id/status'),
            headers: MemberRepository.authHeaders,
            body: jsonEncode({'status': status}),
          )
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> returnRental(int rentalId) =>
      updateStatus(rentalId, 'Returned');
  // Hợp đồng được hủy bằng trạng thái; không xóa lịch sử đã phát sinh.
  static Future<bool> deleteRental(int id) => updateStatus(id, 'Cancelled');
  static Future<List<Map<String, dynamic>>> getHandoverLogs(
    int rentalId,
  ) async {
    var response = await http
        .get(
          Uri.parse('${ApiConstants.baseUrl}/rentals/$rentalId/handover'),
          headers: MemberRepository.authHeaders,
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) throw Exception('Không tải được biên bản');
    return (jsonDecode(response.body) as List)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  static Future<bool> createHandoverLog({
    required int rentalId,
    required String logType,
    required String handledBy,
    required String signerName,
    required String signatureData,
    String? notes,
  }) async {
    try {
      var response = await http
          .post(
            Uri.parse('${ApiConstants.baseUrl}/rentals/$rentalId/handover'),
            headers: MemberRepository.authHeaders,
            body: jsonEncode({
              'logType': logType,
              'handledBy': handledBy,
              'signerName': signerName,
              'signatureData': signatureData,
              'notes': notes,
            }),
          )
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}

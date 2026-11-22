import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/constants/api_constants.dart';
import 'member_repository.dart';
import '../models/unit_model.dart';

class UnitRepository {
  static Future<List<UnitModel>> getUnits() async {
    var response = await http
        .get(
          Uri.parse('${ApiConstants.baseUrl}/units'),
          headers: MemberRepository.authHeaders,
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) throw Exception('Không tải được đơn vị');
    return (jsonDecode(response.body) as List)
        .map((p) => UnitModel.fromJson(p))
        .toList();
  }

  static Future<UnitModel?> createUnit({
    required String name,
    required String address,
    required String phoneNumber,
    required String contactPerson,
    String? email,
  }) async {
    try {
      var response = await http
          .post(
            Uri.parse('${ApiConstants.baseUrl}/units'),
            headers: MemberRepository.authHeaders,
            body: jsonEncode({
              'name': name,
              'address': address,
              'phoneNumber': phoneNumber,
              'contactPerson': contactPerson,
              'email': email,
            }),
          )
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200
          ? UnitModel.fromJson(jsonDecode(response.body))
          : null;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> deleteUnit(int id) async {
    try {
      var response = await http
          .delete(
            Uri.parse('${ApiConstants.baseUrl}/units/$id'),
            headers: MemberRepository.authHeaders,
          )
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}

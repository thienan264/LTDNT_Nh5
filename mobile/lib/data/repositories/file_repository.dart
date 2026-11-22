import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/constants/api_constants.dart';
import 'member_repository.dart';

class FileRepository {
  static String? relativeUrl(String? url) =>
      url?.replaceFirst(ApiConstants.baseHost, '');
  static Future<String> upload(
    String resource,
    int id,
    String base64Image,
  ) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConstants.baseUrl}/$resource/$id/upload-image'),
    );
    var token = MemberRepository.currentUser?.token;
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    final bytes = base64Decode(base64Image);
    final isPng =
        bytes.length >= 4 &&
        bytes[0] == 137 &&
        bytes[1] == 80 &&
        bytes[2] == 78 &&
        bytes[3] == 71;
    // Tên field File khớp FileUploadDto của API C#.
    request.files.add(
      http.MultipartFile.fromBytes(
        'File',
        bytes,
        filename: isPng ? 'image.png' : 'image.jpg',
      ),
    );
    var response = await http.Response.fromStream(await request.send())
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) throw Exception('Upload ảnh thất bại');
    return jsonDecode(response.body)['imageUrl'];
  }
}

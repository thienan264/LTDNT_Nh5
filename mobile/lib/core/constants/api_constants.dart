import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

class ApiConstants {
  // ASP.NET Core 10 Web API Backend Port: 5055
  static const int port = 5055;

  static String get serverHost {
    if (kIsWeb) {
      return '127.0.0.1:$port';
    }
    try {
      if (Platform.isAndroid) {
        // Android Emulator maps host localhost to 10.0.2.2
        return '10.0.2.2:$port';
      }
    } catch (_) {}
    return '127.0.0.1:$port';
  }

  static String get baseHost {
    return const String.fromEnvironment('API_HOST', defaultValue: '') != ''
        ? const String.fromEnvironment('API_HOST')
        : 'http://$serverHost';
  }

  static String get baseUrl {
    return '$baseHost/api';
  }
}

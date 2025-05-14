// lib/services/network_utils.dart

import 'dart:io';
import 'package:http/http.dart' as http;

class NetworkUtils {
  static Future<bool> _checkAppwriteConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isEmpty || result[0].rawAddress.isEmpty) {
        return false;
      }

      final response = await http
          .get(Uri.parse('https://cloud.appwrite.io/v1/avatars/initials'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } on SocketException catch (_) {
      return false;
    } on http.ClientException catch (_) {
      return false;
    }
  }

  static Future<T> withNetworkCheck<T>(Future<T> Function() apiCall) async {
    if (!await _checkAppwriteConnection()) {
      throw Exception('No internet connection available');
    }
    return await apiCall();
  }
}
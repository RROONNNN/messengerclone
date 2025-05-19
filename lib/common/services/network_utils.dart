import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

class NetworkUtils {
  static Future<bool> _checkAppwriteConnection() async {
    try {
      final response = await http
          .head(Uri.parse('http://www.google.com'))
          .timeout(const Duration(seconds: 3));
      debugPrint('Status Network : ${response.statusCode}');

      return response.statusCode >= 200 && response.statusCode < 300;
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
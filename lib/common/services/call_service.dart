import 'dart:convert';
import 'package:appwrite/appwrite.dart';
import 'package:flutter/cupertino.dart';
import 'app_write_config.dart';
import 'network_utils.dart';

class CallService {
  static final Client _client = Client()
      .setEndpoint(AppwriteConfig.endpoint)
      .setProject(AppwriteConfig.projectId);

  static Functions get functions => Functions(_client);

  static Future<void> sendMessage({
    required List<String> userIds,
    required String callId,
    required String callerName,
    required String callerId,
  }) async {
    return NetworkUtils.withNetworkCheck(() async {
      try {
        final payload = jsonEncode({
          'userIds': userIds,
          'callId': callId,
          'callerName': callerName,
          'callerId': callerId,
        });

        debugPrint('Chuẩn bị gửi payload đến Cloud Function: $payload');

        if (payload.isEmpty) {
          throw Exception('Payload rỗng trước khi gửi');
        }

        final execution = await functions.createExecution(
          functionId: AppwriteConfig.sendPushFunctionId,
          body: payload,
        );

        debugPrint('Phản hồi từ Cloud Function: ${execution.responseBody}');

        if (execution.responseBody.isEmpty) {
          throw Exception('Phản hồi từ Cloud Function rỗng');
        }

        final response = jsonDecode(execution.responseBody);
        if (response is! Map<String, dynamic>) {
          throw Exception('Phản hồi không phải JSON hợp lệ: ${execution.responseBody}');
        }

        if (!response['success']) {
          throw Exception(response['error'] ?? 'Gửi thông báo đẩy thất bại');
        }

        debugPrint('Thông báo đẩy được gửi: ${response['messageId']}');
      } on FormatException catch (e) {
        throw Exception('Lỗi phân tích JSON: $e');
      } on AppwriteException catch (e) {
        throw Exception('Lỗi Appwrite: ${e.message}');
      } catch (e) {
        throw Exception('Lỗi khi gửi thông báo đẩy: $e');
      }
    });
  }
}
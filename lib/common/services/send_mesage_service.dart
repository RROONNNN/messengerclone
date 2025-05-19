import 'dart:convert';
import 'package:appwrite/appwrite.dart';
import 'package:flutter/cupertino.dart';
import 'package:messenger_clone/features/chat/data/data_sources/remote/appwrite_repository.dart';
import 'package:messenger_clone/features/chat/model/user.dart' as appUser;
import 'app_write_config.dart';
import 'network_utils.dart';

class SendMessageService {
  static final Client _client = Client()
      .setEndpoint(AppwriteConfig.endpoint)
      .setProject(AppwriteConfig.projectId);

  static Functions get functions => Functions(_client);

  static Future<void> sendMessageNotification({
    required List<String> userIds,
    required String groupMessageId,
    required String messageContent,
    required String senderId,
    required String senderName,
  }) async {
    return NetworkUtils.withNetworkCheck(() async {
      try {
        final List<String> filteredUserIds = [];
        AppwriteRepository appwriteRepository = AppwriteRepository();
        for (String userId in userIds) {
          final user = await appwriteRepository.getUserById(userId);
          if (user != null && user.chattingWithGroupMessId != groupMessageId) {
            filteredUserIds.add(userId);
          }
        }
        final payload = jsonEncode({
          'type': 'message',
          'userIds': filteredUserIds,
          'groupMessageId': groupMessageId,
          'messageContent': messageContent,
          'senderId': senderId,
          'senderName': senderName,
        });

        debugPrint('Preparing to send message notification payload: $payload');

        if (payload.isEmpty) {
          throw Exception('Empty payload before sending');
        }

        final execution = await functions.createExecution(
          functionId: AppwriteConfig.sendPushFunctionId,
          body: payload,
        );

        debugPrint('Response from Cloud Function: ${execution.responseBody}');

        if (execution.responseBody.isEmpty) {
          throw Exception('Empty response from Cloud Function');
        }

        final response = jsonDecode(execution.responseBody);
        if (response is! Map<String, dynamic>) {
          throw Exception('Invalid JSON response: ${execution.responseBody}');
        }

        if (!response['success']) {
          throw Exception(
            response['error'] ?? 'Failed to send push notification',
          );
        }

        debugPrint('Push notification sent: ${response['messageId']}');
      } on FormatException catch (e) {
        throw Exception('JSON parsing error: $e');
      } on AppwriteException catch (e) {
        throw Exception('Appwrite error: ${e.message}');
      } catch (e) {
        throw Exception('Error sending push notification: $e');
      }
    });
  }
}

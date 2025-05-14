

import 'dart:convert';
import 'package:appwrite/appwrite.dart';

import 'app_write_config.dart';


class AIService {
  static final Client _client = Client()
      .setEndpoint(AppwriteConfig.endpoint)
      .setProject(AppwriteConfig.projectId);

  static Functions get functions => Functions(_client);

  static Future<Map<String, dynamic>> callMetaAIFunction(
      List<Map<String, String>> history, int maxTokens) async {
    try {
      final execution = await functions.createExecution(
        functionId: AppwriteConfig.functionMetaAIId,
        body: jsonEncode({
          'body': {'history': history, 'max_new_tokens': maxTokens},
        }),
      );
      final response = jsonDecode(execution.responseBody);
      final responseData = response['body'] ?? response;
      if (responseData is! Map<String, dynamic>) {
        throw Exception('Invalid response format');
      }
      return responseData;
    } catch (e) {
      throw Exception('Failed to call AI function: ${e.toString()}');
    }
  }
}
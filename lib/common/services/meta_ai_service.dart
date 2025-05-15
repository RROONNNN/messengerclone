

import 'dart:convert';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;

import 'app_write_config.dart';
import 'network_utils.dart';


class AIService {
  static final Client _client = Client()
      .setEndpoint(AppwriteConfig.endpoint)
      .setProject(AppwriteConfig.projectId);

  static Functions get functions => Functions(_client);
  static Databases get databases => Databases(_client);

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


  static Future<String> createConversation({
    required String userId,
    required String aiType,
  }) async {
    return NetworkUtils.withNetworkCheck(() async {
      try {
        final document = await databases.createDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.aiChatHistoryCollectionId,
          documentId: ID.unique(),
          data: {
            'userId': userId.toString(),
            'conversationId': ID.unique().toString(),
            'aiType': aiType.toString(),
            'createdAt': DateTime.now().toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),
          },
        );
        return document.$id;
      } catch (e) {
        throw Exception('Failed to create conversation: $e');
      }
    });
  }

  static Future<List<models.Document>> getConversations(String userId) async {
    return NetworkUtils.withNetworkCheck(() async {
      try {
        final response = await databases.listDocuments(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.aiChatHistoryCollectionId,
          queries: [
            Query.equal('userId', userId),
          ],
        );
        return response.documents;
      } catch (e) {
        throw Exception('Failed to fetch conversations: $e');
      }
    });
  }

  static Future<List<Map<String, String>>> getConversationHistory(String conversationId) async {
    return NetworkUtils.withNetworkCheck(() async {
      try {
        final response = await databases.listDocuments(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.aiMessagesCollectionId,
          queries: [
            Query.equal('conversationId', conversationId),
            Query.orderDesc('timestamp'),
          ],
        );
        return response.documents.map((doc) => {
          'role': (doc.data['role'] as String?) ?? '',
          'content': (doc.data['content'] as String?) ?? '',
          'timestamp': ((doc.data['timestamp'] as String?) ?? '').substring(11, 16),
        }).toList();
      } catch (e) {
        throw Exception('Failed to fetch conversation history: $e');
      }
    });
  }

  static Future<void> addMessage({
    required String conversationId,
    required String role,
    required String content,
  }) async {
    return NetworkUtils.withNetworkCheck(() async {
      try {
        final _ = await _getUserIdFromConversation(conversationId);
        await databases.createDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.aiMessagesCollectionId,
          documentId: ID.unique(),
          data: {
            'conversationId': conversationId.toString(),
            'role': role.toString(),
            'content': content.toString(),
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
        await databases.updateDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.aiChatHistoryCollectionId,
          documentId: conversationId,
          data: {
            'updatedAt': DateTime.now().toIso8601String(),
          },
        );
      } catch (e) {
        throw Exception('Failed to add message: $e');
      }
    });
  }

  static Future<String> _getUserIdFromConversation(String conversationId) async {
    final doc = await databases.getDocument(
      databaseId: AppwriteConfig.databaseId,
      collectionId: AppwriteConfig.aiChatHistoryCollectionId,
      documentId: conversationId,
    );
    return (doc.data['userId'] as String?) ?? '';
  }

  static Future<void> deleteConversation(String conversationId) async {
    return NetworkUtils.withNetworkCheck(() async {
      try {
        final messages = await databases.listDocuments(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.aiMessagesCollectionId,
          queries: [
            Query.equal('conversationId', conversationId),
          ],
        );
        for (var message in messages.documents) {
          await databases.deleteDocument(
            databaseId: AppwriteConfig.databaseId,
            collectionId: AppwriteConfig.aiMessagesCollectionId,
            documentId: message.$id,
          );
        }
        await databases.deleteDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.aiChatHistoryCollectionId,
          documentId: conversationId,
        );
      } catch (e) {
        throw Exception('Failed to delete conversation: $e');
      }
    });
  }
  static Future<void> deleteAllConversations(String userId) async {
    return NetworkUtils.withNetworkCheck(() async {
      try {
        final conversations = await getConversations(userId);
        for (var conversation in conversations) {
          await deleteConversation(conversation.$id);
        }
      } catch (e) {
        throw Exception('Failed to delete all conversations: $e');
      }
    });
  }
}
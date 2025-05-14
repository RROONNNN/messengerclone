

import 'package:appwrite/appwrite.dart';

import 'app_write_config.dart';
import 'network_utils.dart';

class CallService {
  static final Client _client = Client()
      .setEndpoint(AppwriteConfig.endpoint)
      .setProject(AppwriteConfig.projectId);

  static Databases get databases => Databases(_client);

  static Future<String> createCall({
    required String callID,
    required String initiatorId,
    required List<String> participants,
  }) async {
    return NetworkUtils.withNetworkCheck(() async {
      try {
        final document = await databases.createDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.callsCollectionId,
          documentId: ID.unique(),
          data: {
            'callID': callID,
            'initiatorId': initiatorId,
            'participants': participants,
            'status': 'pending',
            'createdAt': DateTime.now().toIso8601String(),
          },
        );
        return document.$id;
      } on AppwriteException catch (e) {
        throw Exception('Failed to create call: ${e.message}');
      }
    });
  }

  static Future<Map<String, dynamic>?> checkExistingCall({
    required String userId,
    required String callerId,
  }) async {
    return NetworkUtils.withNetworkCheck(() async {
      try {
        final response = await databases.listDocuments(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.callsCollectionId,
          queries: [
            Query.equal('participants', userId),
            Query.equal('initiatorId', callerId),
            Query.or([
              Query.equal('status', 'pending'),
              Query.equal('status', 'active'),
            ]),
            Query.limit(1),
          ],
        );

        if (response.documents.isNotEmpty) {
          final doc = response.documents.first;
          return {
            'callID': doc.data['callID'] as String?,
            'initiatorId': doc.data['initiatorId'] as String?,
            'status': doc.data['status'] as String?,
            'callDocumentId': doc.$id,
            'participants': List<String>.from(doc.data['participants'] ?? []),
          };
        }
        return null;
      } on AppwriteException catch (e) {
        throw Exception('Failed to check existing call: ${e.message}');
      }
    });
  }

  static Future<void> updateCallStatus({
    required String callDocumentId,
    required String status,
  }) async {
    return NetworkUtils.withNetworkCheck(() async {
      try {
        await databases.updateDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.callsCollectionId,
          documentId: callDocumentId,
          data: {'status': status},
        );
      } on AppwriteException catch (e) {
        throw Exception('Failed to update call status: ${e.message}');
      }
    });
  }
}
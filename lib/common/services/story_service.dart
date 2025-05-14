
import 'dart:io';
import 'package:appwrite/appwrite.dart';

import 'app_write_config.dart';
import 'friend_service.dart';
import 'network_utils.dart';

class StoryService {
  static final Client _client = Client()
      .setEndpoint(AppwriteConfig.endpoint)
      .setProject(AppwriteConfig.projectId);

  static Databases get databases => Databases(_client);
  static Storage get storage => Storage(_client);

  static Future<String> postStory({
    required String userId,
    required File mediaFile,
    required String mediaType,
  }) async {
    return NetworkUtils.withNetworkCheck(() async {
      try {
        final file = await storage.createFile(
          bucketId: AppwriteConfig.storageId,
          fileId: ID.unique(),
          file: InputFile.fromPath(
            path: mediaFile.path,
            filename: mediaFile.path.split('/').last,
          ),
        );

        final mediaUrl = 'https://fra.cloud.appwrite.io/v1/storage/buckets/${AppwriteConfig.storageId}/files/${file.$id}/view?project=${AppwriteConfig.projectId}';

        final now = DateTime.now();
        final twentyFourHoursAgo = now.subtract(const Duration(hours: 24)).toIso8601String();
        final response = await databases.listDocuments(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.storiesCollectionId,
          queries: [
            Query.equal('userId', userId),
            Query.greaterThan('createdAt', twentyFourHoursAgo),
          ],
        );
        final totalStories = response.documents.length + 1;

        await databases.createDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.storiesCollectionId,
          documentId: ID.unique(),
          data: {
            'userId': userId,
            'mediaUrl': mediaUrl,
            'mediaType': mediaType,
            'createdAt': now.toIso8601String(),
            'totalStories': totalStories,
          },
        );

        return mediaUrl;
      } on AppwriteException catch (e) {
        throw Exception('Failed to post story: ${e.message} (Code: ${e.code}, Type: ${e.type})');
      } catch (e) {
        throw Exception('Unexpected error while posting story: $e');
      }
    });
  }

  static Future<List<Map<String, dynamic>>> fetchFriendsStories(String userId) async {
    return NetworkUtils.withNetworkCheck(() async {
      try {
        final friendsList = await FriendService.getFriendsList(userId);
        final friendIds = friendsList.map((friend) => friend['userId'] as String).toList();

        final allIds = [...friendIds, userId];

        final now = DateTime.now();
        final twentyFourHoursAgo = now.subtract(const Duration(hours: 24)).toIso8601String();

        final response = await databases.listDocuments(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.storiesCollectionId,
          queries: [
            Query.equal('userId', allIds),
            Query.greaterThan('createdAt', twentyFourHoursAgo),
            Query.orderDesc('createdAt'),
          ],
        );

        return response.documents.map((doc) => {
          'userId': doc.data['userId'] as String,
          'mediaUrl': doc.data['mediaUrl'] as String,
          'mediaType': doc.data['mediaType'] as String,
          'createdAt': doc.data['createdAt'] as String,
          'totalStories': doc.data['totalStories'] as int,
        }).toList();
      } on AppwriteException catch (e) {
        throw Exception('Failed to fetch friends\' stories: ${e.message}');
      }
    });
  }

  static Future<void> deleteStory(String documentId, String fileId) async {
    return NetworkUtils.withNetworkCheck(() async {
      try {
        await storage.deleteFile(
          bucketId: AppwriteConfig.storageId,
          fileId: fileId,
        );
        await databases.deleteDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.storiesCollectionId,
          documentId: documentId,
        );
      } on AppwriteException catch (e) {
        throw Exception('Failed to delete story: ${e.message}');
      }
    });
  }
}
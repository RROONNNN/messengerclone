import 'package:appwrite/appwrite.dart';
import 'package:messenger_clone/common/services/user_service.dart';
import 'app_write_config.dart';
import 'network_utils.dart';

class FriendService {
  static final Client _client = Client()
      .setEndpoint(AppwriteConfig.endpoint)
      .setProject(AppwriteConfig.projectId);

  static Databases get databases => Databases(_client);

  static Future<Map<String, String>> getFriendshipStatus(
    String currentUserId,
    String otherUserId,
  ) async {
    return NetworkUtils.withNetworkCheck(() async {
      try {
        final sentResponse = await databases.listDocuments(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.friendsCollectionId,
          queries: [
            Query.equal('userId', currentUserId),
            Query.equal('friendId', otherUserId),
            Query.limit(1),
          ],
        );

        if (sentResponse.documents.isNotEmpty) {
          final doc = sentResponse.documents.first;
          return {
            'status': doc.data['status'] as String,
            'requestId': doc.$id,
            'direction': 'sent',
          };
        }

        final receivedResponse = await databases.listDocuments(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.friendsCollectionId,
          queries: [
            Query.equal('userId', otherUserId),
            Query.equal('friendId', currentUserId),
            Query.limit(1),
          ],
        );

        if (receivedResponse.documents.isNotEmpty) {
          final doc = receivedResponse.documents.first;
          return {
            'status': doc.data['status'] as String,
            'requestId': doc.$id,
            'direction': 'received',
          };
        }

        return {'status': 'none', 'requestId': '', 'direction': ''};
      } on AppwriteException catch (e) {
        throw Exception('Failed to check friendship status: ${e.message}');
      }
    });
  }

  static Future<List<Map<String, dynamic>>> getFriendsList(
    String userId,
  ) async {
    return NetworkUtils.withNetworkCheck(() async {
      try {
        final sentFriends = await databases.listDocuments(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.friendsCollectionId,
          queries: [
            Query.equal('userId', userId),
            Query.equal('status', 'accepted'),
          ],
        );
        final receivedFriends = await databases.listDocuments(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.friendsCollectionId,
          queries: [
            Query.equal('friendId', userId),
            Query.equal('status', 'accepted'),
          ],
        );

        final friendIds = <String, String>{};
        for (var doc in sentFriends.documents) {
          friendIds[doc.data['friendId'] as String] = doc.$id;
        }
        for (var doc in receivedFriends.documents) {
          friendIds[doc.data['userId'] as String] = doc.$id;
        }

        final friendsList = await Future.wait(
          friendIds.entries.map((entry) async {
            final friendId = entry.key;
            final requestId = entry.value;
            final friendData = await UserService.fetchUserDataById(friendId);
            return {
              'userId': friendId,
              'name': friendData['userName'] as String?,
              'photoUrl': friendData['photoUrl'] as String?,
              'aboutMe': friendData['aboutMe'] as String? ?? 'No description',
              'requestId': requestId,
            };
          }).toList(),
        );

        return friendsList;
      } on AppwriteException catch (e) {
        throw Exception('Failed to fetch friends list: ${e.message}');
      } catch (e) {
        throw Exception('Error fetching friends list: $e');
      }
    });
  }

  static Future<void> cancelFriendRequest(String requestId) async {
    return NetworkUtils.withNetworkCheck(() async {
      try {
        await databases.deleteDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.friendsCollectionId,
          documentId: requestId,
        );
      } on AppwriteException catch (e) {
        throw Exception('Failed to cancel friend request: ${e.message}');
      }
    });
  }

  static Future<List<Map<String, dynamic>>> searchUsersByName(
    String name,
  ) async {
    return NetworkUtils.withNetworkCheck(() async {
      try {
        final response = await databases.listDocuments(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.userCollectionId,
          queries: [Query.search('name', name), Query.limit(20)],
        );
        return response.documents
            .map(
              (doc) => {
                'userId': doc.$id,
                'name': doc.data['name'] as String?,
                'photoUrl': doc.data['photoUrl'] as String?,
                'aboutMe': doc.data['aboutMe'] as String?,
                'email': doc.data['email'] as String?,
                'isActive': doc.data['isActive'] as bool? ?? false,
              },
            )
            .toList();
      } on AppwriteException catch (e) {
        throw Exception('Failed to search users: ${e.message}');
      } catch (e) {
        throw Exception('Error searching users: $e');
      }
    });
  }

  static Future<void> sendFriendRequest(
    String currentUserId,
    String friendUserId,
  ) async {
    return NetworkUtils.withNetworkCheck(() async {
      try {
        await databases.getDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.userCollectionId,
          documentId: currentUserId,
        );
        await databases.getDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.userCollectionId,
          documentId: friendUserId,
        );

        final existingRequest = await databases.listDocuments(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.friendsCollectionId,
          queries: [
            Query.or([
              Query.and([
                Query.equal('userId', currentUserId),
                Query.equal('friendId', friendUserId),
              ]),
              Query.and([
                Query.equal('userId', friendUserId),
                Query.equal('friendId', currentUserId),
              ]),
            ]),
            Query.limit(1),
          ],
        );

        if (existingRequest.documents.isNotEmpty) {
          final status =
              existingRequest.documents.first.data['status'] as String;
          if (status == 'pending') {
            throw Exception(
              'A friend request is already pending with this user.',
            );
          } else if (status == 'accepted') {
            throw Exception('You are already friends with this user.');
          }
        }

        final documentId = ID.unique();
        await databases.createDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.friendsCollectionId,
          documentId: documentId,
          data: {
            'userId': currentUserId,
            'friendId': friendUserId,
            'status': 'pending',
          },
        );
      } on AppwriteException catch (e) {
        if (e.message?.contains(
              'Document with the requested ID already exists',
            ) ??
            false) {
          try {
            await databases.createDocument(
              databaseId: AppwriteConfig.databaseId,
              collectionId: AppwriteConfig.friendsCollectionId,
              documentId: ID.unique(),
              data: {
                'userId': currentUserId,
                'friendId': friendUserId,
                'status': 'pending',
              },
            );
          } catch (retryError) {
            throw Exception(
              'Failed to send friend request after retry: ${retryError.toString()}',
            );
          }
        } else if (e.message?.contains('unique constraint') ?? false) {
          throw Exception(
            'A friend request or friendship already exists with this user.',
          );
        } else {
          throw Exception('Failed to send friend request: ${e.message}');
        }
      } catch (e) {
        throw Exception('Error sending friend request: $e');
      }
    });
  }

  static Future<int> getPendingFriendRequestsCount(String userId) async {
    return NetworkUtils.withNetworkCheck(() async {
      try {
        final response = await databases.listDocuments(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.friendsCollectionId,
          queries: [
            Query.equal('friendId', userId),
            Query.equal('status', 'pending'),
          ],
        );
        return response.total;
      } on AppwriteException catch (e) {
        throw Exception('Failed to fetch friend requests count: ${e.message}');
      }
    });
  }

  static Future<List<Map<String, dynamic>>> getPendingFriendRequests(
    String userId,
  ) async {
    return NetworkUtils.withNetworkCheck(() async {
      try {
        final response = await databases.listDocuments(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.friendsCollectionId,
          queries: [
            Query.equal('friendId', userId),
            Query.equal('status', 'pending'),
          ],
        );
        return response.documents
            .map(
              (doc) => {
                'requestId': doc.$id,
                'userId': doc.data['userId'] as String,
                'friendId': doc.data['friendId'] as String,
                'status': doc.data['status'] as String,
              },
            )
            .toList();
      } on AppwriteException catch (e) {
        throw Exception('Failed to fetch friend requests: ${e.message}');
      }
    });
  }

  static Future<void> acceptFriendRequest(
    String requestId,
    String userId,
  ) async {
    return NetworkUtils.withNetworkCheck(() async {
      try {
        await databases.updateDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.friendsCollectionId,
          documentId: requestId,
          data: {'status': 'accepted'},
        );
      } on AppwriteException catch (e) {
        throw Exception('Failed to accept friend request: ${e.message}');
      }
    });
  }

  static Future<void> declineFriendRequest(String requestId) async {
    return NetworkUtils.withNetworkCheck(() async {
      try {
        await databases.deleteDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.friendsCollectionId,
          documentId: requestId,
        );
      } on AppwriteException catch (e) {
        throw Exception('Failed to decline friend request: ${e.message}');
      }
    });
  }
}

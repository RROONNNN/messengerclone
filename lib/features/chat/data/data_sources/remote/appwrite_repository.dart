import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:messenger_clone/common/services/app_write_config.dart';
import 'package:messenger_clone/common/services/auth_service.dart';
import 'package:messenger_clone/features/chat/model/group_message.dart';
import 'package:messenger_clone/features/chat/model/user.dart' as ChatModel;
import 'package:messenger_clone/features/messages/domain/models/message_model.dart';

class AppwriteRepository {
  Future<GroupMessage> updateGroupMessage(GroupMessage groupMessage) async {
    try {
      final groupMessageDoc = await AuthService.databases.updateDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.groupMessagesCollectionId,
        documentId: groupMessage.groupMessagesId,
        data: groupMessage.toJson(),
      );
      return GroupMessage.fromJson(groupMessageDoc.data);
    } catch (error) {
      throw Exception("Failed to update group message: $error");
    }
  }

  Future<void> updateChattingWithGroupMessId(
    String userId,
    String? groupMessId,
  ) async {
    try {
      await AuthService.databases.updateDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.userCollectionId,
        documentId: userId,
        data: {'chattingWithGroupMessId': groupMessId},
      );
    } catch (error) {
      throw Exception("Failed to update chattingWithGroupMessId: $error");
    }
  }

  Future<List<GroupMessage>> getGroupMessByIds(
    List<String> groupMessageIds,
  ) async {
    final List<GroupMessage> groupMessages = [];
    try {
      for (String groupMessageId in groupMessageIds) {
        final Document doc = await AuthService.databases.getDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.groupMessagesCollectionId,
          documentId: groupMessageId,
        );
        final group = GroupMessage.fromJson(doc.data);
        groupMessages.add(group);
      }
    } catch (error) {
      throw Exception("Failed to fetch group chats: $error");
    }
    return groupMessages;
  }

  Future<List<ChatModel.User>> getAllUsers() async {
    try {
      final DocumentList documentList = await AuthService.databases
          .listDocuments(
            databaseId: AppwriteConfig.databaseId,
            collectionId: AppwriteConfig.userCollectionId,
          );
      return documentList.documents.map((doc) {
        final groupMessages = doc.data['groupMessages'];
        final groupChatIds =
            groupMessages is List
                ? groupMessages
                    .map((message) => message['groupChatId'])
                    .toList()
                : [];

        return ChatModel.User.fromMap({
          ...doc.data,
          'id': doc.$id,
          'groupMessages': groupChatIds,
        });
      }).toList();
    } catch (error) {
      throw Exception("Failed to fetch users: $error");
    }
  }

  Future<ChatModel.User?> getUserById(String userId) async {
    try {
      final doc = await AuthService.databases.getDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.userCollectionId,
        documentId: userId,
      );
      final groupMessages = doc.data['groupMessages'];
      final groupChatIds =
          groupMessages is List
              ? groupMessages.map((message) => message['groupChatId']).toList()
              : [];
      return ChatModel.User.fromMap({
        ...doc.data,
        'id': doc.$id,
        'groupMessages': groupChatIds,
      });
    } catch (error) {
      throw Exception("Failed to fetch user: $error");
    }
  }

  Future<List<GroupMessage>> getGroupMessagesByUserId(String userId) async {
    try {
      final Document userdoc = await AuthService.databases.getDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.userCollectionId,
        documentId: userId,
      );
      final List<dynamic> groupMessages = userdoc.data['groupMessages'] ?? [];
      final List<String> groupMessIds =
          groupMessages
              .where(
                (message) =>
                    message is Map<String, dynamic> &&
                    message.containsKey('\$id'),
              )
              .map(
                (message) =>
                    (message as Map<String, dynamic>)['\$id'] as String,
              )
              .toList();
      if (groupMessIds.isEmpty) {
        return [];
      }
      return getGroupMessByIds(groupMessIds);
    } catch (error) {
      throw Exception("Failed to fetch group messages: $error");
    }
  }

  Future<Stream<RealtimeMessage>> getStreamToUpdateChatPage(
    String userId,
  ) async {
    try {
      final Document userDoc = await AuthService.databases.getDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.userCollectionId,
        documentId: userId,
      );
      final List<dynamic> groupMessages = userDoc.data['groupMessages'] ?? [];
      final List<String> groupMessIds =
          groupMessages
              .where(
                (message) =>
                    message is Map<String, dynamic> &&
                    message.containsKey('\$id'),
              )
              .map(
                (message) =>
                    (message as Map<String, dynamic>)['\$id'] as String,
              )
              .toList();
      List<String> channels = [];
      channels.add(
        'databases.${AppwriteConfig.databaseId}.collections.${AppwriteConfig.userCollectionId}.documents.$userId',
      );
      for (String groupMessageId in groupMessIds) {
        channels.add(
          'databases.${AppwriteConfig.databaseId}.collections.${AppwriteConfig.groupMessagesCollectionId}.documents.$groupMessageId',
        );
      }
      final subscription = AuthService.realtime.subscribe(channels);
      return subscription.stream;
    } catch (error) {
      throw Exception("Failed to getStreamToUpdateChatPage: $error");
    }
  }

  Future<Stream<RealtimeMessage>> getUserStream(String userId) async {
    try {
      final subscription = AuthService.realtime.subscribe([
        'databases.${AppwriteConfig.databaseId}.collections.${AppwriteConfig.userCollectionId}.documents.$userId',
      ]);
      return subscription.stream;
    } catch (error) {
      throw Exception("Failed to fetch user stream: $error");
    }
  }

  Future<Stream<RealtimeMessage>> getGroupMessageStream(
    String groupMessId,
  ) async {
    try {
      final subscription = AuthService.realtime.subscribe([
        'databases.${AppwriteConfig.databaseId}.collections.${AppwriteConfig.groupMessagesCollectionId}.documents.$groupMessId',
      ]);
      return subscription.stream;
    } catch (error) {
      throw Exception("Failed to fetch group message stream: $error");
    }
  }

  Future<GroupMessage> getGroupMessageById(String groupMessId) async {
    try {
      final groupMessage = await getGroupMessByIds([groupMessId]);
      return groupMessage.first;
    } catch (error) {
      throw Exception("Failed to fetch group message: $error");
    }
  }

  Future<List<ChatModel.User>> getFriendsList(String userId) async {
    try {
      final sentFriends = await AuthService.databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.friendsCollectionId,
        queries: [
          Query.equal('userId', userId),
          Query.equal('status', 'accepted'),
        ],
      );
      final receivedFriends = await AuthService.databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.friendsCollectionId,
        queries: [
          Query.equal('friendId', userId),
          Query.equal('status', 'accepted'),
        ],
      );

      final Set<String> friendIds = {};
      for (var doc in sentFriends.documents) {
        friendIds.add(doc.data['friendId'] as String);
      }
      for (var doc in receivedFriends.documents) {
        friendIds.add(doc.data['userId'] as String);
      }

      final friendsFutures =
          friendIds.map((friendId) => getUserById(friendId)).toList();
      final friendsResults = await Future.wait(friendsFutures);
      final friendsList =
          friendsResults
              .where((user) => user != null)
              .cast<ChatModel.User>()
              .toList();

      return friendsList;
    } on AppwriteException catch (e) {
      throw Exception('Failed to fetch friends list: ${e.message}');
    } catch (e) {
      throw Exception('Error fetching friends list: $e');
    }
  }

  Future<GroupMessage> updateMemberOfGroup(
    String groupMessId,
    Set<String> memberIds,
  ) async {
    try {
      final doc = await AuthService.databases.updateDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.groupMessagesCollectionId,
        documentId: groupMessId,
        data: {'users': memberIds.toList()},
      );
      return GroupMessage.fromJson(doc.data);
    } catch (error) {
      throw Exception("Failed to update member of group: $error");
    }
  }
}

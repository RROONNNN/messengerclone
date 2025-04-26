import 'package:appwrite/models.dart';
import 'package:messenger_clone/common/services/app_write_service.dart';
import 'package:messenger_clone/features/chat/model/group_message.dart';
import 'package:messenger_clone/features/chat/model/user.dart' as ChatModel;
import 'package:messenger_clone/features/messages/domain/models/message_model.dart';

class AppwriteRepository {
  Future<List<GroupMessage>> getGroupMessByIds(
    List<String> groupMessageIds,
  ) async {
    final List<GroupMessage> groupMessages = [];
    try {
      for (String groupMessageId in groupMessageIds) {
        final Document doc = await AppWriteService.databases.getDocument(
          databaseId: AppWriteService.databaseId,
          collectionId: AppWriteService.groupMessagesCollectionId,
          documentId: groupMessageId,
        );
        final List<ChatModel.User> users =
            (doc.data['users'] as List<dynamic>).map((user) {
              if (user is Map<String, dynamic>) {
                return ChatModel.User.fromMap({...user, 'id': user["\$id"]});
              }
              throw Exception("Invalid user format in group chat");
            }).toList();

        final group = GroupMessage(
          groupId: doc.data['groupId'],
          groupMessagesId: doc.$id,
          latestMessage: MessageModel.fromMap(doc.data['lastMessage']),
          users: users,
        );
        groupMessages.add(group);
      }
    } catch (error) {
      throw Exception("Failed to fetch group chats: $error");
    }
    return groupMessages;
  }

  Future<List<ChatModel.User>> getAllUsers() async {
    try {
      final DocumentList documentList = await AppWriteService.databases
          .listDocuments(
            databaseId: AppWriteService.databaseId,
            collectionId: AppWriteService.userCollectionid,
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
      final doc = await AppWriteService.databases.getDocument(
        databaseId: AppWriteService.databaseId,
        collectionId: AppWriteService.userCollectionid,
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
      final Document userdoc = await AppWriteService.databases.getDocument(
        databaseId: AppWriteService.databaseId,
        collectionId: AppWriteService.userCollectionid,
        documentId: userId,
      );
      //get all group messages id by userdoc.data['groupMessages'];
      final List<dynamic> groupMessages = userdoc.data['groupMessages'] ?? [];
      final List<String> groupMessIds =
          groupMessages
              .map((message) => message['\$id'])
              .toList()
              .cast<String>();
      return getGroupMessByIds(groupMessIds);
    } catch (error) {
      throw Exception("Failed to fetch group messages: $error");
    }
  }
}

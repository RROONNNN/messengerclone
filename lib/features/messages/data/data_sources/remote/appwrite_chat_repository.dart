import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:flutter/foundation.dart';
import 'package:messenger_clone/common/constants/appwrite_database_constants.dart';
import 'package:messenger_clone/common/services/app_write_service.dart';
import 'package:messenger_clone/features/chat/model/group_message.dart';
import 'package:messenger_clone/features/messages/domain/models/message_model.dart';

class AppwriteChatRepository {
  Future<Stream<RealtimeMessage>> getChatStream(String groupMessId) async {
    try {
      debugPrint('Fetching chat stream for groupChatId: $groupMessId');
      final String groupMessagesCollectionId =
          AppWriteService.groupMessagesCollectionId;
      final Document groupMessageDoc = await AppWriteService.databases
          .getDocument(
            databaseId: AppWriteService.databaseId,
            collectionId: AppWriteService.groupMessagesCollectionId,
            documentId: groupMessId,
          );
      String documentId = groupMessageDoc.$id;

      final subscription = AppWriteService.realtime.subscribe([
        'databases.${AppWriteService.databaseId}.collections.$groupMessagesCollectionId.documents.$documentId',
      ]);
      return subscription.stream;
    } catch (error) {
      throw Exception("Failed to fetch chat stream: $error");
    }
  }

  Future<List<MessageModel>> getMessages(
    String groupMessId,
    int limit,
    int offset,
  ) async {
    try {
      final DocumentList response = await AppWriteService.databases
          .listDocuments(
            databaseId: AppWriteService.databaseId,
            collectionId: AppWriteService.messageCollectionId,
            queries: [
              Query.equal(
                AppwriteDatabaseConstants.groupMessagesId,
                groupMessId,
              ),
              Query.orderDesc('\$createdAt'),
              Query.limit(limit),
              Query.offset(offset),
            ],
          );
      debugPrint(
        'Fetched ${response.documents.length} messages for groupMessId: $groupMessId',
      );
      if (response.documents.isEmpty) {
        return [];
      }
      return response.documents
          .map((document) => MessageModel.fromMap(document.data))
          .toList();
    } catch (error) {
      throw Exception("Failed to fetch messages: $error");
    }
  }

  Future<void> sendMessage(MessageModel message, List<String> receivers) async {
    try {
      debugPrint('Sending message: ${message.toJson()}');

      final Document messageDocument = await AppWriteService.databases
          .createDocument(
            databaseId: AppWriteService.databaseId,
            collectionId: AppWriteService.messageCollectionId,
            documentId: ID.unique(),
            data: message.toJson(),
          );

      final String messageId = messageDocument.$id;
      final Document groupMessDocument = await AppWriteService.databases
          .getDocument(
            databaseId: AppWriteService.databaseId,
            collectionId: AppWriteService.groupMessagesCollectionId,
            documentId: message.groupMessagesId,
          );
      if (groupMessDocument.data.isNotEmpty) {
        await AppWriteService.databases.updateDocument(
          databaseId: AppWriteService.databaseId,
          collectionId: AppWriteService.groupMessagesCollectionId,
          documentId: groupMessDocument.data['\$id'],
          data: {AppwriteDatabaseConstants.lastMessage: messageId},
        );
      } else {
        await AppWriteService.databases.createDocument(
          databaseId: AppWriteService.databaseId,
          collectionId: AppWriteService.groupMessagesCollectionId,
          documentId: ID.unique(),
          data: {AppwriteDatabaseConstants.lastMessage: messageId},
        );

        await _addGroupChatIdToUser(message.idFrom, message.groupMessagesId);
        for (String receiver in receivers) {
          await _addGroupChatIdToUser(receiver, message.groupMessagesId);
        }
      }
    } catch (error) {
      throw Exception("Failed to send message: $error");
    }
  }

  Future<void> _addGroupChatIdToUser(String userId, String groupMessId) async {
    try {
      debugPrint('Adding groupMessId $groupMessId to user $userId');

      final Document userDoc = await AppWriteService.databases.getDocument(
        databaseId: AppWriteService.databaseId,
        collectionId: AppWriteService.userCollectionid,
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
      if (!groupMessIds.contains(groupMessId)) {
        await AppWriteService.databases.updateDocument(
          databaseId: AppWriteService.databaseId,
          collectionId: AppWriteService.userCollectionid,
          documentId: userId,
          data: {
            'groupMessages': [...groupMessIds, groupMessId],
          },
        );
      }
    } catch (error) {
      debugPrint("Failed to add groupMessId to user  $userId document: $error");
      throw Exception("Failed to add groupMessId to user document: $error");
    }
  }

  Future<GroupMessage> createGroupMessages({
    String? groupName,
    required List<String> userIds,
    String? avatarGroupUrl,
    bool isGroup = false,
    required String groupId,
  }) async {
    try {
      final Document groupMessageDocument = await AppWriteService.databases
          .createDocument(
            databaseId: AppWriteService.databaseId,
            collectionId: AppWriteService.groupMessagesCollectionId,
            documentId: ID.unique(),
            data: {
              'groupName': groupName,
              // 'users': userIds,
              'avatarGroupUrl': avatarGroupUrl,
              'isGroup': isGroup,
              'groupId': groupId,
            },
          );

      for (String userId in userIds) {
        _addGroupChatIdToUser(userId, groupMessageDocument.$id);
      }
      final Document groupMessageDoc = await AppWriteService.databases
          .getDocument(
            databaseId: AppWriteService.databaseId,
            collectionId: AppWriteService.groupMessagesCollectionId,
            documentId: groupMessageDocument.$id,
          );
      final GroupMessage returnVal = GroupMessage.fromJson({
        ...groupMessageDoc.data,
        'groupMessagesId': groupMessageDocument.$id,
      });
      return returnVal;
    } catch (error) {
      debugPrint("Failed to create group message: $error");
      throw Exception("Failed to create group message: $error");
    }
  }

  Future<GroupMessage?> getGroupMessagesByGroupId(String groupId) async {
    try {
      final DocumentList documentList = await AppWriteService.databases
          .listDocuments(
            databaseId: AppWriteService.databaseId,
            collectionId: AppWriteService.groupMessagesCollectionId,
            queries: [Query.equal('groupId', groupId)],
          );
      if (documentList.documents.isNotEmpty) {
        return GroupMessage.fromJson({
          ...documentList.documents.first.data,
          'groupMessagesId': documentList.documents.first.$id,
        });
      } else {
        return null;
      }
    } catch (error) {
      debugPrint("Failed to check group message existence: $error");
      return null;
    }
  }
}

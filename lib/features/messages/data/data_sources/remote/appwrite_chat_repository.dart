import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:flutter/foundation.dart';
import 'package:messenger_clone/common/constants/appwrite_database_constants.dart';
import 'package:messenger_clone/common/services/app_write_service.dart';
import 'package:messenger_clone/common/services/common_function.dart';
import 'package:messenger_clone/features/messages/domain/models/message_model.dart';

class AppwriteChatRepository {
  // Future<List<MessageModel>> _fetchedMessages(List<String> messageIds) async {
  //   final List<MessageModel> messages = [];
  //   for (String messageId in messageIds) {
  //     try {
  //       final Document messageDocument = await AppWriteService.databases.getDocument(
  //         databaseId: AppwriteDatabaseConstants.databaseId,
  //         collectionId: AppwriteDatabaseConstants.messageCollectionId,
  //         documentId: messageId,
  //       );
  //       messages.add(MessageModel.fromMap(messageDocument.data));
  //     } catch (error) {
  //       debugPrint('Error fetching message with ID $messageId: $error');
  //     }
  //   }
  //   return messages;
  // }
  //getChatStream

  Future<Document> getOrCreateDocumentByGroupChatId(String groupChatId) async {
    try {
      final DocumentList documentList = await AppWriteService.databases
          .listDocuments(
            databaseId: AppWriteService.databaseId,
            collectionId: AppWriteService.groupMessagesCollectionId,
            queries: [
              Query.equal(AppwriteDatabaseConstants.groupChatId, groupChatId),
            ],
          );
      if (documentList.documents.isNotEmpty) {
        return documentList.documents.first;
      } else {
        final Document newDocument = await AppWriteService.databases
            .createDocument(
              databaseId: AppWriteService.databaseId,
              collectionId: AppWriteService.groupMessagesCollectionId,
              documentId: ID.unique(),
              data: {AppwriteDatabaseConstants.groupChatId: groupChatId},
            );
        return newDocument;
      }
    } catch (error) {
      throw Exception("Failed to fetch document ID: $error");
    }
  }

  Future<Stream<RealtimeMessage>> getChatStream(String groupChatId) async {
    debugPrint('Fetching chat stream for groupChatId: $groupChatId');
    final String groupMessagesCollectionId =
        AppWriteService.groupMessagesCollectionId;
    String documentId = await getOrCreateDocumentByGroupChatId(
      groupChatId,
    ).then((document) => document.$id).catchError((error) {
      debugPrint('Error fetching document ID: $error');
      throw Exception("Failed to fetch document ID: $error");
    });
    final subscription = AppWriteService.realtime.subscribe([
      'databases.${AppWriteService.databaseId}.collections.$groupMessagesCollectionId.documents.$documentId',
    ]);
    return subscription.stream;
  }

  Future<List<MessageModel>> getMessages(
    String groupChatId,
    int limit,
    int offset,
  ) async {
    try {
      final response = await AppWriteService.databases.listDocuments(
        databaseId: AppWriteService.databaseId,
        collectionId: AppWriteService.messageCollectionId,
        queries: [
          Query.equal(AppwriteDatabaseConstants.groupChatId, groupChatId),
          Query.orderDesc(AppwriteDatabaseConstants.timestamp),
          Query.limit(limit),
          Query.offset(offset),
        ],
      );
      return response.documents
          .map((document) => MessageModel.fromMap(document.data))
          .toList();
    } catch (error) {
      throw Exception("Failed to fetch messages: $error");
    }
  }

  Future<void> sendMessage(MessageModel message) async {
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
      final DocumentList groupChatDocument = await AppWriteService.databases
          .listDocuments(
            databaseId: AppWriteService.databaseId,
            collectionId: AppWriteService.groupMessagesCollectionId,
            queries: [
              Query.equal(
                AppwriteDatabaseConstants.groupChatId,
                CommonFunction.getGroupChatId(message.idFrom, message.idTo),
              ),
            ],
          );
      groupChatDocument.documents.isNotEmpty
          ? await AppWriteService.databases.updateDocument(
            databaseId: AppWriteService.databaseId,
            collectionId: AppWriteService.groupMessagesCollectionId,
            documentId: groupChatDocument.documents.first.$id,
            data: {
              AppwriteDatabaseConstants.groupChatId:
                  CommonFunction.getGroupChatId(message.idFrom, message.idTo),
              AppwriteDatabaseConstants.lastMessage: messageId,
            },
          )
          : await AppWriteService.databases.createDocument(
            databaseId: AppWriteService.databaseId,
            collectionId: AppWriteService.groupMessagesCollectionId,
            documentId: ID.unique(),
            data: {
              AppwriteDatabaseConstants.groupChatId:
                  CommonFunction.getGroupChatId(message.idFrom, message.idTo),
              AppwriteDatabaseConstants.lastMessage: messageId,
            },
          );
    } catch (error) {
      throw Exception("Failed to send message: $error");
    }
  }
}

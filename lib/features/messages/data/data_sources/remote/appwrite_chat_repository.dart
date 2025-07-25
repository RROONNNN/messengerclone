import 'dart:io';

import 'package:appwrite/appwrite.dart';
import 'dart:io' as dart;
import 'package:appwrite/models.dart';
import 'package:flutter/foundation.dart';
import 'package:messenger_clone/common/constants/appwrite_database_constants.dart';
import 'package:messenger_clone/common/services/auth_service.dart';
import 'package:messenger_clone/common/services/story_service.dart';
import 'package:messenger_clone/features/chat/model/group_message.dart';
import 'package:messenger_clone/features/messages/domain/models/message_model.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../../common/services/app_write_config.dart';

class AppwriteChatRepository {
  String getFileidFromUrl(String url) {
    try {
      final Uri uri = Uri.parse(url);

      if (!uri.host.contains('appwrite.io') ||
          !uri.path.contains('/storage/buckets/')) {
        debugPrint('Not a valid Appwrite storage URL: $url');
        throw Exception('Not a valid Appwrite storage URL');
      }

      final List<String> segments = uri.pathSegments;
      final int filesIndex = segments.indexOf('files');

      if (filesIndex == -1 || filesIndex + 1 >= segments.length) {
        debugPrint('URL format not recognized: $url');
        throw Exception('URL format not recognized');
      }

      final String fileId = segments[filesIndex + 1];
      debugPrint('Extracted fileId: $fileId from URL');
      return fileId;
    } catch (e) {
      debugPrint('Error extracting file info from URL: $e');
      throw Exception('Failed to extract fileId from URL');
    }
  }

  Future<String> downloadFile(String url, String filePath) async {
    try {
      final String fileId = getFileidFromUrl(url);
      final Future<Uint8List> downloadFuture = AuthService.storage
          .getFileDownload(bucketId: AppwriteConfig.bucketId, fileId: fileId);
      final Directory cacheDir = await getTemporaryDirectory();
      final String dirPath = '${cacheDir.path}/$filePath';
      final String fullPath = '$dirPath/$fileId';
      final file = dart.File(fullPath);

      final Future<void> dirCreationFuture = dart.Directory(
        dirPath,
      ).create(recursive: true);

      final results = await Future.wait([dirCreationFuture, downloadFuture]);
      final bytes = results[1] as Uint8List;

      await file.writeAsBytes(bytes);

      debugPrint("File downloaded and saved to $fullPath");
      return fullPath;
    } catch (error) {
      debugPrint("Failed to download file: $error");
      throw Exception("Failed to download file: $error");
    }
  }

  Future<MessageModel> getMessageById(String messageId) async {
    try {
      final Document messageDocument = await AuthService.databases.getDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.messageCollectionId,
        documentId: messageId,
      );
      return MessageModel.fromMap(messageDocument.data);
    } catch (error) {
      debugPrint("Failed to fetch message by ID: $error");
      throw Exception("Failed to fetch message by ID: $error");
    }
  }

  Future<MessageModel> updateMessage(MessageModel message) async {
    try {
      final Document messageDocument = await AuthService.databases
          .updateDocument(
            databaseId: AppwriteConfig.databaseId,
            collectionId: AppwriteConfig.messageCollectionId,
            documentId: message.id,
            data: message.toJson(),
          );
      return MessageModel.fromMap(messageDocument.data);
    } catch (error) {
      debugPrint("Failed to update message: $error");
      throw Exception("Failed to update message: $error");
    }
  }

  Future<Stream<RealtimeMessage>> getMessagesStream(
    List<String> messageIds,
  ) async {
    try {
      debugPrint('Fetching messages stream for messageIds: $messageIds');
      final String messageCollectionId = AppwriteConfig.messageCollectionId;

      List<String> subscriptions =
          messageIds
              .map(
                (messageId) =>
                    'databases.${AppwriteConfig.databaseId}.collections.$messageCollectionId.documents.$messageId',
              )
              .toList();

      final subscription = AuthService.realtime.subscribe(subscriptions);
      return subscription.stream;
    } catch (error) {
      throw Exception("Failed to fetch messages stream: $error");
    }
  }

  Future<Stream<RealtimeMessage>> getChatStream(String groupMessId) async {
    try {
      debugPrint('Fetching chat stream for groupChatId: $groupMessId');
      final String groupMessagesCollectionId =
          AppwriteConfig.groupMessagesCollectionId;
      final Document groupMessageDoc = await AuthService.databases.getDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.groupMessagesCollectionId,
        documentId: groupMessId,
      );
      String documentId = groupMessageDoc.$id;

      final subscription = AuthService.realtime.subscribe([
        'databases.${AppwriteConfig.databaseId}.collections.$groupMessagesCollectionId.documents.$documentId',
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
    DateTime? newerThan,
  ) async {
    try {
      final DocumentList response = await AuthService.databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.messageCollectionId,
        queries:
            (newerThan != null)
                ? [
                  Query.equal(
                    AppwriteDatabaseConstants.groupMessagesId,
                    groupMessId,
                  ),
                  Query.orderDesc('\$createdAt'),
                  Query.greaterThan('\$createdAt', newerThan.toIso8601String()),
                ]
                : [
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
          .map((doc) => MessageModel.fromMap(doc.data))
          .toList();
    } catch (error) {
      throw Exception("Failed to fetch messages: $error");
    }
  }

  Future<MessageModel> sendMessage(
    MessageModel message,
    GroupMessage groupMessage,
  ) async {
    try {
      debugPrint('Sending message: ${message.toJson()}');
      final Document messageDocument = await AuthService.databases
          .createDocument(
            databaseId: AppwriteConfig.databaseId,
            collectionId: AppwriteConfig.messageCollectionId,
            documentId: message.id,
            data: message.toJson(),
          );

      final String messageId = messageDocument.$id;

      await AuthService.databases.updateDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.groupMessagesCollectionId,
        documentId: groupMessage.groupMessagesId,
        data: {AppwriteDatabaseConstants.lastMessage: messageId},
      );
      return MessageModel.fromMap(messageDocument.data);
    } catch (error) {
      throw Exception("Failed to send message: $error");
    }
  }

  Future<GroupMessage> createGroupMessages({
    String? groupName,
    required List<String> userIds,
    String? avatarGroupUrl,
    bool isGroup = false,
    required String groupId,
    String? createrId,
  }) async {
    try {
      final Document groupMessageDocument = await AuthService.databases
          .createDocument(
            databaseId: AppwriteConfig.databaseId,
            collectionId: AppwriteConfig.groupMessagesCollectionId,
            documentId: ID.unique(),
            data: {
              'groupName': groupName,
              'avatarGroupUrl': avatarGroupUrl,
              'isGroup': isGroup,
              'groupId': groupId,
              'createrId': createrId,
              'users': userIds,
            },
          );
      List<Future<void>> userUpdates = [];
      await Future.wait(userUpdates);
      final Document groupMessageDoc = await AuthService.databases.getDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.groupMessagesCollectionId,
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
      final DocumentList documentList = await AuthService.databases
          .listDocuments(
            databaseId: AppwriteConfig.databaseId,
            collectionId: AppwriteConfig.groupMessagesCollectionId,
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
      debugPrint("Failed to get group message existence: $error");
      throw Exception("Failed to get group message existence: $error");
    }
  }

  Future<File> uploadFile(String filePath, String senderId) async {
    try {
      debugPrint("Attempting to upload file from path: $filePath");

      final fileObject = dart.File(filePath);
      if (!await fileObject.exists()) {
        throw Exception('File does not exist at path: $filePath');
      }

      final fileSize = await fileObject.length();
      debugPrint("File size: $fileSize bytes");

      if (fileSize == 0) {
        throw Exception('File is empty: $filePath');
      }

      final String fileName = filePath.split('/').last;
      InputFile inputFile;

      if (fileName.toLowerCase().endsWith('.mp4') ||
          fileName.toLowerCase().endsWith('.mov') ||
          fileName.toLowerCase().endsWith('.avi')) {
        final bytes = await fileObject.readAsBytes();
        inputFile = InputFile.fromBytes(bytes: bytes, filename: fileName);
        debugPrint(
          "Using bytes method for video: $fileName with ${bytes.length} bytes",
        );
      } else {
        inputFile = InputFile.fromPath(path: filePath);
        debugPrint("Using path method for file: $fileName");
      }

      List<String> permissions = [
        Permission.write(Role.user(senderId)),
        Permission.read(Role.user(senderId)),
        Permission.read(Role.any()),
      ];

      return await StoryService.storage.createFile(
        bucketId: AppwriteConfig.bucketId,
        fileId: ID.unique(),
        file: inputFile,
        permissions: permissions,
      );
    } catch (error) {
      if (error is AppwriteException) {
        debugPrint("Appwrite error code: ${error.code}");
        debugPrint("Appwrite error message: ${error.message}");
        debugPrint("Appwrite response details: ${error.response}");
      }
      debugPrint("Failed to upload file: $error");
      throw Exception("Failed to upload file: $error");
    }
  }
}

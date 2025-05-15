import 'package:appwrite/models.dart';
import 'package:appwrite/src/realtime_message.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:messenger_clone/features/chat/model/group_message.dart';
import 'package:messenger_clone/features/messages/data/data_sources/remote/appwrite_chat_repository.dart';
import 'package:messenger_clone/features/messages/domain/models/message_model.dart';
import 'package:messenger_clone/features/messages/domain/repositories/abstract_chat_repository.dart';

class ChatRepositoryImpl implements AbstractChatRepository {
  late final AppwriteChatRepository appwriteChatRepository;
  ChatRepositoryImpl() {
    appwriteChatRepository = AppwriteChatRepository();
  }
  @override
  Future<Either<String, Stream<RealtimeMessage>>> getChatStream(
    String groupMessId,
  ) async {
    try {
      final response = await appwriteChatRepository.getChatStream(groupMessId);
      return Right(response);
    } catch (error) {
      return Left("Failed to fetch chat stream: $error");
    }
  }

  @override
  Future<List<MessageModel>> getMessages(
    String groupMessId,
    int limit,
    int offset,
  ) async {
    try {
      final response = await appwriteChatRepository.getMessages(
        groupMessId,
        limit,
        offset,
      );
      return response;
    } catch (error) {
      debugPrint("Failed to fetch messages: $error");
      return [];
    }
  }

  @override
  Future<Either<String, void>> sendMessage(
    MessageModel message,
    GroupMessage groupMessage,
  ) async {
    try {
      final response = await appwriteChatRepository.sendMessage(
        message,
        groupMessage,
      );
      return Right(response);
    } catch (error) {
      return Left("Failed to send message: $error");
    }
  }

  @override
  Future<Either<String, GroupMessage>> createGroupMessages({
    String? groupName,
    required List<String> userIds,
    String? avatarGroupUrl,
    bool isGroup = false,
    required String groupId,
  }) async {
    try {
      final GroupMessage response = await appwriteChatRepository
          .createGroupMessages(
            groupName: groupName,
            userIds: userIds,
            avatarGroupUrl: avatarGroupUrl,
            isGroup: isGroup,
            groupId: groupId,
          );

      return Right(response);
    } catch (error) {
      return Left("Failed to create group messages: $error");
    }
  }

  @override
  Future<GroupMessage?> getGroupMessagesByGroupId(String groupId) async {
    return await appwriteChatRepository.getGroupMessagesByGroupId(groupId);
  }

  Future<void> updateMessage(MessageModel message) async {
    await appwriteChatRepository.updateMessage(message);
  }

  Future<Either<String, Stream<RealtimeMessage>>> getMessagesStream(
    List<String> messageIds,
  ) async {
    try {
      final response = await appwriteChatRepository.getMessagesStream(
        messageIds,
      );
      return Right(response);
    } catch (error) {
      return Left("Failed to fetch message stream: $error");
    }
  }

  @override
  Future<File> uploadFile(String filePath, String senderId) async {
    try {
      return appwriteChatRepository.uploadFile(filePath, senderId);
    } catch (error) {
      debugPrint("Failed to upload file: $error");
      throw Exception("Failed to upload file: $error");
    }
  }

  @override
  Future<String> downloadFile(String url, String filePath) async {
    try {
      return appwriteChatRepository.downloadFile(url, filePath);
    } catch (error) {
      debugPrint("Failed to download file: $error");
      throw Exception("Failed to download file: $error");
    }
  }
}

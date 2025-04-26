import 'package:appwrite/appwrite.dart';
import 'package:dartz/dartz.dart';
import 'package:messenger_clone/features/chat/model/group_message.dart';
import 'package:messenger_clone/features/messages/domain/models/message_model.dart';

abstract class AbstractChatRepository {
  Future<Either<String, List<MessageModel>>> getMessages(
    String groupChatId,
    int limit,
    int offset,
  );
  Future<Either<String, void>> sendMessage(
    MessageModel message,
    List<String> receiver,
  );
  Future<Either<String, Stream<RealtimeMessage>>> getChatStream(
    String groupChatId,
  );
  Future<Either<String, GroupMessage>> createGroupMessages({
    String? groupName,
    required List<String> userIds,
    String? avatarGroupUrl,
    bool isGroup = false,
    required String groupId,
  });
  Future<GroupMessage?> getGroupMessagesByGroupId(String groupId);
}

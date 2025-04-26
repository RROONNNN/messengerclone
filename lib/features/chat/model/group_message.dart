import 'package:messenger_clone/features/chat/model/user.dart';
import 'package:messenger_clone/features/messages/domain/models/message_model.dart';

class GroupMessage {
  final bool isGroup;
  final String groupMessagesId;
  final MessageModel? latestMessage;
  final String? avatarGroupUrl;
  final List<User> users;
  final String? groupName;
  final String groupId;

  GroupMessage({
    required this.groupMessagesId,
    this.latestMessage,
    this.users = const [],
    this.isGroup = false,
    this.avatarGroupUrl,
    this.groupName,
    required this.groupId,
  }) : assert(
         isGroup == false || groupName != null,
         'groupName must not be null if isGroup is true',
       );

  Map<String, dynamic> toJson() {
    return {
      'groupMessagesId': groupMessagesId,
      'latestMessage': latestMessage?.toJson(),
      'users': users,
      'isGroup': isGroup,
      'avatarGroupUrl': avatarGroupUrl,
      'groupName': groupName,
      'groupId': groupId,
    };
  }

  factory GroupMessage.fromJson(Map<String, dynamic> json) {
    return GroupMessage(
      groupMessagesId: json['groupMessagesId'] as String,
      latestMessage:
          json['latestMessage'] != null
              ? MessageModel.fromMap(
                json['latestMessage'] as Map<String, dynamic>,
              )
              : null,
      users:
          (json['users'] as List<dynamic>?)
              ?.map((e) => User.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      isGroup: json['isGroup'] as bool? ?? false,
      avatarGroupUrl: json['avatarGroupUrl'] as String?,
      groupName: json['groupName'] as String?,
      groupId: json['groupId'] as String,
    );
  }
}

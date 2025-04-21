import 'package:messenger_clone/features/chat/model/user.dart';
import 'package:messenger_clone/features/messages/domain/models/message_model.dart';

class GroupMessage {
  final String groupChatId;
  final MessageModel latestMessage;
  final List<User> users;

  GroupMessage({
    required this.groupChatId,
    required this.latestMessage,
    this.users = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'groupChatId': groupChatId,
      'latestMessage': latestMessage.toJson(),
      'users': users,
    };
  }

  factory GroupMessage.fromJson(Map<String, dynamic> json) {
    return GroupMessage(
      groupChatId: json['groupChatId'] as String,
      latestMessage: MessageModel.fromMap(json['latestMessage']),
      users:
          (json['users'] as List<dynamic>?)
              ?.map((e) => User.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

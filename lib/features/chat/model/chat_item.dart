import 'package:messenger_clone/features/chat/model/group_message.dart';

class ChatItem {
  final GroupMessage groupMessage;
  final String time;
  final bool hasUnread;

  ChatItem({
    required this.groupMessage,
    required this.time,
    this.hasUnread = false,
  });
}

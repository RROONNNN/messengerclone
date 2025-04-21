import 'package:messenger_clone/features/chat/model/user.dart';

class ChatItem {
  final User user;
  final String latestMessage;
  final bool isTheLatestMessSentByMe;
  final String time;
  final bool hasUnread;

  ChatItem({
    required this.user,
    required this.latestMessage,
    required this.isTheLatestMessSentByMe,
    required this.time,
    this.hasUnread = false,
  });
}

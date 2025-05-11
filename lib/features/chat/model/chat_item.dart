import 'package:messenger_clone/features/chat/model/group_message.dart';

class ChatItem {
  final GroupMessage groupMessage;
  late final DateTime _time;
  final bool hasUnread;

  ChatItem({required this.groupMessage, this.hasUnread = false}) {
    _time = groupMessage.lastMessage?.createdAt ?? DateTime.now().toUtc();
  }
  DateTime get vietnamTime {
    final utcTime = _time.toUtc();
    return utcTime.add(const Duration(hours: 7));
  }
}

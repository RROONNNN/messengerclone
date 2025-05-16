import 'package:messenger_clone/features/chat/model/group_message.dart';
import 'package:messenger_clone/features/chat/model/user.dart';

class ChatItem {
  final GroupMessage groupMessage;
  late final DateTime _time;
  late final bool hasUnread;
  final String meId;
  ChatItem({required this.groupMessage, required this.meId}) {
    _time = groupMessage.lastMessage?.createdAt ?? DateTime.now().toUtc();
    if (groupMessage.lastMessage == null) {
      hasUnread = false;
    } else if (groupMessage.lastMessage!.idFrom == meId) {
      hasUnread = false;
    } else {
      hasUnread =
          (groupMessage.lastMessage!.usersSeen.contains(
                User.createMeUser(meId),
              ))
              ? false
              : true;
    }
  }
  DateTime get vietnamTime {
    final utcTime = _time.toUtc();
    return utcTime.add(const Duration(hours: 7));
  }

  ChatItem copyWith({
    GroupMessage? groupMessage,
    DateTime? time,
    bool? hasUnread,
  }) {
    return ChatItem(
      groupMessage: groupMessage ?? this.groupMessage,
      meId: meId,
    );
  }
}

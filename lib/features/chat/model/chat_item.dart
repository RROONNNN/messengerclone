class ChatItem {
  final String title;
  final String subtitle;
  final String time;
  final bool hasUnread;
  final String avatar;
  final bool isActive;

  ChatItem({
    required this.avatar,
    required this.title,
    required this.subtitle,
    required this.time,
    this.hasUnread = false,
    this.isActive = true,
  });
}
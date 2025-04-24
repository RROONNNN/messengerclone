class StoryItem {
  final String title;
  final String imageUrl;
  final String avatarUrl;
  final bool hasBorder;
  final int notificationCount;

  const StoryItem({
    required this.title,
    required this.imageUrl,
    required this.avatarUrl,
    this.hasBorder = true,
    this.notificationCount = 0,
  });
}
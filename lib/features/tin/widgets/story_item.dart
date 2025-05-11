
class StoryItem {
  final String userId;
  final String title;
  final String imageUrl;
  final String avatarUrl;
  final bool hasBorder;
  final int notificationCount;
  final bool? isVideo;
  final DateTime postedAt;
  final int totalStories;
  final String? mediaUrl;
  final String? mediaType;

  const StoryItem({
    required this.userId,
    required this.title,
    required this.imageUrl,
    required this.avatarUrl,
    this.hasBorder = true,
    this.notificationCount = 0,
    this.isVideo = false,
    required this.postedAt,
    this.totalStories = 1,
    this.mediaUrl,
    this.mediaType,
  }) : assert(totalStories >= 1, 'totalStories must be at least 1');
}
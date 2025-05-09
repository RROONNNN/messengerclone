import 'package:flutter/material.dart';

class StoryItem {
  final String userId; // New field for unique user identification
  final String title;
  final String imageUrl;
  final String avatarUrl;
  final bool hasBorder;
  final int notificationCount;
  final bool? isVideo;
  final List<TextOverlay> textOverlays;
  final DateTime postedAt;
  final int totalStories;

  const StoryItem({
    required this.userId,
    required this.title,
    required this.imageUrl,
    required this.avatarUrl,
    this.hasBorder = true,
    this.notificationCount = 0,
    this.isVideo = false,
    this.textOverlays = const [],
    required this.postedAt,
    this.totalStories = 1,
  }) : assert(totalStories >= 1, 'totalStories must be at least 1');
}

class TextOverlay {
  final String content;
  final TextStyle style;
  final Offset position;

  const TextOverlay({
    required this.content,
    this.style = const TextStyle(
      color: Colors.white,
      fontSize: 16,
      fontWeight: FontWeight.bold,
    ),
    this.position = const Offset(16, 150),
  });
}
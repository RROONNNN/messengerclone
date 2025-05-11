import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:messenger_clone/common/extensions/custom_theme_extension.dart';
import 'package:messenger_clone/common/widgets/custom_text_style.dart';
import 'package:messenger_clone/features/tin/story_item.dart';
import 'package:messenger_clone/features/tin/pages/detail_tinPage.dart';
import 'package:messenger_clone/features/tin/pages/tin_uploadPage.dart';
import 'package:messenger_clone/features/tin/pages/gallery_uploadTin.dart'; // Add this import

class TinPage extends StatefulWidget {
  const TinPage({super.key});

  @override
  State<TinPage> createState() => _TinPageState();
}

class _TinPageState extends State<TinPage> {
  final List<StoryItem> stories = [
    StoryItem(
      userId: 'add_to_tin',
      title: 'Thêm vào tin',
      imageUrl: 'https://picsum.photos/150?random=1',
      avatarUrl: 'https://picsum.photos/50?random=1',
      notificationCount: 0,
      postedAt: DateTime.now().subtract(const Duration(hours: 12)),
    ),
    StoryItem(
      userId: 'hong_nhung',
      title: 'Hồng Nhung',
      imageUrl: 'https://picsum.photos/4000/4000?random=20',
      avatarUrl: 'https://picsum.photos/50?random=20',
      notificationCount: 3,
      isVideo: false,
      postedAt: DateTime.now().subtract(const Duration(hours: 6)),
      totalStories: 1,
      textOverlays: const [],
    ),
    StoryItem(
      userId: 'ha_vi',
      title: 'Nguyễn Thị Hà Vi',
      imageUrl: 'https://www.sample-videos.com/video123/mp4/720/big_buck_bunny_720p_1mb.mp4',
      avatarUrl: 'https://picsum.photos/50?random=21',
      notificationCount: 1,
      isVideo: true,
      postedAt: DateTime.now().subtract(const Duration(hours: 12)),
      totalStories: 5,
      textOverlays: const [
        TextOverlay(content: '@PhanTuongLinh'),
        TextOverlay(
          content: 'Cùng chụp đồ rét code đây chứ 😎',
          position: Offset(16, 180),
        ),
      ],
    ),
    StoryItem(
      userId: 'ha_vi',
      title: 'Nguyễn Thị Hà Vi',
      imageUrl: 'https://picsum.photos/1600/900?random=22',
      avatarUrl: 'https://picsum.photos/50?random=21',
      notificationCount: 1,
      isVideo: false,
      postedAt: DateTime.now().subtract(const Duration(hours: 12)),
      totalStories: 5,
      textOverlays: const [],
    ),
    StoryItem(
      userId: 'ha_vi',
      title: 'Nguyễn Thị Hà Vi',
      imageUrl: 'https://picsum.photos/900/1600?random=23',
      avatarUrl: 'https://picsum.photos/50?random=21',
      notificationCount: 1,
      isVideo: false,
      postedAt: DateTime.now().subtract(const Duration(hours: 12)),
      totalStories: 5,
      textOverlays: const [],
    ),
    StoryItem(
      userId: 'ha_vi',
      title: 'Nguyễn Thị Hà Vi',
      imageUrl: 'https://picsum.photos/4000/4000?random=24',
      avatarUrl: 'https://picsum.photos/50?random=21',
      notificationCount: 1,
      isVideo: false,
      postedAt: DateTime.now().subtract(const Duration(hours: 12)),
      totalStories: 5,
      textOverlays: const [],
    ),
    StoryItem(
      userId: 'ha_vi',
      title: 'Nguyễn Thị Hà Vi',
      imageUrl: 'https://www.sample-videos.com/video123/mp4/720/big_buck_bunny_720p_1mb.mp4',
      avatarUrl: 'https://picsum.photos/50?random=21',
      notificationCount: 1,
      isVideo: true,
      postedAt: DateTime.now().subtract(const Duration(hours: 12)),
      totalStories: 5,
      textOverlays: const [],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Group stories by userId to display only the first story per user
    final Map<String, List<StoryItem>> groupedStories = {};
    for (var story in stories) {
      if (groupedStories.containsKey(story.userId)) {
        groupedStories[story.userId]!.add(story);
      } else {
        groupedStories[story.userId] = [story];
      }
    }

    final displayStories = groupedStories.entries.map((entry) {
      return entry.value.first;
    }).toList();

    return Scaffold(
      backgroundColor: context.theme.bg,
      appBar: AppBar(
        backgroundColor: context.theme.bg,
        elevation: 0,
        title: const TitleText("Tin"),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(8.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8.0,
          mainAxisSpacing: 8.0,
          childAspectRatio: 0.7,
        ),
        itemCount: displayStories.length,
        itemBuilder: (context, index) {
          final story = displayStories[index];
          final isFirst = index == 0;
          return GestureDetector(
            onTap: () async {
              if (isFirst) {
                // Navigate to GallerySelectionPage for adding a new story
                final newStory = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GallerySelectionPage(),
                  ),
                );
                if (newStory != null && newStory is StoryItem) {
                  setState(() {
                    stories.add(newStory);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã thêm tin mới (mô phỏng)!')),
                  );
                }
              } else {
                // Navigate to StoryDetailPage for viewing existing stories
                final userStories = stories.where((s) => s.userId == story.userId).toList();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StoryDetailPage(
                      stories: userStories,
                      initialIndex: 0,
                    ),
                  ),
                );
              }
            },
            child: StoryCard(story: story, isFirst: isFirst),
          );
        },
      ),
    );
  }
}

class StoryCard extends StatelessWidget {
  final StoryItem story;
  final bool isFirst;

  const StoryCard({super.key, required this.story, required this.isFirst});

  @override
  Widget build(BuildContext context) {
    // Check if imageUrl is a local file path
    bool isLocalImage = story.imageUrl.startsWith('/');

    return ClipRRect(
      borderRadius: BorderRadius.circular(16.0),
      child: Stack(
        children: [
          // Display image (local or network)
          if (isLocalImage)
            Image.file(
              File(story.imageUrl),
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.error, color: Colors.red),
            )
          else
            Image(
              image: CachedNetworkImageProvider(story.imageUrl),
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.error, color: Colors.red),
            ),
          if (!isFirst)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: story.hasBorder ? context.theme.blue : Colors.transparent,
                ),
                child: CircleAvatar(
                  radius: 18,
                  backgroundImage: CachedNetworkImageProvider(story.avatarUrl),
                ),
              ),
            ),
          if (isFirst)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: const Icon(
                  Icons.add,
                  size: 36,
                  color: Colors.black,
                ),
              ),
            ),
          if (story.notificationCount > 0)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  story.notificationCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: 8,
            left: 8,
            right: 8,
            child: Text(
              story.title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
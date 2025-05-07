import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:messenger_clone/common/extensions/custom_theme_extension.dart';
import 'package:messenger_clone/common/widgets/custom_text_style.dart';
import 'package:messenger_clone/features/tin/story_item.dart'; // Sửa import

class TinPage extends StatelessWidget {
  const TinPage({super.key});

  final List<StoryItem> stories = const [
    StoryItem(
      title: 'Thêm vào tin',
      imageUrl: 'https://picsum.photos/150?random=1',
      avatarUrl: 'https://picsum.photos/50?random=1',
      notificationCount: 0,
    ),
    // ... (các StoryItem khác như bạn đã cung cấp)
    StoryItem(
      title: 'Hồng Nhung',
      imageUrl: 'https://picsum.photos/150?random=20',
      avatarUrl: 'https://picsum.photos/50?random=20',
      notificationCount: 3,
    ),
  ];

  @override
  Widget build(BuildContext context) {
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
        itemCount: stories.length,
        itemBuilder: (context, index) {
          final story = stories[index];
          return GestureDetector(
            onTap: () {
              // TODO: Điều hướng đến trang chi tiết tin
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Xem chi tiết: ${story.title}')),
              );
            },
            child: StoryCard(story: story, isFirst: index == 0),
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
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.0),
            image: DecorationImage(
              image: CachedNetworkImageProvider(story.imageUrl),
              fit: BoxFit.cover,
            ),
          ),
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
    );
  }
}

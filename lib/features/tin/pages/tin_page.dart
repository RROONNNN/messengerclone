import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:messenger_clone/common/extensions/custom_theme_extension.dart';
import 'package:messenger_clone/common/widgets/custom_text_style.dart';
import 'StoryItem.dart'; // Sửa import

class TinPage extends StatelessWidget {
  const TinPage({super.key});

  // Dữ liệu mẫu cho Stories (tăng lên 20 tin)
  final List<StoryItem> stories = const [
    StoryItem(
      title: 'Thêm vào tin',
      imageUrl: 'https://picsum.photos/150?random=1',
      avatarUrl: 'https://picsum.photos/50?random=1',
      notificationCount: 0, // Story đầu tiên không có thông báo
    ),
    StoryItem(
      title: 'Phẩm Hồng Ngân',
      imageUrl: 'https://picsum.photos/150?random=2',
      avatarUrl: 'https://picsum.photos/50?random=2',
      notificationCount: 2,
    ),
    StoryItem(
      title: 'Brainrot 💩',
      imageUrl: 'https://picsum.photos/150?random=3',
      avatarUrl: 'https://picsum.photos/50?random=3',
      notificationCount: 2,
    ),
    StoryItem(
      title: 'Võ Thành Lâm',
      imageUrl: 'https://picsum.photos/150?random=4',
      avatarUrl: 'https://picsum.photos/50?random=4',
      notificationCount: 1,
    ),
    StoryItem(
      title: 'Bảo Văn',
      imageUrl: 'https://picsum.photos/150?random=5',
      avatarUrl: 'https://picsum.photos/50?random=5',
      notificationCount: 1,
    ),
    StoryItem(
      title: 'Đức căng nét khi thắng...',
      imageUrl: 'https://picsum.photos/150?random=6',
      avatarUrl: 'https://picsum.photos/50?random=6',
      notificationCount: 2,
    ),
    StoryItem(
      title: 'Lan Anh',
      imageUrl: 'https://picsum.photos/150?random=7',
      avatarUrl: 'https://picsum.photos/50?random=7',
      notificationCount: 3,
    ),
    StoryItem(
      title: 'Minh Tuấn',
      imageUrl: 'https://picsum.photos/150?random=8',
      avatarUrl: 'https://picsum.photos/50?random=8',
      notificationCount: 1,
    ),
    StoryItem(
      title: 'Hà Phương',
      imageUrl: 'https://picsum.photos/150?random=9',
      avatarUrl: 'https://picsum.photos/50?random=9',
      notificationCount: 2,
    ),
    StoryItem(
      title: 'Trần Quốc Anh',
      imageUrl: 'https://picsum.photos/150?random=10',
      avatarUrl: 'https://picsum.photos/50?random=10',
      notificationCount: 4,
    ),
    StoryItem(
      title: 'Ngọc Linh',
      imageUrl: 'https://picsum.photos/150?random=11',
      avatarUrl: 'https://picsum.photos/50?random=11',
      notificationCount: 1,
    ),
    StoryItem(
      title: 'Thanh Huyền',
      imageUrl: 'https://picsum.photos/150?random=12',
      avatarUrl: 'https://picsum.photos/50?random=12',
      notificationCount: 2,
    ),
    StoryItem(
      title: 'Đức Anh',
      imageUrl: 'https://picsum.photos/150?random=13',
      avatarUrl: 'https://picsum.photos/50?random=13',
      notificationCount: 3,
    ),
    StoryItem(
      title: 'Mai Anh',
      imageUrl: 'https://picsum.photos/150?random=14',
      avatarUrl: 'https://picsum.photos/50?random=14',
      notificationCount: 1,
    ),
    StoryItem(
      title: 'Hoàng Nam',
      imageUrl: 'https://picsum.photos/150?random=15',
      avatarUrl: 'https://picsum.photos/50?random=15',
      notificationCount: 2,
    ),
    StoryItem(
      title: 'Thu Hà',
      imageUrl: 'https://picsum.photos/150?random=16',
      avatarUrl: 'https://picsum.photos/50?random=16',
      notificationCount: 3,
    ),
    StoryItem(
      title: 'Quang Vinh',
      imageUrl: 'https://picsum.photos/150?random=17',
      avatarUrl: 'https://picsum.photos/50?random=17',
      notificationCount: 1,
    ),
    StoryItem(
      title: 'Phương Thảo',
      imageUrl: 'https://picsum.photos/150?random=18',
      avatarUrl: 'https://picsum.photos/50?random=18',
      notificationCount: 2,
    ),
    StoryItem(
      title: 'Tùng Dương',
      imageUrl: 'https://picsum.photos/150?random=19',
      avatarUrl: 'https://picsum.photos/50?random=19',
      notificationCount: 1,
    ),
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
          return StoryCard(story: story, isFirst: index == 0);
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
        // Hình ảnh story
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.0),
            image: DecorationImage(
              image: CachedNetworkImageProvider(story.imageUrl),
              fit: BoxFit.cover,
            ),
          ),
        ),
        // Avatar (không hiển thị cho story đầu tiên)
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
        // Nút "+" cho story đầu tiên
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
                size: 36, // To bằng avatar
                color: Colors.black,
              ),
            ),
          ),
        // Số tin ở góc trên bên phải của mỗi tin
        if (story.notificationCount > 0)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7), // Nền đen với opacity
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                story.notificationCount.toString(),
                style: const TextStyle(
                  color: Colors.white, // Chữ trắng
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        // Tiêu đề
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
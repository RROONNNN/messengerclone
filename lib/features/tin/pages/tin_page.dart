import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:messenger_clone/common/extensions/custom_theme_extension.dart';
import 'package:messenger_clone/common/widgets/custom_text_style.dart';
import 'package:messenger_clone/features/tin/pages/detail_tinPage.dart';
import 'package:messenger_clone/features/tin/pages/gallery_uploadTin.dart';
import 'package:messenger_clone/common/services/app_write_service.dart';
import '../../../common/widgets/dialog/custom_alert_dialog.dart';
import '../widgets/story_item.dart';

class TinPage extends StatefulWidget {
  const TinPage({super.key});

  @override
  State<TinPage> createState() => _TinPageState();
}

class _TinPageState extends State<TinPage> {
  final List<StoryItem> stories = [];
  String? _currentUserAvatarUrl;

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserData();
    _fetchStoriesFromAppwrite();
  }

  Future<void> _fetchCurrentUserData() async {
    try {
      final userId = await AppWriteService.isLoggedIn();
      if (userId != null) {
        final userData = await AppWriteService.fetchUserDataById(userId);
        setState(() {
          _currentUserAvatarUrl = userData['photoUrl'] as String? ??
              'https://images.hcmcpv.org.vn/res/news/2024/02/24-02-2024-ve-su-dung-co-dang-va-hinh-anh-co-dang-cong-san-viet-nam-FE119635-details.jpg?vs=24022024094023';
        });
      }
    } catch (e) {
      if (mounted) {
        CustomAlertDialog.show(
          context: context,
          title: 'Lỗi',
          message: 'Không thể lấy thông tin người dùng: $e',
        );
      }
    }
  }

  Future<void> _fetchStoriesFromAppwrite() async {
    try {
      final userId = await AppWriteService.isLoggedIn();
      if (userId == null) {
        if (mounted) {
          CustomAlertDialog.show(
            context: context,
            title: 'Lỗi',
            message: 'Vui lòng đăng nhập để xem tin!',
          );
        }
        return;
      }

      final fetchedStories = await AppWriteService.fetchFriendsStories(userId);

      final storyItems = await Future.wait(fetchedStories.map((data) async {
        final userData = await AppWriteService.fetchUserDataById(data['userId'] as String);
        int totalStories = data['totalStories'] as int;
        if (data['mediaType'] == 'video') {
          totalStories = 10;
        }
        return StoryItem(
          userId: data['userId'] as String,
          title: userData['userName'] as String? ?? 'Unknown',
          imageUrl: data['mediaUrl'] as String,
          avatarUrl: userData['photoUrl'] as String? ?? '',
          isVideo: data['mediaType'] == 'video',
          postedAt: DateTime.parse(data['createdAt'] as String),
          totalStories: totalStories,
        );
      }).toList());

      if (mounted) {
        setState(() {
          stories.addAll(storyItems);
          stories.sort((a, b) => b.postedAt.compareTo(a.postedAt));
        });
      }
    } catch (e) {
      if (mounted) {
        CustomAlertDialog.show(
          context: context,
          title: 'Lỗi',
          message: 'Lỗi khi lấy danh sách tin: $e',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, List<StoryItem>> groupedStories = {};
    for (var story in stories) {
      if (groupedStories.containsKey(story.userId)) {
        groupedStories[story.userId]!.add(story);
      } else {
        groupedStories[story.userId] = [story];
      }
    }

    final displayStories = [
      StoryItem(
        userId: 'add_to_tin',
        title: 'Thêm vào tin',
        imageUrl: _currentUserAvatarUrl ??
            'https://images.hcmcpv.org.vn/res/news/2024/02/24-02-2024-ve-su-dung-co-dang-va-hinh-anh-co-dang-cong-san-viet-nam-FE119635-details.jpg?vs=24022024094023',
        avatarUrl: '',
        notificationCount: 0,
        postedAt: DateTime.now(),
      ),
      ...groupedStories.entries.map((entry) => entry.value.first),
    ];

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
                final newStory = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const GallerySelectionPage()),
                );
                if (newStory != null && newStory is StoryItem && mounted) {
                  setState(() {
                    stories.add(newStory);
                    stories.sort((a, b) => b.postedAt.compareTo(a.postedAt));
                  });
                  CustomAlertDialog.show(
                    context: context,
                    title: 'Thành công',
                    message: 'Đã thêm tin mới!',
                  );
                }
              } else {
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

class StoryCard extends StatefulWidget {
  final StoryItem story;
  final bool isFirst;

  const StoryCard({super.key, required this.story, required this.isFirst});

  @override
  State<StoryCard> createState() => _StoryCardState();
}

class _StoryCardState extends State<StoryCard> {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16.0),
      child: Stack(
        children: [
          CachedNetworkImage(
            imageUrl: widget.isFirst
                ? widget.story.imageUrl
                : (widget.story.isVideo)
                ? 'https://images.hcmcpv.org.vn/res/news/2024/02/24-02-2024-ve-su-dung-co-dang-va-hinh-anh-co-dang-cong-san-viet-nam-FE119635-details.jpg?vs=24022024094023'
                : widget.story.imageUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorWidget: (context, error, stackTrace) => const Icon(Icons.error, color: Colors.red),
          ),
          if (!widget.isFirst)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.story.hasBorder ? context.theme.blue : Colors.transparent,
                ),
                child: CircleAvatar(
                  radius: 18,
                  backgroundImage: CachedNetworkImageProvider(widget.story.avatarUrl),
                ),
              ),
            ),
          if (widget.isFirst)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.theme.white.withOpacity(0.9),
                ),
                child: Icon(
                  Icons.add,
                  size: 36,
                  color: context.theme.blue,
                ),
              ),
            ),
          if (widget.story.notificationCount > 0)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: context.theme.grey.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.story.notificationCount.toString(),
                  style: TextStyle(
                    color: context.theme.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          if ((widget.story.isVideo) && !widget.isFirst)
            Positioned(
              child: Center(
                child: Icon(
                  Icons.play_circle_outline,
                  color: context.theme.white.withOpacity(0.7),
                  size: 40,
                ),
              ),
            ),
          Positioned(
            bottom: 8,
            left: 8,
            right: 8,
            child: Text(
              widget.story.title,
              style: TextStyle(
                color: context.theme.white,
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
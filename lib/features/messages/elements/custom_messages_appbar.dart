import 'package:flutter/material.dart';
import '../../../common/widgets/custom_text_style.dart';
import '../../../common/widgets/elements/custom_round_avatar.dart';
import '../../../common/extensions/custom_theme_extension.dart';

class FakeUser {
  final String name;
  final bool isActive;
  final Duration offlineDuration;

  FakeUser({
    required this.name,
    required this.isActive,
    required this.offlineDuration,
  });
}

class CustomMessagesAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final FakeUser user;
  final bool isMe;
  final Color? backgroundColor;
  final void Function()? callFunc;
  final void Function()? videoCallFunc;
  final void Function()? onTapAvatar;
  const CustomMessagesAppBar({
    super.key,
    required this.isMe,
    this.backgroundColor,
    required this.user,
    this.callFunc,
    this.videoCallFunc,
    this.onTapAvatar,
  });
  String _getOfflineDurationText() {
    if (user.offlineDuration.inDays > 0) {
      return "Hoạt động ${user.offlineDuration.inDays} ngày trước";
    } else if (user.offlineDuration.inHours > 0) {
      return "Hoạt động ${user.offlineDuration.inHours} giờ trước";
    } else {
      return "Hoạt động ${user.offlineDuration.inMinutes} phút trước";
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      iconTheme: IconThemeData(color: context.theme.blue),
      backgroundColor: context.theme.appBar,
      elevation: 0,
      leadingWidth: 50,
      title: GestureDetector(
        onTap: onTapAvatar,
        child: Row(
          children: [
            CustomRoundAvatar(isActive: user.isActive, radius: 16),
            SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ContentText(
                  user.name,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                ContentText(
                  user.isActive ? "Đang hoạt động" : _getOfflineDurationText(),
                  color: context.theme.textGrey,
                ),
              ],
            ),
          ],
        ),
      ),
      actions:
          isMe
              ? [
                IconButton(
                  onPressed: callFunc ?? () {},
                  icon: Icon(Icons.local_phone),
                ),
                const SizedBox(width: 8),

                IconButton(
                  onPressed: videoCallFunc ?? () {},
                  icon: Icon(Icons.videocam),
                ),
                const SizedBox(width: 8),
              ]
              : [const SizedBox()],
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: IconButton(
          padding: EdgeInsets.all(0),
          iconSize: 18,
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back_ios_new),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}

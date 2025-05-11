import 'package:flutter/material.dart';

import '../../../common/widgets/custom_text_style.dart';
import '../../../common/widgets/elements/custom_round_avatar.dart';
import '../../../common/extensions/custom_theme_extension.dart';
import '../../chat/model/user.dart';

class CustomMessagesAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final User user;
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
    final duration = DateTime.now().difference(user.lastSeen);

    if (duration.inDays > 0) {
      return "Hoạt động ${duration.inDays} ngày trước";
    } else if (duration.inHours > 0) {
      return "Hoạt động ${duration.inHours} giờ trước";
    } else if (duration.inMinutes > 0) {
      return "Hoạt động ${duration.inMinutes} phút trước";
    } else {
      return "Đang hoạt động";
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      iconTheme: IconThemeData(color: context.theme.blue),
      backgroundColor: context.theme.appBar,
      elevation: 0,
      leadingWidth: 40,
      titleSpacing: 0,
      actionsPadding: EdgeInsets.all(0),
      title: GestureDetector(
        onTap: onTapAvatar,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            CustomRoundAvatar(
              isActive: user.isActive,
              radius: 18,
              avatarUrl: user.photoUrl,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ContentText(
                    user.name,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    overflow: TextOverflow.ellipsis,
                  ),
                  ContentText(
                    user.isActive
                        ? "Đang hoạt động"
                        : _getOfflineDurationText(),
                    overflow: TextOverflow.ellipsis,
                    color: context.theme.textGrey,
                  ),
                ],
              ),
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
      leading: IconButton(
        padding: EdgeInsets.all(0),
        iconSize: 18,
        onPressed: () {
          Navigator.pop(context);
        },
        icon: Icon(Icons.arrow_back_ios_new),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}

import 'package:flutter/material.dart';

import '../../../common/widgets/custom_text_style.dart';
import '../../../common/widgets/elements/custom_round_avatar.dart';
import '../../../common/extensions/custom_theme_extension.dart';
import '../../chat/model/user.dart';

class CustomMessagesAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final User? user;
  final bool isMe;
  final Color? backgroundColor;
  final bool isGroup;
  final String? groupName;
  final String? avatarGroupUrl;
  final void Function()? callFunc;
  final void Function()? videoCallFunc;
  final void Function()? onTapAvatar;

  const CustomMessagesAppBar._({
    super.key,
    required this.isMe,
    this.backgroundColor,
    this.user,
    this.callFunc,
    this.videoCallFunc,
    this.onTapAvatar,
    this.isGroup = false,
    this.groupName,
    this.avatarGroupUrl,
  });

  factory CustomMessagesAppBar({
    required bool isMe,
    Color? backgroundColor,
    required User user,
    void Function()? callFunc,
    void Function()? videoCallFunc,
    void Function()? onTapAvatar,
  }) {
    return CustomMessagesAppBar._(
      isMe: isMe,
      backgroundColor: backgroundColor,
      user: user,
      callFunc: callFunc,
      videoCallFunc: videoCallFunc,
      onTapAvatar: onTapAvatar,
    );
  }

  factory CustomMessagesAppBar.group({
    required bool isMe,
    Color? backgroundColor,
    void Function()? callFunc,
    void Function()? videoCallFunc,
    void Function()? onTapAvatar,
    required String groupName,
    String? avatarGroupUrl,
  }) {
    return CustomMessagesAppBar._(
      isMe: isMe,
      backgroundColor: backgroundColor,
      callFunc: callFunc,
      videoCallFunc: videoCallFunc,
      onTapAvatar: onTapAvatar,
      isGroup: true,
      groupName: groupName,
      avatarGroupUrl: avatarGroupUrl,
    );
  }

  String _getOfflineDurationText() {
    final duration = DateTime.now().difference(
      user?.lastSeen ?? DateTime.now(),
    );

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
              isActive: isGroup ? true : user?.isActive ?? true,
              radius: 18,
              avatarUrl: isGroup ? avatarGroupUrl : user?.photoUrl,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ContentText(
                    isGroup ? groupName : user?.name,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    overflow: TextOverflow.ellipsis,
                  ),
                  ContentText(
                    isGroup ? "Đang hoạt động" : _getOfflineDurationText(),
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
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

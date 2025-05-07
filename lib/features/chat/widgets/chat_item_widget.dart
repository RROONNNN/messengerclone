import 'package:flutter/material.dart';
import 'package:messenger_clone/common/extensions/custom_theme_extension.dart';
import 'package:messenger_clone/common/services/common_function.dart';
import 'package:messenger_clone/common/services/date_time_format.dart';
import 'package:messenger_clone/common/services/hive_service.dart';
import 'package:messenger_clone/features/chat/model/user.dart';

import '../../../common/widgets/custom_text_style.dart';
import '../../../common/widgets/elements/custom_round_avatar.dart';
import '../model/chat_item.dart';

class ChatItemWidget extends StatelessWidget {
  final ChatItem item;
  final VoidCallback? onTap;
  final Function(ChatItem)? onLongPress;
  final double avatarRadius;

  const ChatItemWidget({
    super.key,
    required this.item,
    this.onTap,
    this.onLongPress,
    this.avatarRadius = 30,
  });
  Future<String> _init() async {
    return await HiveService.instance.getCurrentUserId();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _init(),
      builder: (context, currentUserIdSnapshot) {
        if (currentUserIdSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        // final List<User> others =
        //     item.groupMessage.users
        //         .where((user) => user.id != currentUserIdSnapshot.data)
        //         .toList();
        List<User> others = CommonFunction.getOthers(
          item.groupMessage.users,
          currentUserIdSnapshot.data!,
        );
        if (others.isEmpty) {
          others = [item.groupMessage.users.first];
        }

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 16,
          ),
          dense: false,
          onTap: onTap,
          onLongPress: () => onLongPress?.call(item),
          title: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: CustomRoundAvatar(
                  radius: avatarRadius,
                  isActive: others.first.isActive,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            item.groupMessage.isGroup
                                ? item.groupMessage.groupName!
                                : others.first.name,
                            style: TextStyle(
                              fontWeight:
                                  item.hasUnread
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                              fontSize: 18,
                              overflow: TextOverflow.ellipsis,
                              color: context.theme.textColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.6,
                            ),
                            child: ContentText(
                              item.groupMessage.lastMessage?.content,
                              color:
                                  item.hasUnread
                                      ? context.theme.textColor
                                      : context.theme.textColor.withOpacity(
                                        0.5,
                                      ),
                              fontWeight:
                                  item.hasUnread
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                              fontSize: 16,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                            top: 4,
                            left: 4,
                            right: 4,
                          ),
                          child: Text(
                            "·",
                            style: TextStyle(
                              color:
                                  item.hasUnread
                                      ? context.theme.textColor
                                      : context.theme.textColor.withOpacity(
                                        0.5,
                                      ),
                              fontSize: 16,
                              fontWeight:
                                  item.hasUnread
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            DateTimeFormat.dateTimeToString(item.vietnamTime),
                            style: TextStyle(
                              fontSize: 14,
                              color:
                                  item.hasUnread
                                      ? context.theme.textColor
                                      : context.theme.textColor.withOpacity(
                                        0.5,
                                      ),
                              fontWeight:
                                  item.hasUnread
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

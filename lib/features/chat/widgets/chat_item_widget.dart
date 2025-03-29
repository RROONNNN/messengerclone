import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      dense: false,
      onTap: onTap,
      onLongPress: () => onLongPress?.call(item),
      title: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CustomRoundAvatar(
              avatarImage : NetworkImage(item.avatar),
              radius: avatarRadius,
              isActive: item.isActive,
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
                        item.title,
                        style: TextStyle(
                          fontWeight: item.hasUnread ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize:  18,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (item.subtitle.isNotEmpty)
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            item.subtitle,
                            style: TextStyle(
                              color: item.hasUnread ? Colors.black : Colors.grey,
                              fontWeight: item.hasUnread ? FontWeight.bold : FontWeight.normal,
                              fontSize: 16,
                              overflow: TextOverflow.ellipsis,
                            ),
                            maxLines: 1,
                          ),
                        ),
                      ),
                    Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          "·",
                          style: TextStyle(
                            color: item.hasUnread ? Colors.black : Colors.grey,
                            fontSize: 16,
                            fontWeight: item.hasUnread ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                    ),
                    Text(
                      item.time,
                      style: TextStyle(
                        fontSize: 14,
                        color: item.hasUnread ? Colors.black : Colors.grey,
                        fontWeight: item.hasUnread ? FontWeight.bold : FontWeight.normal,
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
  }
}
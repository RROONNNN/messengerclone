import 'package:flutter/material.dart';
import '../../extensions/custom_theme_extension.dart';
import '../custom_text_style.dart';

class CustomMessageItem extends StatelessWidget {
  final bool isMe;
  final bool isTextMessage;
  final bool isImageMessage;
  final Widget child;
  final List<String> reactions;
  final void Function()? onLongPress;
  const CustomMessageItem({
    super.key,
    required this.isMe,
    required this.child,
    this.isImageMessage = false,
    this.isTextMessage = false,
    this.reactions = const [],
    this.onLongPress,
  }) : assert(
         (isTextMessage ? 1 : 0) + (isImageMessage ? 1 : 0) < 2,
         "only and must be one of isImageMessage, isTextMessage can be true",
       );

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onLongPress: onLongPress,
            child: Container(
              decoration: BoxDecoration(
                color:
                    isImageMessage
                        ? null
                        : isMe
                        ? context.theme.blue
                        : context.theme.grey,
                borderRadius: BorderRadius.all(Radius.circular(15)),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth:
                      isImageMessage
                          ? MediaQuery.of(context).size.width * 0.6
                          : MediaQuery.of(context).size.width * 0.8,
                  maxHeight:
                      isImageMessage
                          ? MediaQuery.of(context).size.width * 0.5
                          : double.infinity,
                  minWidth: 0,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: child,
                ),
              ),
            ),
          ),
        ),
        if (reactions.isNotEmpty)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 2, horizontal: 5),
              decoration: BoxDecoration(
                color: context.theme.grey,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Wrap(
                spacing: 4.0,
                children: [
                  ...reactions.toSet().map(
                    (reaction) => ContentText(reaction, fontSize: 12),
                  ),
                  ContentText("${reactions.length}", fontSize: 12),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

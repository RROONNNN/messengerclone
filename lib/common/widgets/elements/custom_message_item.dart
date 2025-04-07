import 'package:flutter/material.dart';
import '../../extensions/custom_theme_extension.dart';
import '../custom_text_style.dart';

class CustomMessageItem extends StatefulWidget {
  final bool isMe;
  final bool isTextMessage;
  final bool isImageMessage;
  final Widget child;
  const CustomMessageItem({
    super.key,
    required this.isMe,
    required this.child,
    this.isImageMessage = false,
    this.isTextMessage = false,
  }) : assert(
         (isTextMessage ? 1 : 0) + (isImageMessage ? 1 : 0) < 2,
         "only and must be one of isImageMessage, isTextMessage can be true",
       );

  @override
  State<CustomMessageItem> createState() => _CustomMessageItemState();
}

class _CustomMessageItemState extends State<CustomMessageItem> {
  late List<String> reactions;

  @override
  void initState() {
    super.initState();
    reactions = [];
  }

  void addReaction(String reaction) {
    setState(() {
      reactions.add(reaction);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onLongPress: () {
              showDialog<List<String>>(
                context: context,
                builder:
                    (context) => AlertDialog(
                      contentPadding: EdgeInsets.all(5),
                      backgroundColor: context.theme.tileColor,
                      content: SizedBox(
                        width: 250,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,

                          children:
                              ['👍', '❤️', '😂', '😮', '😢', '👏'].map((
                                reaction,
                              ) {
                                return GestureDetector(
                                  onTap: () {
                                    addReaction(reaction);
                                    Navigator.of(context).pop();
                                  },
                                  child: ContentText(
                                    reaction,
                                    fontSize: 22,
                                    overflow: TextOverflow.clip,
                                  ),
                                );
                              }).toList(),
                        ),
                      ),
                    ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color:
                    widget.isImageMessage
                        ? null
                        : widget.isMe
                        ? context.theme.blue
                        : context.theme.grey,
                borderRadius: BorderRadius.all(Radius.circular(15)),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth:
                      widget.isImageMessage
                          ? MediaQuery.of(context).size.width * 0.6
                          : MediaQuery.of(context).size.width * 0.7,
                  maxHeight:
                      widget.isImageMessage
                          ? MediaQuery.of(context).size.width * 0.5
                          : double.infinity,
                  minWidth: 0,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: widget.child,
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

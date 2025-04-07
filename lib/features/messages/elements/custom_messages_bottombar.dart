import 'package:flutter/material.dart';

import '../../../common/extensions/custom_theme_extension.dart';

class CustomMessagesBottomBar extends StatefulWidget {
  final TextEditingController textController;
  final void Function()? onSendMessage;
  const CustomMessagesBottomBar({
    super.key,
    required this.textController,
    this.onSendMessage,
  });

  @override
  State<CustomMessagesBottomBar> createState() =>
      _CustomMessagesBottomBarState();
}

class _CustomMessagesBottomBarState extends State<CustomMessagesBottomBar> {
  final FocusNode _focusNode = FocusNode();
  late bool _isFocused;
  late bool _isExpandedLeft;

  @override
  void initState() {
    super.initState();
    _isFocused = false;
    _isExpandedLeft = false;
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });

    widget.textController.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return IconTheme(
      data: IconThemeData(color: context.theme.blue),
      child: Container(
        decoration: BoxDecoration(color: context.theme.appBar),
        height: 50,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            (_isFocused && _isExpandedLeft == false)
                ? SizedBox()
                : IconButton(onPressed: () {}, icon: Icon(Icons.add_circle)),
            (_isFocused && _isExpandedLeft == false)
                ? SizedBox()
                : IconButton(onPressed: () {}, icon: Icon(Icons.camera_alt)),
            (_isFocused && _isExpandedLeft == false)
                ? SizedBox()
                : IconButton(onPressed: () {}, icon: Icon(Icons.image)),
            (_isFocused && _isExpandedLeft == false)
                ? SizedBox()
                : IconButton(onPressed: () {}, icon: Icon(Icons.mic)),
            (_isFocused && _isExpandedLeft == false)
                ? SizedBox(
                  width: 30,
                  child: IconButton(
                    padding: EdgeInsets.all(0),
                    onPressed: () {
                      setState(() {
                        _isExpandedLeft = !_isExpandedLeft;
                      });
                    },
                    icon: Icon(Icons.keyboard_arrow_right),
                  ),
                )
                : SizedBox(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: TextField(
                  onTap: () {
                    setState(() {
                      _isExpandedLeft = false;
                    });
                  },
                  focusNode: _focusNode,
                  controller: widget.textController,
                  style: TextStyle(
                    color: context.theme.textColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    filled: true,
                    fillColor: context.theme.grey,
                    hintText: "Nhắn tin",
                    hintStyle: TextStyle(color: context.theme.textColor),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 0,
                    ),
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                widget.onSendMessage?.call();
                _focusNode.requestFocus();
              },
              icon: Icon(
                widget.textController.text.isNotEmpty
                    ? Icons.send
                    : Icons.thumb_up_alt,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
//67e9058800157c0908e0
//67e905710032fd9a41b3
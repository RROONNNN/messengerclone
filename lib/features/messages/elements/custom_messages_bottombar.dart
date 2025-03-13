import 'package:flutter/material.dart';
import '../../../common/extensions/custom_theme_extension.dart';

class CustomMessagesBottomBar extends StatefulWidget {
  final TextEditingController? textController;
  const CustomMessagesBottomBar({super.key, this.textController});

  @override
  State<CustomMessagesBottomBar> createState() =>
      _CustomMessagesBottomBarState();
}

class _CustomMessagesBottomBarState extends State<CustomMessagesBottomBar> {
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
            IconButton(onPressed: () {}, icon: Icon(Icons.add_circle)),
            IconButton(onPressed: () {}, icon: Icon(Icons.camera_alt)),
            IconButton(onPressed: () {}, icon: Icon(Icons.image)),
            IconButton(onPressed: () {}, icon: Icon(Icons.mic)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: TextField(
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

            IconButton(onPressed: () {}, icon: Icon(Icons.thumb_up_alt)),
          ],
        ),
      ),
    );
  }
}

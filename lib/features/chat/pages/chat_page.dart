import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../messages/pages/messages_page.dart';
import '../../../common/extensions/custom_theme_extension.dart';
import '../../../common/widgets/custom_text_style.dart';
import '../../../common/widgets/elements/custom_grouped_list_title.dart';
import '../../../common/widgets/elements/custom_message_item.dart';
import '../../../common/widgets/elements/custom_round_avatar.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.bg,
      appBar: AppBar(
        title: const TitleText("Chat Page"),
        backgroundColor: context.theme.appBar,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => MessagesPage()),
                    );
                  },
                  child: Text("MessagesPage"),
                ),
                CustomRoundAvatar(isActive: true, radius: 25),
                CustomGroupedListTitle(
                  onTapFunc: () {},
                  isFirstTab: true,
                  child: ListTile(
                    iconColor: context.theme.textColor,
                    contentPadding: EdgeInsets.symmetric(horizontal: 10),
                    leading: FaIcon(FontAwesomeIcons.store, size: 19),
                    title: ContentText("Marketplace"),
                    trailing: Icon(Icons.keyboard_arrow_right),
                  ),
                ),
                _divider(),
                CustomGroupedListTitle(
                  onTapFunc: () {},
                  isMiddleTab: true,
                  child: ListTile(
                    iconColor: context.theme.textColor,
                    contentPadding: EdgeInsets.symmetric(horizontal: 10),
                    leading: Icon(Icons.chat_bubble, size: 19),
                    title: ContentText("Tin nhắn đang chờ"),
                    trailing: Icon(Icons.keyboard_arrow_right),
                  ),
                ),
                _divider(),
                CustomGroupedListTitle(
                  onTapFunc: () {},
                  isLastTab: true,
                  child: ListTile(
                    iconColor: context.theme.textColor,
                    contentPadding: EdgeInsets.symmetric(horizontal: 10),
                    leading: FaIcon(FontAwesomeIcons.box, size: 19),
                    title: ContentText("Kho lưu trữ"),
                    trailing: Icon(Icons.keyboard_arrow_right),
                  ),
                ),

                CustomMessageItem(
                  isTextMessage: true,
                  isMe: true,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ContentText(
                      "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s,  ",
                    ),
                  ),
                ),
                CustomMessageItem(
                  isImageMessage: true,
                  isMe: true,
                  child: Image.asset("assets/images/imagemaxwidth.png"),
                ),
                CustomMessageItem(
                  isImageMessage: true,
                  isMe: true,
                  child: Image.asset(
                    "assets/images/imagemaxheight.png",
                    fit: BoxFit.cover,
                  ),
                ),
                CustomMessageItem(
                  isMe: false,
                  isImageMessage: false,
                  child: IntrinsicWidth(
                    child: ListTile(
                      dense: true,
                      title: ContentText(
                        "Cuộc gọi video",
                        fontWeight: FontWeight.w700,
                      ),
                      subtitle: ContentText(
                        "13 giây",
                        color: context.theme.textGrey,
                      ),
                      leading: Icon(
                        Icons.video_call,
                        size: 30,
                        color: context.theme.textColor,
                      ),
                    ),
                  ),
                ),
                CustomMessageItem(
                  isMe: false,
                  isImageMessage: false,
                  child: IntrinsicWidth(
                    child: ListTile(
                      title: ContentText("Cuộc gọi video"),
                      subtitle: ContentText(
                        "13 giây",
                        color: context.theme.textGrey,
                      ),
                      leading: Icon(
                        Icons.video_call,
                        size: 30,
                        color: context.theme.textColor,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 25),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.only(left: 45),
      child: Divider(height: 0, thickness: 0.5, color: context.theme.grey),
    );
  }
}

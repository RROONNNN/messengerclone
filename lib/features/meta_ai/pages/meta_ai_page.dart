import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:messenger_clone/common/extensions/custom_theme_extension.dart';
import 'package:messenger_clone/common/widgets/custom_text_style.dart';

import '../../../common/widgets/elements/custom_grouped_list_title.dart';
import '../../../common/widgets/elements/custom_round_avatar.dart';

class MetaAiPage extends StatefulWidget {
  const MetaAiPage({super.key});

  @override
  State<MetaAiPage> createState() => _MetaAiPageState();
}

class _MetaAiPageState extends State<MetaAiPage> {
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
                ElevatedButton(onPressed: () {}, child: Text("MessagesPage")),
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

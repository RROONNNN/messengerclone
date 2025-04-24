import 'package:flutter/material.dart';

import '../elements/custom_messages_appbar.dart';
import '../elements/custom_messages_bottombar.dart';

class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomMessagesAppBar(
        isMe: true,
        user: FakeUser(
          name: "Nguyễn Minh Thuận",
          isActive: false,
          offlineDuration: Duration(minutes: 12),
        ),
      ),
      bottomNavigationBar: CustomMessagesBottomBar(),
      body: const Placeholder(),
    );
  }
}

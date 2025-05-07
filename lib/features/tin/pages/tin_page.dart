import 'package:flutter/material.dart';
import 'package:messenger_clone/common/extensions/custom_theme_extension.dart';
import 'package:messenger_clone/common/widgets/custom_text_style.dart';

import 'call_page.dart';

class TinPage extends StatelessWidget {
  const TinPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.bg,
      appBar: AppBar(
        title: const TitleText("Tin Page"),
        backgroundColor: context.theme.appBar,
      ),
      body: Center(child:
      ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CallPage(callID: '1234'),
            ),
          );
        }, child: const Text("Call",),)
      ),
    );
  }
}

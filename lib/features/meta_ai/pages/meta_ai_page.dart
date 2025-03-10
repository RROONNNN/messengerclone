import 'package:flutter/material.dart';
import 'package:messenger_clone/common/extensions/custom_theme_extension.dart';
import 'package:messenger_clone/common/widgets/custom_text_style.dart';

class MetaAiPage extends StatelessWidget {
  const MetaAiPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.bg,
      appBar: AppBar(
        title: const TitleText("MetaAi Page"),
        backgroundColor: context.theme.appBar,
      ),
      body: const Center(child: ContentText("MetaAi Page")),
    );
  }
}

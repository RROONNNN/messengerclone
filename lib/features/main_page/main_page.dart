
import 'package:flutter/material.dart';
import 'package:messenger_clone/features/chat/pages/chat_page.dart';
import 'package:messenger_clone/features/menu/pages/menu_page.dart';
import 'package:messenger_clone/features/meta_ai/pages/meta_ai_page.dart';
import 'package:messenger_clone/features/tin/pages/tin_page.dart';
import '../../common/extensions/custom_theme_extension.dart';
import '../../common/widgets/custom_text_style.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final PageStorageBucket bucket = PageStorageBucket();
  List<Widget> dashBoardScreens = [
    const ChatPage(),
    const MetaAiPage(),
     TinPage(),
    const MenuPage(),
  ];
  int currentPage = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.bg,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: PageStorage(
        bucket: bucket,
        child: IndexedStack(index: currentPage, children: dashBoardScreens),
      ),
      bottomNavigationBar: Container(
        width: MediaQuery.of(context).size.width,
        height: 45 + 28,
        padding: const EdgeInsets.only(top: 8, bottom: 20, left: 5, right: 5),
        decoration: BoxDecoration(
          color: context.theme.bottomNav,
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, -1),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            bottomItem(context, 0, Icons.chat_bubble, "Đoạn chat"),
            bottomItem(context, 1, Icons.donut_large, "Meta AI"),
            bottomItem(context, 2, Icons.view_agenda, "Tin"),
            bottomItem(context, 3, Icons.menu, "Menu"),
          ],
        ),
      ),
    );
  }

  Widget bottomItem(
    BuildContext context,
    int itemIndex,
    IconData icon,
    String title,
  ) {
    Color color =
        currentPage != itemIndex ? context.theme.textColor : context.theme.blue;
    return SizedBox(
      child: InkWell(
        onTap: () {
          setState(() {
            currentPage = itemIndex;
          });
        },
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            ContentText(title, fontSize: 12, color: color),
          ],
        ),
      ),
    );
  }
}

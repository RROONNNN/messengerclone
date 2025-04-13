import 'package:flutter/material.dart';
import 'package:messenger_clone/common/extensions/custom_theme_extension.dart';
import 'package:messenger_clone/common/widgets/elements/custom_round_avatar.dart';
import 'package:messenger_clone/features/messages/pages/messages_page.dart';

import '../model/chat_item.dart';
import '../widgets/chat_item_widget.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final List<ChatItem> chatItems = [
    ChatItem(
      title: 'Mobile',
      subtitle: 'https://docs.google.codsfsfsfsfdsfsfdsfdsfdsfdfds',
      time: '12:28',
      avatar: 'https://picsum.photos/50?random=${'Mobile'.hashCode}'
    ),
    ChatItem(
      title: 'Văn Nguyên',
      subtitle: '1 tiếng 1 nuôi à',
      time: '22:57',
      hasUnread: true,
        avatar: 'https://picsum.photos/50?random=${'Văn Nguyên'.hashCode}'
    ),
    ChatItem(
      title: 'Anh Em Cây Khế',
      subtitle: 'Thuận: Dứt xíu về hè duyet duyet dsfsdfsd',
      time: '21:04',
      avatar: 'https://picsum.photos/50?random=${'Anh Em Cây Khế'.hashCode}'
    ),
    ChatItem(
      title: 'Rôn sui sèo',
      subtitle: 'Định vô ngồi mà con nó giành lọ',
      time: 'Th 6',
        hasUnread: true,
      avatar: 'https://picsum.photos/50?random=${'Rôn sui sèo'.hashCode}'
    ),
    ChatItem(
      title: 'Hạ Cuối',
      subtitle: 'Duyệt',
      time: 'Th 6',
      avatar: 'https://picsum.photos/50?random=${'Hạ Cuối'.hashCode}'
    ),
    ChatItem(
        title: 'Hạ Cuối',
        subtitle: 'Duyệt',
        time: 'Th 6',
        avatar: 'https://picsum.photos/50?random=${'Hạ Cuối'.hashCode}'
    ),
    ChatItem(
        title: 'Hạ Cuối',
        subtitle: 'Duyệt',
        time: 'Th 6',
        avatar: 'https://picsum.photos/50?random=${'Hạ Cuối'.hashCode}'
    ),
    ChatItem(
        title: 'Hạ Cuối',
        subtitle: 'Duyệt',
        time: 'Th 6',
        avatar: 'https://picsum.photos/50?random=${'Hạ Cuối'.hashCode}'
    ),
    ChatItem(
        title: 'Hạ Cuối',
        subtitle: 'Duyệt',
        time: 'Th 6',
        avatar: 'https://picsum.photos/50?random=${'Hạ Cuối'.hashCode}'
    ),
    ChatItem(
        title: 'Hạ Cuối',
        subtitle: 'Duyệt',
        time: 'Th 6',
        avatar: 'https://picsum.photos/50?random=${'Hạ Cuối'.hashCode}'
    ),
  ];
  final List<String> friends  = ['Tôi', 'Hiển', 'Tâm', 'Tuấn' , 'Nhật Băng', 'Hiển', 'Tâm', 'Tuấn' , 'Nhật Băng', 'Hiển', 'Tâm', 'Tuấn' ] ;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              'messenger',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: context.theme.titleHeaderColor,
              ),
            ),
            SizedBox(width: 8),
            Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: context.theme.titleHeaderColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline,
                size: 20,
                color: Colors.blueAccent,
              ),
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: context.theme.bg,
        actions: [
          IconButton(
            icon: Icon(Icons.account_tree_outlined, color: context.theme.textColor.withOpacity(0.7)),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.facebook,
                color: context.theme.textColor.withOpacity(0.7)),
            onPressed: () {},
          ),
        ],
      ),
      backgroundColor: context.theme.bg,
      body: ListView(
        children: [
          _buildHeader(),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: chatItems.length,
            itemBuilder: (context, index) {
              final item = chatItems[index];
              return Column(
                children: [
                  ChatItemWidget(
                    item: item,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => MessagesPage()),
                      );
                    },
                    onLongPress: (item) {
                      _showChatOptionsBottomSheet(context, item);
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: Container(
            decoration: BoxDecoration(
              color: context.theme.grey,
              borderRadius: BorderRadius.circular(20.0),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Row(
              children: [
                Icon(Icons.search, color: context.theme.textColor.withOpacity(0.5), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search',
                      hintStyle: TextStyle(
                        color: context.theme.textColor.withOpacity(0.5),
                        fontSize: 16.0,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    style: TextStyle(
                      color: context.theme.textColor,
                      fontSize: 16.0,
                    ),
                  ),
                ),
                Icon(Icons.qr_code, color: context.theme.textColor.withOpacity(0.5), size: 20),
              ],
            ),
          ),
        ),
        SizedBox(
          height: 100,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children:  friends.map((name) => Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 8.0),
                child: GestureDetector(
                  onTap: (){
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => MessagesPage()),
                    );
                  },
                  onLongPress: (){
                    debugPrint("LongPress");
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                     CustomRoundAvatar(
                          radius: 35,
                          isActive: true,
                          avatarImage: NetworkImage('https://picsum.photos/50?random=${name.hashCode}'),
                     ),
                      const SizedBox(height: 4),
                      Text(
                          name ,
                          style: TextStyle(
                            color: context.theme.textColor,
                          ),
                      ),
                    ],
                  ),
                ),
              ))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }
  void _showChatOptionsBottomSheet(BuildContext context, ChatItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: context.theme.appBar,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                height: 6,
                width: 50,
                color: Colors.grey,
              ),

              ListTile(
                leading:  Icon(Icons.archive , color: context.theme.textColor,),
                title: Text('Lưu trữ'  , style: TextStyle(color: context.theme.textColor),),
                onTap: () {
                  Navigator.pop(context);
                },
              ),

              ListTile(
                leading: Icon(Icons.person_add , color: context.theme.textColor,),
                title: Text('Thêm thành viên' , style: TextStyle(color: context.theme.textColor),),
                onTap: () {
                  Navigator.pop(context);
                },
              ),

              ListTile(
                leading:  Icon(Icons.notifications_off , color: context.theme.textColor,),
                title:  Text('Tắt thông báo' , style: TextStyle(color: context.theme.textColor),),
                onTap: () {
                  Navigator.pop(context);
                },
              ),

              ListTile(
                leading:  Icon(Icons.markunread , color: context.theme.textColor,),
                title:  Text('Đánh dấu là chưa đọc' , style: TextStyle(color: context.theme.textColor),),
                onTap: () {
                  Navigator.pop(context);
                },
              ),

              ListTile(
                leading:  Icon(Icons.exit_to_app , color: context.theme.textColor,),
                title:  Text('Rời nhóm' , style: TextStyle(color: context.theme.textColor),),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading:  Icon(Icons.delete, color: context.theme.red),
                title:  Text('Xóa', style: TextStyle(color: context.theme.red)),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
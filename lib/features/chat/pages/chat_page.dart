import 'package:flutter/material.dart';
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
      subtitle: 'https://docs.google.co...',
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
      subtitle: 'Thuận: Dứt xíu về hè lọ',
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
                color: Colors.blue,
              ),
            ),
            SizedBox(width: 8),
            Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.2),
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
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.account_tree_outlined, color: Colors.black.withOpacity(0.7)),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.facebook,
                color: Colors.black.withOpacity(0.7)),
            onPressed: () {},
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Container(
            color: Colors.grey[300],
            height: 1,
          ),
        ),
      ),
      backgroundColor: Colors.white,
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
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(20.0),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.grey, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm',
                      hintStyle: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16.0,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16.0,
                    ),
                  ),
                ),
                const Icon(Icons.qr_code, color: Colors.grey, size: 20),
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
                    _showContextMenu(context);
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
                      Text(name),
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
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const Divider(height: 1),

              ListTile(
                leading: const Icon(Icons.archive),
                title: const Text('Lưu trữ'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),

              ListTile(
                leading: const Icon(Icons.person_add),
                title: const Text('Thêm thành viên'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),

              ListTile(
                leading: const Icon(Icons.notifications_off),
                title: const Text('Tắt thông báo'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),

              ListTile(
                leading: const Icon(Icons.markunread),
                title: const Text('Đánh dấu là chưa đọc'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),

              ListTile(
                leading: const Icon(Icons.exit_to_app),
                title: const Text('Rời nhóm'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),

              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Xóa', style: TextStyle(color: Colors.red)),
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
  void _showContextMenu(BuildContext context) {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final RenderBox tile = context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        tile.localToGlobal(Offset.zero, ancestor: overlay),
        tile.localToGlobal(tile.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    showMenu(
      context: context,
      position: position,
      items: [
        PopupMenuItem(
          child: const Text('Xem trang cá nhân'),
          onTap: () {
          },
        ),
        PopupMenuItem(
          child: const Text('Ẩn người liên he'),
          onTap: () {
          },
        ),
      ],
    );
  }
}
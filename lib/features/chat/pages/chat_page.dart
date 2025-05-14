import 'dart:async';

import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:messenger_clone/common/extensions/custom_theme_extension.dart';
import 'package:messenger_clone/common/routes/routes.dart';
import 'package:messenger_clone/common/services/app_write_config.dart';
import 'package:messenger_clone/common/services/chat_stream_manager.dart';
import 'package:messenger_clone/common/services/hive_service.dart';
import 'package:messenger_clone/common/widgets/elements/custom_round_avatar.dart';
import 'package:messenger_clone/features/chat/bloc/chat_item_bloc.dart';
import 'package:messenger_clone/features/chat/data/data_sources/remote/appwrite_repository.dart';
import 'package:messenger_clone/features/chat/model/group_message.dart';
import 'package:messenger_clone/features/chat/pages/searching_page.dart';

import '../model/chat_item.dart';
import '../widgets/chat_item_widget.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  String? currentUserId;
  late final AppwriteRepository appwriteRepository;
  late final ChatStreamManager _chatStreamManager;
  final List<String> friends = [
    'Tôi',
    'Hiển',
    'Tâm',
    'Tuấn',
    'Nhật Băng',
    'Hiển',
    'Tâm',
    'Tuấn',
    'Nhật Băng',
    'Hiển',
    'Tâm',
    'Tuấn',
  ];
  bool isGetItemAgain = false;
  @override
  void initState() {
    super.initState();
    appwriteRepository = AppwriteRepository();

    _chatStreamManager = ChatStreamManager(
      onMessageReceived: _handleRealtimeMessage,
      onError: (error) {
        debugPrint('Error in realtime stream: $error');
      },
    );
    _initializeChatItems();
    debugPrint("ChatPage initialized");
  }

  Future<void> _initializeChatItems() async {
    currentUserId = await HiveService().getCurrentUserId();
    setState(() {});
    if (currentUserId != null) {
      BlocProvider.of<ChatItemBloc>(
        context,
      ).add(GetChatItemEvent(userid: currentUserId!));
      final groupMessages = await appwriteRepository.getGroupMessagesByUserId(
        currentUserId!,
      );
      final groupIds = groupMessages.map((gm) => gm.groupMessagesId).toList();
      await _chatStreamManager.initialize(currentUserId!, groupIds);
    }
  }

  void _handleRealtimeMessage(RealtimeMessage message) {
    debugPrint('Received update: ${message.events}');
    if (currentUserId == null) return;
    if (message.events.any(
      (event) =>
          event.contains('collections.${AppwriteConfig.userCollectionId}') &&
          event.contains(currentUserId!),
    )) {
      _getChatItemAgain();
    } else if (message.events.any(
      (event) => event.contains(
        'collections.${AppwriteConfig.groupMessagesCollectionId}',
      ),
    )) {
      _refreshChatItems(message.payload);
    }
  }

  void _getChatItemAgain() {
    if (mounted && currentUserId != null) {
      isGetItemAgain = true;
      BlocProvider.of<ChatItemBloc>(
        context,
      ).add(GetChatItemEvent(userid: currentUserId!));
    }
  }

  void _refreshChatItems(Map<String, dynamic> groupMessagePayload) async {
    if (mounted && currentUserId != null) {
      final groupId = groupMessagePayload['\$id'] as String;

      BlocProvider.of<ChatItemBloc>(
        context,
      ).add(UpdateChatItemEvent(groupChatId: groupId));
    }
  }

  @override
  void dispose() {
    _chatStreamManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (currentUserId == null) {
      return const Center(child: CircularProgressIndicator());
    }
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
            icon: Icon(
              Icons.account_tree_outlined,
              color: context.theme.textColor.withOpacity(0.7),
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(
              Icons.facebook,
              color: context.theme.textColor.withOpacity(0.7),
            ),
            onPressed: () {},
          ),
        ],
      ),
      backgroundColor: context.theme.bg,
      body: ListView(
        children: [
          _buildHeader(),
          BlocBuilder<ChatItemBloc, ChatItemState>(
            builder: (context, state) {
              if (state is ChatItemLoading) {
                return Center(child: CircularProgressIndicator());
              } else if (state is ChatItemError) {
                return Center(child: Text("Error loading chat items"));
              }
              if (isGetItemAgain) {
                isGetItemAgain = false;
                for (GroupMessage groupMessage
                    in (state as ChatItemLoaded).groupMessages) {
                  if (!_chatStreamManager.isSubscribedToGroup(
                    groupMessage.groupMessagesId,
                  )) {
                    _chatStreamManager.addGroupMessage(
                      currentUserId!,
                      groupMessage.groupMessagesId,
                    );
                  }
                }
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: (state as ChatItemLoaded).chatItems.length,
                itemBuilder: (context, index) {
                  final item = state.chatItems[index];
                  return Column(
                    children: [
                      ChatItemWidget(
                        item: item,
                        onTap: () {
                          Navigator.of(context).pushNamed(
                            Routes.chat,
                            arguments: item.groupMessage,
                          );
                        },
                        onLongPress: (item) {
                          _showChatOptionsBottomSheet(context, item);
                        },
                      ),
                    ],
                  );
                },
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
            padding: const EdgeInsets.symmetric(
              horizontal: 10.0,
              vertical: 4.0,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search,
                  color: context.theme.textColor.withOpacity(0.5),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const SearchingPage(),
                        ),
                      );
                    },
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 0,
                      ),
                      hintText: 'Search',
                      hintStyle: TextStyle(
                        color: context.theme.textColor.withOpacity(0.5),
                        fontSize: 16.0,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    style: TextStyle(
                      color: context.theme.textColor,
                      fontSize: 16.0,
                    ),
                  ),
                ),
                Icon(
                  Icons.qr_code,
                  color: context.theme.textColor.withOpacity(0.5),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        SizedBox(
          height: 100,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children:
                  friends
                      .map(
                        (name) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: GestureDetector(
                            onTap: () {
                              // Navigator.of(context).push(
                              //   MaterialPageRoute(
                              //     builder: (context) => MessagesPage(),
                              //   ),
                              // );
                            },
                            onLongPress: () {
                              debugPrint("LongPress");
                            },
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CustomRoundAvatar(
                                  radius: 35,
                                  isActive: true,
                                  avatarUrl:
                                      'https://picsum.photos/50?random=${name.hashCode}',
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  name,
                                  style: TextStyle(
                                    color: context.theme.textColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
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
                leading: Icon(Icons.archive, color: context.theme.textColor),
                title: Text(
                  'Lưu trữ',
                  style: TextStyle(color: context.theme.textColor),
                ),
                onTap: () {
                  Navigator.pop(context);
                },
              ),

              ListTile(
                leading: Icon(Icons.person_add, color: context.theme.textColor),
                title: Text(
                  'Thêm thành viên',
                  style: TextStyle(color: context.theme.textColor),
                ),
                onTap: () {
                  Navigator.pop(context);
                },
              ),

              ListTile(
                leading: Icon(
                  Icons.notifications_off,
                  color: context.theme.textColor,
                ),
                title: Text(
                  'Tắt thông báo',
                  style: TextStyle(color: context.theme.textColor),
                ),
                onTap: () {
                  Navigator.pop(context);
                },
              ),

              ListTile(
                leading: Icon(Icons.markunread, color: context.theme.textColor),
                title: Text(
                  'Đánh dấu là chưa đọc',
                  style: TextStyle(color: context.theme.textColor),
                ),
                onTap: () {
                  Navigator.pop(context);
                },
              ),

              ListTile(
                leading: Icon(
                  Icons.exit_to_app,
                  color: context.theme.textColor,
                ),
                title: Text(
                  'Rời nhóm',
                  style: TextStyle(color: context.theme.textColor),
                ),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete, color: context.theme.red),
                title: Text('Xóa', style: TextStyle(color: context.theme.red)),
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

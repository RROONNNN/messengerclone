import 'dart:async';

import 'package:appwrite/appwrite.dart';

import 'package:flutter/material.dart';
import 'package:messenger_clone/common/constants/appwrite_database_constants.dart';
import 'package:messenger_clone/common/extensions/custom_theme_extension.dart';
import 'package:messenger_clone/common/services/common_function.dart';

import 'package:messenger_clone/common/services/hive_service.dart';
import 'package:messenger_clone/common/widgets/custom_text_style.dart';
import 'package:messenger_clone/common/widgets/elements/custom_message_item.dart';
import 'package:messenger_clone/common/widgets/elements/custom_round_avatar.dart';
import 'package:messenger_clone/features/chat/model/group_message.dart';
import 'package:messenger_clone/features/chat/model/user.dart';
import 'package:messenger_clone/features/messages/data/repositories/chat_repository_impl.dart';
import 'package:messenger_clone/features/messages/domain/models/message_model.dart';
import 'package:messenger_clone/features/messages/message_type.dart';

import '../elements/custom_messages_appbar.dart';
import '../elements/custom_messages_bottombar.dart';

class MessagesPage extends StatefulWidget {
  final GroupMessage? groupMessage;
  final List<User>? otherUsers;
  const MessagesPage({super.key, this.groupMessage, this.otherUsers})
    : assert(
        (groupMessage == null) != (otherUsers == null),
        'Either groupMessage or otherUsers must be provided, but not both.',
      );

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  List<MessageModel> messages = [];
  Stream<RealtimeMessage>? chatStream;
  late final TextEditingController textEditingController;
  late final ChatRepositoryImpl chatRepository;
  String? me;
  late final ScrollController _scrollController;
  StreamSubscription<RealtimeMessage>? _chatStreamSubscription;
  final int _limit = 20;
  int _offset = 0;
  bool isLoadingMore = false;
  bool isLoading = true;
  late final List<User> others;
  late final GroupMessage groupMessage;

  Future<void> _getMessages() async {
    final result = await chatRepository.getMessages(
      groupMessage.groupMessagesId,
      _limit,
      _offset,
    );
    result.fold((error) => [], (messages) {
      if (messages.isNotEmpty) {
        _subcribeToChatStream();
      }
      setState(() {
        this.messages = messages;
      });
    });
  }

  Future<void> _loadMoreMessages() async {
    chatRepository
        .getMessages(groupMessage.groupMessagesId, _limit, _offset)
        .then((value) {
          return value.fold((error) => [], (newMessages) {
            setState(() {
              messages.addAll(newMessages);

              isLoadingMore = false;
            });
          });
        });
  }

  void _init_async() async {
    me = await HiveService.instance.getCurrentUserId();
    if (me == null || me!.isEmpty) {
      debugPrint('User ID is empty. Please log in.');
      return;
    }
    if (widget.groupMessage == null) {
      others = widget.otherUsers!
          .where((user) => user.id != me)
          .toList(growable: false);

      final groupId = CommonFunction.generateGroupId([
        ...widget.otherUsers!.map((user) => user.id).toList(),
        me!,
      ]);
      final GroupMessage? getGroup = await chatRepository
          .getGroupMessagesByGroupId(groupId);
      if (getGroup != null) {
        debugPrint('Group message already exists.');
        groupMessage = getGroup;
      } else {
        final result = await chatRepository.createGroupMessages(
          userIds: [...widget.otherUsers!.map((user) => user.id).toList(), me!],
          groupId: groupId,
        );
        result.fold(
          (error) => debugPrint('Error creating group message: $error'),
          (group) => groupMessage = group,
        );
      }
    } else {
      groupMessage = widget.groupMessage!;
      others = groupMessage.users.where((user) => user.id != me).toList();
    }
    await _getMessages();
    setState(() {
      isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    textEditingController = TextEditingController();
    chatRepository = ChatRepositoryImpl();

    _init_async();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.offset >=
            _scrollController.position.maxScrollExtent &&
        !_scrollController.position.outOfRange &&
        (_offset + _limit) <= messages.length &&
        !isLoadingMore) {
      debugPrint('Loading more messages...');
      setState(() {
        isLoadingMore = true;
      });
      _offset = messages.length;
      _loadMoreMessages().then((_) {
        setState(() {
          isLoadingMore = false;
        });
      });
    }
  }

  void _subcribeToChatStream() {
    chatRepository.getChatStream(groupMessage.groupMessagesId).then((response) {
      response.fold((error) => debugPrint('Error: $error'), (stream) {
        chatStream = stream;
        _chatStreamSubscription = chatStream!.listen(
          (event) {
            debugPrint('Received event: ${event.events}');
            final payload = event.payload;
            debugPrint(
              'type of payload: ${payload[AppwriteDatabaseConstants.lastMessage].runtimeType}',
            );
            final MessageModel newMessage = MessageModel.fromMap(
              payload[AppwriteDatabaseConstants.lastMessage],
            );
            if (newMessage.idFrom != me) {
              setState(() {
                messages.insert(0, newMessage);
              });
            }
          },
          onError: (error) {
            debugPrint('Error in chat stream: $error');
          },
        );
      });
    });
  }

  @override
  void dispose() {
    _chatStreamSubscription?.cancel();
    chatStream?.drain();
    textEditingController.dispose();
    _scrollController
      ..removeListener(_scrollListener)
      ..dispose();
    super.dispose();
  }

  void _onSendMessage() {
    final message = textEditingController.text.trim();
    if (message.isEmpty) return;
    setState(() {
      final newMessage = MessageModel(
        idFrom: me!,
        content: message,
        type: "text",
        groupMessagesId: groupMessage.groupMessagesId,
      );
      messages.insert(0, newMessage);
      chatRepository
          .sendMessage(
            newMessage,
            CommonFunction.getOthersId(groupMessage.users, me!),
          )
          .then((value) {
            value.fold(
              (error) => debugPrint('Error sending message: $error'),
              (success) => debugPrint('Message sent successfully'),
            );
          });
      textEditingController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: CustomMessagesAppBar(isMe: true, user: others.first),
        bottomNavigationBar: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: CustomMessagesBottomBar(
            onSendMessage: () {
              _onSendMessage();
            },
            textController: textEditingController,
          ),
        ),
        body: SafeArea(
          child: Container(
            color: context.theme.bg,
            padding: EdgeInsets.symmetric(horizontal: 5),
            child:
                messages.length > 0
                    ? _buildListMessage()
                    : Container(height: double.infinity),
          ),
        ),
      ),
    );
  }

  Widget _buildListMessage() {
    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      itemBuilder: (context, index) {
        if (index == messages.length) {
          return isLoadingMore
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                ),
              )
              : SizedBox.shrink();
        }
        final message = messages[index];
        return Row(
          mainAxisAlignment:
              message.idFrom == me
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
          children: [
            message.idFrom == me
                ? const SizedBox()
                : CustomRoundAvatar(
                  isActive: true,
                  radius: 18,
                  radiusOfActiveIndicator: 5,
                ),
            CustomMessageItem(
              isTextMessage: message.type == MessageType.text,
              isMe: message.idFrom == me,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: ContentText(message.content),
              ),
            ),
          ],
        );
      },
      itemCount: messages.length + 1,
    );
  }
}

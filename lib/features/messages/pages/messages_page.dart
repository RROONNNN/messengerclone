import 'dart:async';

import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:messenger_clone/common/constants/appwrite_database_constants.dart';
import 'package:messenger_clone/common/extensions/custom_theme_extension.dart';
import 'package:messenger_clone/common/services/common_function.dart';
import 'package:messenger_clone/common/widgets/custom_text_style.dart';
import 'package:messenger_clone/common/widgets/elements/custom_message_item.dart';
import 'package:messenger_clone/common/widgets/elements/custom_round_avatar.dart';
import 'package:messenger_clone/features/messages/data/repositories/chat_repository_impl.dart';
import 'package:messenger_clone/features/messages/domain/models/message_model.dart';
import 'package:messenger_clone/features/messages/message_type.dart';

import '../elements/custom_messages_appbar.dart';
import '../elements/custom_messages_bottombar.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  List<MessageModel> messages = [];
  late final Stream<RealtimeMessage> chatStream;
  late final TextEditingController textEditingController;
  late final ChatRepositoryImpl chatRepository;
  static const String me = "67e9058800157c0908e0";
  static const String other = "67e905710032fd9a41b3";
  late final ScrollController _scrollController;
  late StreamSubscription<RealtimeMessage> _chatStreamSubscription;
  final int _limit = 20;
  int _offset = 0;
  bool isLoadingMore = false;

  void _getMessages() {
    chatRepository
        .getMessages(CommonFunction.getGroupChatId(me, other), _limit, _offset)
        .then((value) {
          return value.fold((error) => [], (messages) {
            setState(() {
              this.messages = messages;
            });
          });
        });
  }

  Future<void> _loadMoreMessages() async {
    chatRepository
        .getMessages(CommonFunction.getGroupChatId(me, other), _limit, _offset)
        .then((value) {
          return value.fold((error) => [], (newMessages) {
            setState(() {
              messages.addAll(newMessages);
              isLoadingMore = false;
            });
          });
        });
  }

  @override
  void initState() {
    super.initState();

    textEditingController = TextEditingController();
    chatRepository = ChatRepositoryImpl();
    _getMessages();
    chatRepository.getChatStream(CommonFunction.getGroupChatId(me, other)).then((
      response,
    ) {
      response.fold((error) => debugPrint('Error: $error'), (stream) {
        chatStream = stream;
        _chatStreamSubscription = chatStream.listen(
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

  @override
  void dispose() {
    _chatStreamSubscription.cancel();
    chatStream.drain();
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
        idFrom: me,
        idTo: other,
        timestamp: DateTime.now().toString(),
        content: message,
        type: "text",
      );
      messages.insert(0, newMessage);
      chatRepository.sendMessage(newMessage).then((value) {
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
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: CustomMessagesAppBar(
          isMe: true,
          user: FakeUser(
            name: "Nguyễn Minh Thuận",
            isActive: false,
            offlineDuration: Duration(minutes: 12),
          ),
        ),
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
                messages.length > 0 ? _buildListMessage() : SizedBox(height: 0),
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

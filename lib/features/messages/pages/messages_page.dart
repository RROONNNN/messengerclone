import 'dart:async';

import 'package:appwrite/appwrite.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:messenger_clone/common/extensions/custom_theme_extension.dart';

import 'package:messenger_clone/common/widgets/custom_text_style.dart';
import 'package:messenger_clone/common/widgets/elements/custom_message_item.dart';
import 'package:messenger_clone/common/widgets/elements/custom_round_avatar.dart';
import 'package:messenger_clone/features/chat/model/group_message.dart';
import 'package:messenger_clone/features/chat/model/user.dart';
import 'package:messenger_clone/features/messages/bloc/message_bloc.dart';
import 'package:messenger_clone/features/messages/data/repositories/chat_repository_impl.dart';
import 'package:messenger_clone/features/messages/enum/message_status.dart';
import '../elements/custom_messages_appbar.dart';
import '../elements/custom_messages_bottombar.dart';

class MessagesPage extends StatefulWidget {
  final GroupMessage? groupMessage;
  final User? otherUser;
  const MessagesPage({super.key, this.groupMessage, this.otherUser})
    : assert(
        (groupMessage == null) != (otherUser == null),
        'Either groupMessage or otherUsers must be provided, but not both.',
      );

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  Stream<RealtimeMessage>? chatStream;
  Stream<RealtimeMessage>? messageStream;
  late final TextEditingController textEditingController;
  late final ChatRepositoryImpl chatRepository;
  late final ScrollController _scrollController;
  late MessageBloc _messageBloc;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    debugPrint('didChangeDependencies MessagesPage called');
    _messageBloc = BlocProvider.of<MessageBloc>(context);
  }

  @override
  void initState() {
    super.initState();
    textEditingController = TextEditingController();
    chatRepository = ChatRepositoryImpl();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (!_scrollController.hasClients) return;
    final currentState = context.read<MessageBloc>();
    if (currentState is! MessageLoaded) {
      return;
    }
    final bool hasMoreMessages =
        (currentState as MessageLoaded).hasMoreMessages;

    if (_scrollController.offset >=
            _scrollController.position.maxScrollExtent &&
        !_scrollController.position.outOfRange &&
        (hasMoreMessages)) {
      context.read<MessageBloc>().add(MessageLoadMoreEvent());
    }
  }

  @override
  void dispose() {
    textEditingController.dispose();
    _scrollController
      ..removeListener(_scrollListener)
      ..dispose();
    if (mounted) {
      _messageBloc.add(UnsubscribeFromChatStreamEvent());
      _messageBloc.add(ClearMessageEvent());
    }
    super.dispose();
  }

  void _onSendMessage() {
    final message = textEditingController.text.trim();
    if (message.isEmpty) return;
    context.read<MessageBloc>().add(MessageSendEvent(message));
    textEditingController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MessageBloc, MessageState>(
      listenWhen:
          (previous, current) =>
              current is MessageLoaded && previous != current,
      listener: (context, state) {
        if (state is MessageLoaded) {
          final bloc = context.read<MessageBloc>();
          bloc.add(SubscribeToChatStreamEvent());
          bloc.add(SubscribeToMessagesEvent());
        }
      },
      child: BlocBuilder<MessageBloc, MessageState>(
        builder: (context, state) {
          if (state is MessageLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is MessageError) {
            return Center(
              child: HeadlineText(state.error, color: context.theme.red),
            );
          } else if (state is MessageLoaded) {
            return GestureDetector(
              onTap: () {
                FocusScope.of(context).unfocus();
              },
              child: Scaffold(
                appBar: CustomMessagesAppBar(
                  isMe: true,
                  user: state.others.first,
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
                        state.messages.isNotEmpty
                            ? _buildListMessage()
                            : Container(height: double.infinity),
                  ),
                ),
              ),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildListMessage() {
    return BlocBuilder<MessageBloc, MessageState>(
      builder: (context, state) {
        if (state is MessageLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is MessageError) {
          return Center(
            child: HeadlineText(state.error, color: context.theme.red),
          );
        } else if (state is MessageLoaded) {
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child:
                                (state.messages.firstOrNull != null &&
                                        state.messages.first.idFrom ==
                                            state.meId)
                                    ? switch (state.messages.first.status) {
                                      MessageStatus.seen => const ContentText(
                                        'Seen',
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                      MessageStatus.sending =>
                                        const ContentText(
                                          'Sending',
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      null => const SizedBox(),
                                      MessageStatus.failed => const ContentText(
                                        'Failed',
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                      MessageStatus.sent => const ContentText(
                                        'Sent',
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    }
                                    : const SizedBox(),
                          ),
                        ],
                      );
                    }
                    if (index == state.messages.length) {
                      final bool isLoadingMore = state.isLoadingMore;
                      return (isLoadingMore)
                          ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(),
                            ),
                          )
                          : SizedBox.shrink();
                    }
                    final message = state.messages[index];
                    return Row(
                      mainAxisAlignment:
                          message.idFrom == state.meId
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                      children: [
                        message.idFrom == state.meId
                            ? const SizedBox()
                            : CustomRoundAvatar(
                              isActive: true,
                              radius: 18,
                              radiusOfActiveIndicator: 5,
                            ),
                        BlocProvider.value(
                          value: BlocProvider.of<MessageBloc>(context),
                          child: CustomMessageItem(
                            message: message,
                            isMe: message.idFrom == state.meId,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: ContentText(message.content),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                  itemCount: state.messages.length + 1,
                ),
              ),
            ],
          );
        }
        return const SizedBox();
      },
    );
  }
}

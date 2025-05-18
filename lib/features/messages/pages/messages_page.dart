import 'dart:async';
import 'package:appwrite/appwrite.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:messenger_clone/common/extensions/custom_theme_extension.dart';
import 'package:messenger_clone/common/services/user_service.dart';
import 'package:messenger_clone/common/widgets/custom_text_style.dart';
import 'package:messenger_clone/common/widgets/elements/custom_message_item.dart';
import 'package:messenger_clone/common/widgets/elements/custom_round_avatar.dart';
import 'package:messenger_clone/features/chat/model/group_message.dart';
import 'package:messenger_clone/features/chat/model/user.dart';
import 'package:messenger_clone/features/messages/bloc/message_bloc.dart';
import 'package:messenger_clone/features/messages/data/repositories/chat_repository_impl.dart';
import 'package:messenger_clone/features/messages/enum/message_status.dart';
import 'package:messenger_clone/features/messages/elements/call_page.dart';
import '../../../common/services/call_service.dart';
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
    if (currentState.state is! MessageLoaded) {
      return;
    }
    final bool hasMoreMessages =
        (currentState.state as MessageLoaded).hasMoreMessages;

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
      _messageBloc.close();
    }
    super.dispose();
  }

  void _onSendMessage() {
    final message = textEditingController.text.trim();
    if (message.isEmpty) return;
    context.read<MessageBloc>().add(MessageSendEvent(message));
    textEditingController.clear();
  }

  void _onSendMediaMessage(XFile media) {
    context.read<MessageBloc>().add(MessageSendEvent(media));
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
                  callFunc: () async {
                    final String userName =
                        await UserService.getNameUser(state.meId) as String;
                    if (state.meId.isEmpty || state.others.isEmpty) {
                      debugPrint('Lỗi: meId hoặc others rỗng');
                      return;
                    }
                    List<String> participants = [state.meId];
                    for (User user in state.others) {
                      if (user.id.isNotEmpty) {
                        participants.add(user.id);
                      }
                    }
                    if (participants.length < 2) {
                      debugPrint('Lỗi: Không đủ participants để gọi');
                      return;
                    }
                    participants.sort();
                    String callID = "";
                    for (final participant in participants) {
                      callID += participant;
                      callID += "call_video_21211221133211412114214";
                    }
                    debugPrint(
                      'Gửi thông báo gọi với callID: $callID, participants: $participants',
                    );
                    try {
                      await CallService.sendMessage(
                        userIds: participants,
                        callId: callID,
                        callerName: userName,
                        callerId: state.meId,
                      );
                      debugPrint('Điều hướng đến CallPage');
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => CallPage(
                                callID: callID,
                                userID: state.meId,
                                userName: userName,
                              ),
                        ),
                      );
                    } catch (e) {
                      debugPrint('Lỗi khi gửi thông báo gọi: $e');
                    }
                  },
                  videoCallFunc: () async {
                    if (state.meId.isEmpty || state.others.isEmpty) {
                      debugPrint('Lỗi: meId hoặc others rỗng');
                      return;
                    }
                    List<String> participants = [state.meId];
                    for (User user in state.others) {
                      if (user.id.isNotEmpty) {
                        participants.add(user.id);
                      }
                    }
                    if (participants.length < 2) {
                      debugPrint('Lỗi: Không đủ participants để gọi video');
                      return;
                    }
                    participants.sort();
                    String callID = "";
                    for (final participant in participants) {
                      callID += participant;
                      callID += "call_video_21211221133211412114214";
                    }
                    debugPrint(
                      'Gửi thông báo gọi video với callID: $callID, participants: $participants',
                    );
                    try {
                      await CallService.sendMessage(
                        userIds: participants,
                        callId: callID,
                        callerName: state.meId,
                        callerId: state.meId,
                      );
                      debugPrint('Điều hướng đến CallPage');
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => CallPage(
                                callID: callID,
                                userID: state.meId,
                                userName: state.meId,
                              ),
                        ),
                      );
                    } catch (e) {
                      debugPrint('Lỗi khi gửi thông báo gọi video: $e');
                    }
                  },
                ),
                bottomNavigationBar: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: CustomMessagesBottomBar(
                    onSendMessage: () {
                      _onSendMessage();
                    },
                    onSendMediaMessage: _onSendMediaMessage,
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
                    debugPrint('builder status');
                    if (index == 0) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (state.messages.first.usersSeen.isEmpty)
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child:
                                  (state.messages.first.idFrom == state.meId)
                                      ? switch (state.messages.first.status) {
                                        null => const ContentText(
                                          'Sent',
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                        MessageStatus.sending =>
                                          const ContentText(
                                            'Sending',
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        MessageStatus.failed =>
                                          const ContentText(
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
                            )
                          else
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ...state.messages.first.usersSeen
                                    .take(3)
                                    .where((user) => user.id != state.meId)
                                    .map(
                                      (user) => Padding(
                                        padding: const EdgeInsets.only(
                                          left: 4.0,
                                        ),
                                        child: Tooltip(
                                          message: user.name,
                                          child: CustomRoundAvatar(
                                            isActive: false,
                                            radius: 7,
                                            radiusOfActiveIndicator: 5,
                                            avatarUrl: user.photoUrl,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                if (state.messages.first.usersSeen.length > 3)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 4.0),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: ContentText(
                                        '+${state.messages.first.usersSeen.length - 3}',
                                        fontSize: 12,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                        ],
                      );
                    }
                    if (index == state.messages.length + 1) {
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
                    final message = state.messages[index - 1];
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
                              avatarUrl: message.sender.photoUrl,
                            ),
                        BlocProvider.value(
                          value: BlocProvider.of<MessageBloc>(context),
                          child: CustomMessageItem(
                            message: message,
                            isMe: message.idFrom == state.meId,
                          ),
                        ),
                      ],
                    );
                  },
                  itemCount: state.messages.length + 2,
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

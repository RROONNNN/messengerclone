import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:messenger_clone/common/services/hive_service.dart';
import 'package:messenger_clone/features/chat/data/data_sources/remote/appwrite_repository.dart';
import 'package:messenger_clone/features/chat/model/chat_item.dart';
import 'package:messenger_clone/features/chat/model/group_message.dart';
import 'package:messenger_clone/features/messages/message_type.dart';

part 'chat_item_event.dart';
part 'chat_item_state.dart';

class ChatItemBloc extends Bloc<ChatItemEvent, ChatItemState> {
  final AppwriteRepository appwriteRepository;
  Set<GroupMessage> groupMessages = {};
  ChatItemBloc({required this.appwriteRepository}) : super(ChatItemLoading()) {
    on<GetChatItemEvent>((event, emit) async {
      emit(ChatItemLoading());
      try {
        List<GroupMessage> groupMessagesList = await appwriteRepository
            .getGroupMessagesByUserId(event.userid);

        groupMessagesList.sort((a, b) {
          if (a.lastMessage == null && b.lastMessage == null) {
            return 0;
          } else if (a.lastMessage == null) {
            return 1;
          } else if (b.lastMessage == null) {
            return -1;
          } else {
            return b.lastMessage!.vietnamTime.compareTo(
              a.lastMessage!.vietnamTime,
            );
          }
        });
        groupMessages = groupMessagesList.toSet();
        List<ChatItem> chatItems = [];
        for (var groupMessage in groupMessages) {
          if (groupMessage.lastMessage == null) {
            continue;
          }
          if (groupMessage.lastMessage!.type == MessageType.text) {
            final isTheLatestMessSentByMe =
                groupMessage.lastMessage!.idFrom == event.userid;
            chatItems.add(
              // todo:
              ChatItem(
                groupMessage: groupMessage,
                hasUnread: (isTheLatestMessSentByMe) ? false : true,
              ),
            );
          } else {
            debugPrint(
              'Message type ${groupMessage.lastMessage!.type} not supported yet',
            );
          }
        }
        emit(ChatItemLoaded(chatItems: chatItems, groupMessages));
      } catch (error) {
        emit(ChatItemError(message: error.toString()));
      }
    });
    on<UpdateChatItemEvent>((event, emit) async {
      emit(ChatItemLoading());
      try {
        final GroupMessage groupMessage = await appwriteRepository
            .getGroupMessageById(event.groupChatId);
        groupMessages.removeWhere((message) => message == groupMessage);
        groupMessages.add(groupMessage);
        final sortedGroupMessages = groupMessages.toList();
        sortedGroupMessages.sort((a, b) {
          if (a.lastMessage == null && b.lastMessage == null) {
            return 0;
          } else if (a.lastMessage == null) {
            return 1;
          } else if (b.lastMessage == null) {
            return -1;
          } else {
            return b.lastMessage!.vietnamTime.compareTo(
              a.lastMessage!.vietnamTime,
            );
          }
        });
        groupMessages = sortedGroupMessages.toSet();
        final String currentUserId =
            await HiveService.instance.getCurrentUserId();
        List<ChatItem> chatItems = [];
        for (var groupMessage in groupMessages) {
          if (groupMessage.lastMessage == null) {
            continue;
          }
          if (groupMessage.lastMessage!.type == MessageType.text) {
            final isTheLatestMessSentByMe =
                groupMessage.lastMessage!.idFrom == currentUserId;
            chatItems.add(
              //todo:
              ChatItem(
                groupMessage: groupMessage,
                hasUnread: (isTheLatestMessSentByMe) ? false : true,
              ),
            );
          } else {
            debugPrint(
              'Message type ${groupMessage.lastMessage!.type} not supported yet',
            );
          }
        }
        emit(ChatItemLoaded(chatItems: chatItems, groupMessages));
      } catch (error) {
        emit(ChatItemError(message: error.toString()));
      }
    });
  }
}

import 'dart:async';

import 'package:appwrite/appwrite.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:messenger_clone/common/services/friend_service.dart';
import 'package:messenger_clone/common/services/hive_service.dart';
import 'package:messenger_clone/features/chat/data/data_sources/remote/appwrite_repository.dart';
import 'package:messenger_clone/features/chat/model/chat_item.dart';
import 'package:messenger_clone/features/chat/model/group_message.dart';
import 'package:messenger_clone/features/chat/model/user.dart';
import 'package:messenger_clone/features/messages/domain/models/message_model.dart';
import 'package:messenger_clone/common/services/app_write_config.dart';
import 'package:messenger_clone/common/services/auth_service.dart';

part 'chat_item_event.dart';
part 'chat_item_state.dart';

class ChatItemBloc extends Bloc<ChatItemEvent, ChatItemState> {
  final AppwriteRepository appwriteRepository;
  late final Future<String> meId;
  StreamSubscription<RealtimeMessage>? _chatStreamSubscription;
  ChatItemBloc({required this.appwriteRepository}) : super(ChatItemLoading()) {
    meId = HiveService.instance.getCurrentUserId();
    on<GetChatItemEvent>((event, emit) async {
      emit(ChatItemLoading());
      try {
        final String me = await meId;
        List<GroupMessage> groupMessages = await appwriteRepository
            .getGroupMessagesByUserId(me);
        Future<List<User>> friendsFuture = appwriteRepository.getFriendsList(
          me,
        );
        if (groupMessages.isEmpty) {
          List<User> friends = await friendsFuture;
          emit(ChatItemLoaded(meId: me, chatItems: [], friends: friends));
          return;
        }
        groupMessages.sort((a, b) {
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
        List<ChatItem> chatItems = [];
        for (var groupMessage in groupMessages) {
          chatItems.add(ChatItem(groupMessage: groupMessage, meId: me));
        }
        List<User> friends = await friendsFuture;
        emit(ChatItemLoaded(meId: me, chatItems: chatItems, friends: friends));
        add(SubscribeToChatStreamEvent());
      } catch (error) {
        emit(ChatItemError(message: error.toString()));
      }
    });
    on<UpdateChatItemEvent>((event, emit) async {
      try {
        if (state is ChatItemLoaded) {
          final currentState = state as ChatItemLoaded;
          final GroupMessage groupMessage = await appwriteRepository
              .getGroupMessageById(event.groupChatId);
          List<ChatItem> chatItems = List.from(currentState.chatItems);
          // for (int i = 0; i < chatItems.length; i++) {
          //   if (chatItems[i].groupMessage.groupMessagesId ==
          //       groupMessage.groupMessagesId) {
          //     chatItems[i] = chatItems[i].copyWith(groupMessage: groupMessage);
          //     break;
          //   }
          // }
          final index = chatItems.indexWhere(
            (element) =>
                element.groupMessage.groupMessagesId ==
                groupMessage.groupMessagesId,
          );
          if (index != -1) {
            final chatItem = chatItems[index].copyWith(
              groupMessage: groupMessage,
            );
            chatItems.removeAt(index);
            chatItems.insert(0, chatItem);
          }

          emit(currentState.copyWith(chatItems: chatItems));
          add(SubscribeToChatStreamEvent());
        }
      } catch (error) {
        emit(ChatItemError(message: error.toString()));
      }
    });
    on<UpdateUsersSeenEvent>((event, emit) async {
      try {
        if (state is ChatItemLoaded) {
          final currentState = state as ChatItemLoaded;
          final MessageModel message = event.message;
          final List<ChatItem> chatItems = (currentState.chatItems).toList();
          for (int i = 0; i < chatItems.length; i++) {
            if (chatItems[i].groupMessage.groupMessagesId ==
                message.groupMessagesId) {
              chatItems[i] = chatItems[i].copyWith(
                groupMessage: chatItems[i].groupMessage.copyWith(
                  lastMessage: message,
                ),
              );
              break;
            }
          }
          emit(currentState.copyWith(chatItems: chatItems));
        }
      } catch (error) {
        emit(ChatItemError(message: error.toString()));
      }
    });
    on<SubscribeToChatStreamEvent>((event, emit) async {
      try {
        if (state is ChatItemLoaded) {
          final currentState = state as ChatItemLoaded;
          final userId = currentState.meId;
          _chatStreamSubscription?.cancel();
          List<GroupMessage> groupMessages =
              currentState.chatItems.map((e) => e.groupMessage).toList();
          List<String> channels = [
            'databases.${AppwriteConfig.databaseId}.collections.${AppwriteConfig.userCollectionId}.documents.$userId',
          ];
          for (GroupMessage group in groupMessages) {
            channels.add(
              'databases.${AppwriteConfig.databaseId}.collections.${AppwriteConfig.groupMessagesCollectionId}.documents.${group.groupMessagesId}',
            );

            if (group.lastMessage != null) {
              channels.add(
                'databases.${AppwriteConfig.databaseId}.collections.${AppwriteConfig.messageCollectionId}.documents.${group.lastMessage!.id}',
              );
              debugPrint('Subscribing to message: ${group.lastMessage!.id}');
            }
          }
          debugPrint('Subscribing to channels: $channels');
          final subscription = AuthService.realtime.subscribe(channels);
          _chatStreamSubscription = subscription.stream.listen(
            (message) {
              debugPrint('Received update: ${message.events}');
              if (message.events.any(
                (event) =>
                    event.contains(
                      'collections.${AppwriteConfig.userCollectionId}',
                    ) &&
                    event.contains(currentState.meId),
              )) {
                add(GetChatItemEvent());
              } else if (message.events.any(
                (event) => event.contains(
                  'collections.${AppwriteConfig.groupMessagesCollectionId}',
                ),
              )) {
                final groupId = message.payload['\$id'] as String;
                add(UpdateChatItemEvent(groupChatId: groupId));
              } else if (message.events.any(
                (event) => event.contains(
                  'collections.${AppwriteConfig.messageCollectionId}',
                ),
              )) {
                final MessageModel newMessage = MessageModel.fromMap(
                  message.payload,
                );
                add(UpdateUsersSeenEvent(message: newMessage));
              }
            },
            onError: (error) {
              debugPrint('Error: $error');
              emit(ChatItemError(message: error.toString()));
            },
          );
        }
      } catch (error) {
        emit(ChatItemError(message: error.toString()));
      }
    });
    on<UpdateChatItemFromMessagePageEvent>((event, emit) async {
      try {
        if (state is ChatItemLoaded) {
          final currentState = state as ChatItemLoaded;
          final List<ChatItem> chatItems = (currentState.chatItems).toList();
          final GroupMessage newGroupMessage = event.groupMessage;
          final index = chatItems.indexWhere(
            (element) =>
                element.groupMessage.groupMessagesId ==
                newGroupMessage.groupMessagesId,
          );
          if (index != -1) {
            chatItems[index] = chatItems[index].copyWith(
              groupMessage: newGroupMessage,
            );
          }
          emit(currentState.copyWith(chatItems: chatItems));
        }
      } catch (error) {
        emit(ChatItemError(message: error.toString()));
      }
    });
  }
  @override
  Future<void> close() async {
    await _chatStreamSubscription?.cancel();
    super.close();
  }
}

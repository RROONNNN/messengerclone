import 'dart:async';

import 'package:appwrite/appwrite.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:messenger_clone/common/constants/appwrite_database_constants.dart';
import 'package:messenger_clone/common/services/common_function.dart';
import 'package:messenger_clone/common/services/hive_service.dart';
import 'package:messenger_clone/features/chat/data/data_sources/remote/appwrite_repository.dart';
import 'package:messenger_clone/features/chat/model/group_message.dart';
import 'package:messenger_clone/features/chat/model/user.dart';
import 'package:messenger_clone/features/messages/data/repositories/chat_repository_impl.dart';
import 'package:messenger_clone/features/messages/domain/models/message_model.dart';
import 'package:messenger_clone/features/messages/enum/message_status.dart';

part 'message_event.dart';
part 'message_state.dart';

class MessageBloc extends Bloc<MessageEvent, MessageState> {
  late final ChatRepositoryImpl chatRepository;
  late final AppwriteRepository appwriteRepository;
  final int _limit = 20;
  late final Future<String> meId;
  StreamSubscription<RealtimeMessage>? _chatStreamSubscription;
  StreamSubscription<RealtimeMessage>? _messagesStreamSubscription;
  MessageBloc() : super(MessageInitial()) {
    meId = HiveService.instance.getCurrentUserId();
    chatRepository = ChatRepositoryImpl();
    appwriteRepository = AppwriteRepository();
    on<MessageLoadEvent>(_onMessageLoadEvent);
    on<MessageLoadMoreEvent>(_onMessageLoadMoreEvent);
    on<ClearMessageEvent>(_onClearMessageEvent);
    on<MessageSendEvent>(_onMessageSendEvent);
    on<ReceiveMessageEvent>(_onReceiveMessageEvent);
    on<AddReactionEvent>(_onAddReactionEvent);
    on<SubscribeToChatStreamEvent>(_onSubscribeToChatStreamEvent);
    on<UnsubscribeFromChatStreamEvent>(_onUnsubscribeFromChatStreamEvent);
    on<SubscribeToMessagesEvent>(_onSubscribeToMessagesEvent);
    on<UnsubscribeFromMessagesEvent>(_onUnsubscribeFromMessagesEvent);
    on<UpdateMessageEvent>(_onUpdateMessageEvent);
  }
  void _onUpdateMessageEvent(
    UpdateMessageEvent event,
    Emitter<MessageState> emit,
  ) async {
    if (state is MessageLoaded) {
      try {
        final currentState = state as MessageLoaded;
        final String messageId = event.message.id;
        final List<MessageModel> messages = List<MessageModel>.from(
          currentState.messages,
        );
        final int index = messages.indexWhere(
          (message) => message.id == messageId,
        );
        if (index != -1) {
          if (messages[index].reactions.length ==
              event.message.reactions.length) {
            return;
          }
          messages[index] = event.message;
          emit(currentState.copyWith(messages: messages));
        }
      } catch (error) {
        debugPrint('Error updating message: $error');
        emit(MessageError(error.toString()));
      }
    }
  }

  void _onUnsubscribeFromMessagesEvent(
    UnsubscribeFromMessagesEvent event,
    Emitter<MessageState> emit,
  ) async {
    await _messagesStreamSubscription?.cancel();
    _messagesStreamSubscription = null;
  }

  void _onSubscribeToMessagesEvent(
    SubscribeToMessagesEvent event,
    Emitter<MessageState> emit,
  ) async {
    if (state is MessageLoaded) {
      try {
        final currentState = state as MessageLoaded;
        await _messagesStreamSubscription?.cancel();
        final List<String> messageIds =
            currentState.messages
                .where((message) {
                  return message.status != MessageStatus.failed &&
                      message.status != MessageStatus.sending;
                })
                .map((message) {
                  return message.id;
                })
                .toList();
        if (messageIds.isEmpty) return;
        debugPrint(
          'Subscribing to messages stream for messageIds: $messageIds',
        );
        final response = await chatRepository.getMessagesStream(messageIds);
        response.fold(
          (error) => debugPrint('Error subscribing to messages stream: $error'),
          (stream) {
            _messagesStreamSubscription = stream.listen(
              (event) {
                if (event.events.isEmpty) return;
                debugPrint('Received messages stream event: $event');
                final MessageModel message = MessageModel.fromMap(
                  event.payload,
                );
                add(UpdateMessageEvent(message));
              },
              onError: (error) {
                debugPrint('Error in messages stream: $error');
              },
            );
          },
        );
      } catch (error) {
        debugPrint('Error subscribing to messages stream: $error');
        emit(MessageError(error.toString()));
      }
    }
  }

  void _onSubscribeToChatStreamEvent(
    SubscribeToChatStreamEvent event,
    Emitter<MessageState> emit,
  ) async {
    if (state is MessageLoaded) {
      try {
        final currentState = state as MessageLoaded;
        if (_chatStreamSubscription != null) return;
        final GroupMessage groupMessage = currentState.groupMessage;
        final response = await chatRepository.getChatStream(
          groupMessage.groupMessagesId,
        );
        response.fold(
          (error) => debugPrint('Error subscribing to chat stream: $error'),
          (stream) {
            _chatStreamSubscription = stream.listen(
              (event) {
                if (event.events.isEmpty) return;
                add(ReceiveMessageEvent(event));
              },
              onError: (error) {
                debugPrint('Error in chat stream: $error');
              },
            );
          },
        );
      } catch (error) {
        debugPrint('Error subscribing to chat stream: $error');
        emit(MessageError(error.toString()));
      }
    }
  }

  void _onUnsubscribeFromChatStreamEvent(
    UnsubscribeFromChatStreamEvent event,
    Emitter<MessageState> emit,
  ) async {
    await _chatStreamSubscription?.cancel();
    _chatStreamSubscription = null;
  }

  @override
  Future<void> close() async {
    await _chatStreamSubscription?.cancel();
    _chatStreamSubscription = null;
    await _messagesStreamSubscription?.cancel();
    _messagesStreamSubscription = null;
    return super.close();
  }

  void _onAddReactionEvent(
    AddReactionEvent event,
    Emitter<MessageState> emit,
  ) async {
    if (state is MessageLoaded) {
      try {
        final currentState = state as MessageLoaded;
        final String messageId = event.messageId;
        final String reaction = event.reaction;
        final List<MessageModel> messages = List<MessageModel>.from(
          currentState.messages,
        );
        final int index = messages.indexWhere(
          (message) => message.id == messageId,
        );
        if (index != -1) {
          List<String> reactions = List<String>.from(messages[index].reactions);
          reactions.add(reaction);
          messages[index] = messages[index].copyWith(reactions: reactions);

          emit(currentState.copyWith(messages: messages));
          await chatRepository.updateMessage(messages[index]);
        }
      } catch (error) {
        debugPrint('_onAddReactionEvent Error adding reaction: $error');
        emit(MessageError(error.toString()));
      }
    }
  }

  void _onReceiveMessageEvent(
    ReceiveMessageEvent event,
    Emitter<MessageState> emit,
  ) async {
    if (state is MessageLoaded) {
      try {
        final RealtimeMessage realtimeMessage = event.realtimeMessage;
        final currentState = state as MessageLoaded;
        List<MessageModel> messages = List<MessageModel>.from(
          currentState.messages,
        );

        final payload = realtimeMessage.payload;

        if (!payload.containsKey(AppwriteDatabaseConstants.lastMessage)) {
          debugPrint('Payload is missing lastMessage field: $payload');
        }

        final MessageModel newMessage = MessageModel.fromMap(
          payload[AppwriteDatabaseConstants.lastMessage],
        );

        final String me = await meId;
        if (newMessage.idFrom != me) {
          messages.insert(0, newMessage);
          emit(currentState.copyWith(messages: messages));
        }
      } catch (error) {
        debugPrint('Error handling realtime message: $error');
        throw Exception('Error handling realtime message: $error');
      }
    }
  }

  void _onMessageSendEvent(
    MessageSendEvent event,
    Emitter<MessageState> emit,
  ) async {
    if (state is MessageLoaded) {
      final String message = event.message;
      final currentState = state as MessageLoaded;
      final String me = await meId;
      final GroupMessage groupMessage = currentState.groupMessage;
      List<MessageModel> messages = List<MessageModel>.from(
        currentState.messages,
      );
      final newMessage = MessageModel(
        idFrom: me,
        content: message,
        type: "text",
        groupMessagesId: groupMessage.groupMessagesId,
        status: MessageStatus.sending,
      );
      messages.insert(0, newMessage);
      emit(currentState.copyWith(messages: messages));
      final updatedMessages = List<MessageModel>.from(messages);
      final result = await chatRepository.sendMessage(newMessage, groupMessage);
      result.fold(
        (error) {
          debugPrint("Error sending message: $error");
          updatedMessages[0] = newMessage.copyWith(
            status: MessageStatus.failed,
          );

          emit(currentState.copyWith(messages: updatedMessages));
        },
        (success) {
          debugPrint("Message sent successfully");
          updatedMessages[0] = newMessage.copyWith(status: MessageStatus.sent);
          emit(currentState.copyWith(messages: updatedMessages));
        },
      );
    }
  }

  void _onClearMessageEvent(
    ClearMessageEvent event,
    Emitter<MessageState> emit,
  ) {
    emit(MessageInitial());
  }

  void _onMessageLoadMoreEvent(
    MessageLoadMoreEvent event,
    Emitter<MessageState> emit,
  ) async {
    try {
      if (state is MessageLoaded) {
        final currentState = state as MessageLoaded;
        emit(currentState.copyWith(isLoadingMore: true));
        final offset = currentState.messages.length;
        final result = await chatRepository
            .getMessages(
              currentState.groupMessage.groupMessagesId,
              _limit,
              offset,
            )
            .timeout(
              const Duration(seconds: 10),
              onTimeout:
                  () =>
                      Left("Request timed out. Please check your connection."),
            );

        result.fold(
          (error) => emit(MessageError(error)),
          (newMessages) => emit(
            currentState.copyWith(
              messages: [...currentState.messages, ...newMessages],
              isLoadingMore: false,
              hasMoreMessages: newMessages.length >= _limit,
            ),
          ),
        );
      }
    } catch (error) {
      if (state is MessageLoaded) {
        emit((state as MessageLoaded).copyWith(isLoadingMore: false));
      } else {
        emit(MessageError(error.toString()));
      }
    }
  }

  void _onMessageLoadEvent(
    MessageLoadEvent event,
    Emitter<MessageState> emit,
  ) async {
    emit(MessageLoading());

    try {
      final String me = await meId;
      final GroupMessage? groupMessage = event.groupMessage;
      final User? otherUser = event.otherUser;

      final Either<String, GroupMessage> groupResult =
          await _getOrCreateGroupMessage(groupMessage, otherUser, me);

      if (groupResult.isLeft()) {
        emit(MessageError(groupResult.fold((error) => error, (_) => "")));
        return;
      }

      final finalGroupMessage =
          groupResult.fold((_) => null, (group) => group)!;
      final List<User> others =
          (finalGroupMessage.users.length > 1)
              ? finalGroupMessage.users.where((user) => user.id != me).toList()
              : (finalGroupMessage.users).toList();

      final result = await chatRepository.getMessages(
        finalGroupMessage.groupMessagesId,
        _limit,
        0,
      );
      result.fold((error) => emit(MessageError(error)), (messages) {
        final state = MessageLoaded(
          messages: messages,
          groupMessage: finalGroupMessage,
          others: others,
          meId: me,
        );
        emit(state);
      });
    } catch (error) {
      debugPrint("Error loading messages: $error");
      emit(MessageError(error.toString()));
    }
  }

  Future<Either<String, GroupMessage>> _getOrCreateGroupMessage(
    GroupMessage? groupMessage,
    User? otherUser,
    String currentUserId,
  ) async {
    if (groupMessage != null) {
      return Right(groupMessage);
    }

    if (otherUser == null) {
      return Left("No user or group message provided");
    }

    final String groupId = CommonFunction.generateGroupId([
      currentUserId,
      otherUser.id,
    ]);

    final GroupMessage? existingGroup = await chatRepository
        .getGroupMessagesByGroupId(groupId);

    if (existingGroup != null) {
      debugPrint('Group message already exists.');
      return Right(existingGroup);
    }

    return await chatRepository.createGroupMessages(
      userIds: [currentUserId, otherUser.id],
      groupId: groupId,
    );
  }
}

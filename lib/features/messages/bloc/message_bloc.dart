import 'dart:async';
import 'dart:io' as io;
import 'dart:io';
import 'dart:io' as dart;

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:messenger_clone/common/constants/appwrite_database_constants.dart';
import 'package:messenger_clone/common/services/app_write_config.dart';
import 'package:messenger_clone/common/services/common_function.dart';
import 'package:messenger_clone/common/services/hive_service.dart';
import 'package:messenger_clone/common/services/send_mesage_service.dart';
import 'package:messenger_clone/features/chat/data/data_sources/remote/appwrite_repository.dart';
import 'package:messenger_clone/features/chat/model/group_message.dart';
import 'package:messenger_clone/features/chat/model/user.dart' as appUser;
import 'package:messenger_clone/features/messages/data/data_sources/local/hive_chat_repository.dart';
import 'package:messenger_clone/features/messages/data/repositories/chat_repository_impl.dart';
import 'package:messenger_clone/features/messages/domain/models/message_model.dart';
import 'package:messenger_clone/features/messages/enum/message_status.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

part 'message_event.dart';
part 'message_state.dart';

class MessageBloc extends Bloc<MessageEvent, MessageState> {
  late final ChatRepositoryImpl chatRepository;
  late final AppwriteRepository appwriteRepository;
  final int _limit = 20;
  late final Future<String> meId;
  StreamSubscription<RealtimeMessage>? _chatStreamSubscription;
  StreamSubscription<RealtimeMessage>? _messagesStreamSubscription;
  Timer? _seenStatusDebouncer;

  MessageBloc() : super(MessageInitial()) {
    meId = HiveService.instance.getCurrentUserId();
    chatRepository = ChatRepositoryImpl();
    appwriteRepository = AppwriteRepository();
    on<MessageLoadEvent>(_onLoad);
    on<MessageLoadMoreEvent>(_onLoadMore);
    on<MessageSendEvent>(_onSend);
    on<MessageUpdateGroupNameEvent>(_onUpdateName);
    on<MessageUpdateGroupAvatarEvent>(_onUpdateAvatar);
    on<MessageAddGroupMemberEvent>(_onAddMember);
    on<ClearMessageEvent>(_onClearMessageEvent);
    on<ReceiveMessageEvent>(_onReceiveMessageEvent);
    on<AddReactionEvent>(_onAddReactionEvent);
    on<SubscribeToChatStreamEvent>(_onSubscribeToChatStreamEvent);
    on<UnsubscribeFromChatStreamEvent>(_onUnsubscribeFromChatStreamEvent);
    on<SubscribeToMessagesEvent>(_onSubscribeToMessagesEvent);
    on<UnsubscribeFromMessagesEvent>(_onUnsubscribeFromMessagesEvent);
    on<UpdateMessageEvent>(_onUpdateMessageEvent);
    on<AddMeSeenMessageEvent>(_onAddMeSeenMessageEvent);
    on<MessageRemoveGroupMemberEvent>(_onRemoveMember);
  }

  List<appUser.User> _updateOthers(GroupMessage groupMessage, String meId) {
    return (groupMessage.users.length > 1)
        ? groupMessage.users.where((user) => user.id != meId).toList()
        : groupMessage.users.toList();
  }

  void _onRemoveMember(
    MessageRemoveGroupMemberEvent event,
    Emitter<MessageState> emit,
  ) async {
    if (state is! MessageLoaded) return;
    final currentState = state as MessageLoaded;
    final removedUser = event.memberToRemove;
    final me = currentState.meId;
    if (currentState.groupMessage.createrId?.trim() != me.trim()) {
      emit(MessageError('Only group admin can remove members'));
      return;
    }
    if (removedUser.id == me) {
      emit(MessageError('Admin cannot remove themselves from the group'));
      return;
    }

    try {
      final List<appUser.User> updatedUser =
          currentState.groupMessage.users
              .where((user) => user.id != removedUser.id)
              .toList();

      final GroupMessage updatedGroup = currentState.groupMessage.copyWith(
        users: updatedUser,
      );

      // Update the group in the backend
      final updatedGroupFromBackend = await appwriteRepository
          .updateGroupMessage(updatedGroup);

      emit(
        currentState.copyWith(
          groupMessage: updatedGroupFromBackend,
          others: _updateOthers(updatedGroupFromBackend, me),
          successMessage: '${removedUser.name} removed from group',
        ),
      );

      final admin = currentState.groupMessage.users.firstWhere(
        (user) => user.id == me,
      );
      final message =
          "${admin.name} removed ${removedUser.name} from the group";

      add(MessageSendEvent(message));
      emit(currentState.copyWith(successMessage: null));
    } catch (e) {
      emit(MessageError('Failed to remove member: $e'));
    }
  }

  void _onUpdateName(
    MessageUpdateGroupNameEvent event,
    Emitter<MessageState> emit,
  ) async {
    try {
      if (state is MessageLoaded) {
        final currentState = state as MessageLoaded;
        final me = currentState.meId;
        if (currentState.groupMessage.createrId?.trim() != me.trim()) {
          emit(MessageError('Only group admin can update group name'));
          return;
        }
        GroupMessage updatedGroup = currentState.groupMessage.copyWith(
          groupName: event.newName,
        );
        updatedGroup = await appwriteRepository.updateGroupMessage(
          updatedGroup,
        );
        final admin = currentState.groupMessage.users.firstWhere(
          (user) => user.id == me,
        );
        final message = "${admin.name} has named the group ${event.newName}";
        add(MessageSendEvent(message));

        emit(
          currentState.copyWith(
            groupMessage: updatedGroup,
            successMessage: 'Group name updated successfully',
          ),
        );

        emit(
          currentState.copyWith(
            groupMessage: updatedGroup,
            successMessage: null,
          ),
        );
      }
    } catch (e) {
      emit(MessageError(e.toString()));
    }
  }

  void _onAddMeSeenMessageEvent(
    AddMeSeenMessageEvent event,
    Emitter<MessageState> emit,
  ) async {
    if (state is MessageLoaded) {
      final currentState = state as MessageLoaded;
      final MessageModel message = event.message;
      if (message.idFrom != currentState.meId &&
          !message.isContains(currentState.meId)) {
        message.addUserSeen(appUser.User.createMeUser(currentState.meId));
        await chatRepository.updateMessage(message);
      }
    }
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
          messages[index] = event.message;
          emit(currentState.copyWith(messages: messages));
          _debouncedUpdateSeenStatus(event.message);
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
    add(UnsubscribeFromChatStreamEvent());
    List<Future<void>> futureList = [];
    if (_chatStreamSubscription != null) {
      futureList.add(_chatStreamSubscription!.cancel());
    }
    _chatStreamSubscription = null;
    if (_messagesStreamSubscription != null) {
      futureList.add(_messagesStreamSubscription!.cancel());
    }
    _messagesStreamSubscription = null;
    if (state is MessageLoaded) {
      final currentState = state as MessageLoaded;
      appwriteRepository.updateChattingWithGroupMessId(currentState.meId, null);

      //delete message status failed or sending
      List<MessageModel> messages = List<MessageModel>.from(
        currentState.messages,
      );
      if (currentState.lastSuccessMessage != null) {
        int index = messages.indexOf(currentState.lastSuccessMessage!);

        if (index != -1) {
          messages.removeRange(0, index);
          if (messages.isNotEmpty) {
            futureList.add(
              HiveChatRepository.instance.saveMessages(
                currentState.groupMessage.groupMessagesId,
                messages,
              ),
            );
          }
        }
      }

      for (var controller in currentState.videoPlayers.values) {
        await controller.dispose();
      }
    }
    add(ClearMessageEvent());
    await Future.wait(futureList);
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
        _debouncedUpdateSeenStatus(newMessage);

        final String me = await meId;
        if (newMessage.idFrom != me) {
          if (messages.first.id == newMessage.id) {
            debugPrint('Received message is already in the list: $newMessage');
            return;
          }
          messages.insert(0, newMessage);
          Map<String, VideoPlayerController> updatedVideoPlayers = Map.from(
            currentState.videoPlayers,
          );
          Map<String, Image> updatedImages = Map.from(currentState.images);
          if (newMessage.type == "video") {
            try {
              final controller = VideoPlayerController.networkUrl(
                Uri.parse(newMessage.content),
              );
              await controller.initialize();
              updatedVideoPlayers[newMessage.id] = controller;
            } catch (e) {
              debugPrint("Error initializing video player: $e");
            }
          }
          if (newMessage.type == "image") {
            try {
              final image = Image.network(newMessage.content);
              updatedImages[newMessage.id] = image;
            } catch (e) {
              debugPrint("Error loading image: $e");
            }
          }

          emit(
            currentState.copyWith(
              messages: messages,
              videoPlayers: updatedVideoPlayers,
              images: updatedImages,
              lastSuccessMessage: newMessage,
            ),
          );
        }
      } catch (error) {
        debugPrint('Error handling realtime message: $error');
        throw Exception('Error handling realtime message: $error');
      }
    }
  }

  String generateUrl(File file) {
    return "https://fra.cloud.appwrite.io/v1/storage/buckets/${AppwriteConfig.bucketId}/files/${file.$id}/view?project=${AppwriteConfig.projectId}";
  }

  void _onSend(MessageSendEvent event, Emitter<MessageState> emit) async {
    if (state is MessageLoaded) {
      final currentState = state as MessageLoaded;
      final String me = await meId;
      final GroupMessage groupMessage = currentState.groupMessage;
      List<MessageModel> messages = List<MessageModel>.from(
        currentState.messages,
      );
      Map<String, VideoPlayerController> videoPlayers = Map.from(
        currentState.videoPlayers,
      );

      late final newMessage;
      Map<String, Image> images = Map.from(currentState.images);
      switch (event.message.runtimeType) {
        case String:
          newMessage = MessageModel(
            sender: appUser.User.createMeUser(me),
            content: event.message,
            type: "text",
            groupMessagesId: groupMessage.groupMessagesId,
            status: MessageStatus.sending,
          );
          break;
        case XFile
            when event.message.name.endsWith('.mp4') ||
                event.message.name.endsWith('.mov') ||
                event.message.mimeType?.startsWith('video/') == true:
          final XFile video = event.message;
          final String filePath = video.path;
          final File file = await chatRepository.uploadFile(filePath, me);
          final String url = generateUrl(file);
          newMessage = MessageModel(
            sender: appUser.User.createMeUser(me),
            content: url,
            type: "video",
            groupMessagesId: groupMessage.groupMessagesId,
            status: MessageStatus.sending,
          );

          // Initialize video player for the new video message
          try {
            final controller = VideoPlayerController.networkUrl(Uri.parse(url));
            await controller.initialize();
            videoPlayers[newMessage.id] = controller;
          } catch (e) {
            debugPrint("Error initializing video player: $e");
          }
          break;
        default:
          final XFile image = event.message;

          final String filePath = image.path;
          final Image imageStore = Image.file(io.File(image.path));
          final File file = await chatRepository.uploadFile(filePath, me);
          final String url = generateUrl(file);
          newMessage = MessageModel(
            sender: appUser.User.createMeUser(me),
            content: url,
            type: "image",
            groupMessagesId: groupMessage.groupMessagesId,
            status: MessageStatus.sending,
          );
          images[newMessage.id] = imageStore;
      }
      debugPrint("Sending message: $newMessage");
      messages.insert(0, newMessage);
      emit(
        currentState.copyWith(
          messages: messages,
          videoPlayers: videoPlayers,
          images: images,
        ),
      );
      try {
        final MessageModel sentMessage = await chatRepository.sendMessage(
          newMessage,
          groupMessage,
        );
        final String tempId = newMessage.id;
        if (state is MessageLoaded) {
          final latestState = state as MessageLoaded;
          final List<MessageModel> latestMessages =
              (latestState.messages).toList();
          final int index = latestMessages.indexWhere(
            (message) => message.id == tempId,
          );
          if (index != -1) {
            debugPrint("Message sent successfully");
            latestMessages[index] = sentMessage.copyWith(
              status: MessageStatus.sent,
            );
            latestMessages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            emit(
              latestState.copyWith(
                messages: latestMessages,
                lastSuccessMessage: sentMessage,
              ),
            );
            List<String> userIds =
                groupMessage.users.map((user) => user.id).toList();
            SendMessageService.sendMessageNotification(
              userIds: userIds,
              groupMessageId: groupMessage.groupMessagesId,
              messageContent: sentMessage.content,
              senderId: me,
              senderName: sentMessage.sender.name,
            );
          }
        }
      } catch (error) {
        debugPrint("Error sending message: $error");
        if (state is MessageLoaded) {
          final latestState = state as MessageLoaded;
          final latestMessages = List<MessageModel>.from(latestState.messages);
          final int index = latestMessages.indexWhere(
            (message) => message.id == newMessage.id,
          );
          if (index != -1) {
            latestMessages[index] = latestMessages[index].copyWith(
              status: MessageStatus.failed,
            );
            emit(latestState.copyWith(messages: latestMessages));
          }
        }
      }
    }
  }

  void _onClearMessageEvent(
    ClearMessageEvent event,
    Emitter<MessageState> emit,
  ) {
    emit(MessageInitial());
  }

  void _onLoadMore(
    MessageLoadMoreEvent event,
    Emitter<MessageState> emit,
  ) async {
    try {
      if (state is MessageLoaded) {
        final currentState = state as MessageLoaded;
        emit(currentState.copyWith(isLoadingMore: true));
        final offset = currentState.messages.length;
        final List<MessageModel> newMessages = await chatRepository
            .getMessages(
              currentState.groupMessage.groupMessagesId,
              _limit,
              offset,
              null,
            )
            .timeout(
              const Duration(seconds: 10),
              onTimeout:
                  () =>
                      throw Exception(
                        "Request timed out. Please check your connection.",
                      ),
            );

        Map<String, VideoPlayerController> newVideoPlayers = {};
        Map<String, Image> newImages = {};
        for (MessageModel message in newMessages) {
          if (message.type == "video") {
            try {
              final controller = VideoPlayerController.networkUrl(
                Uri.parse(message.content),
              );
              await controller.initialize();
              newVideoPlayers[message.id] = controller;
            } catch (e) {
              debugPrint("Error initializing video player: $e");
            }
          }
          if (message.type == "image") {
            try {
              final image = Image.network(message.content);
              newImages[message.id] = image;
            } catch (e) {
              debugPrint("Error loading image: $e");
            }
          }
        }
        emit(
          currentState.copyWith(
            messages: [...currentState.messages, ...newMessages],
            isLoadingMore: false,
            hasMoreMessages: newMessages.length >= _limit,
            videoPlayers: {...currentState.videoPlayers, ...newVideoPlayers},
            images: {...currentState.images, ...newImages},
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

  List<MessageModel> _updateUserInCache(
    List<MessageModel> cachedMessages,
    List<appUser.User> users,
  ) {
    final Map<String, appUser.User> userMap = {
      for (var user in users) user.id: user,
    };

    return cachedMessages.map((message) {
      final updatedUser = userMap[message.sender.id];
      if (updatedUser != null) {
        return message.copyWith(sender: updatedUser);
      }
      return message;
    }).toList();
  }

  void _onLoad(MessageLoadEvent event, Emitter<MessageState> emit) async {
    emit(MessageLoading());
    try {
      final String me = await meId;
      final GroupMessage? groupMessage = event.groupMessage;
      final appUser.User? otherUser = event.otherUser;

      final Either<String, GroupMessage> groupResult =
          await _getOrCreateGroupMessage(groupMessage, otherUser, me);

      if (groupResult.isLeft()) {
        emit(MessageError(groupResult.fold((error) => error, (_) => "")));
        return;
      }

      GroupMessage finalGroupMessage =
          groupResult.fold((_) => null, (group) => group)!;

      MessageModel? lastMessage = finalGroupMessage.lastMessage;
      if (lastMessage != null &&
          lastMessage.idFrom != me &&
          !lastMessage.usersSeen.contains(appUser.User.createMeUser(me))) {
        lastMessage.addUserSeen(appUser.User.createMeUser(me));
        chatRepository.updateMessage(lastMessage);
        finalGroupMessage = finalGroupMessage.copyWith(
          lastMessage: lastMessage,
        );
      }
      final List<appUser.User> others =
          (finalGroupMessage.users.length > 1)
              ? finalGroupMessage.users.where((user) => user.id != me).toList()
              : (finalGroupMessage.users).toList();
      List<MessageModel> cachedMessages =
          await HiveChatRepository.instance.getMessages(
            finalGroupMessage.groupMessagesId,
          ) ??
          [];

      if (cachedMessages.isNotEmpty) {
        emit(
          MessageLoaded(
            messages: cachedMessages,
            groupMessage: finalGroupMessage,
            others: others,
            meId: me,
            hasMoreMessages: true,
          ),
        );
      }
      appwriteRepository.updateChattingWithGroupMessId(
        me,
        finalGroupMessage.groupMessagesId,
      );
      cachedMessages = _updateUserInCache(cachedMessages, others);
      final DateTime? latestTimestamp =
          cachedMessages.isNotEmpty ? cachedMessages.first.createdAt : null;
      final List<MessageModel> newMessages = await chatRepository
          .getMessages(
            finalGroupMessage.groupMessagesId,
            _limit,
            0,
            latestTimestamp,
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout:
                () =>
                    throw Exception(
                      "Request timed out. Please check your connection.",
                    ),
          );
      final allMessages = [...newMessages, ...cachedMessages]
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      Map<String, VideoPlayerController> videoPlayers = {};
      Map<String, Image> images = {};

      for (final MessageModel message in allMessages) {
        if (message.type == "video") {
          try {
            if (await isCacheFile(message.content, AppwriteConfig.bucketId)) {
              debugPrint("File already exists in cache: ${message.content}");
              final controller = VideoPlayerController.file(
                io.File(
                  "${(await getTemporaryDirectory()).path}/$AppwriteConfig.bucketId/${getFileidFromUrl(message.content)}",
                ),
              );
              videoPlayers[message.id] = controller;
              controller.initialize().then((_) {
                videoPlayers[message.id] = controller;
              });
              continue;
            }
            chatRepository.downloadFile(
              message.content,
              AppwriteConfig.bucketId,
            );
            final controller = VideoPlayerController.networkUrl(
              Uri.parse(message.content),
            );
            videoPlayers[message.id] = controller;
            controller.initialize().then((_) {
              videoPlayers[message.id] = controller;
            });
          } catch (e) {
            debugPrint("Error initializing video player for ${message.id}: $e");
          }
        }
        if (message.type == "image") {
          try {
            if (await isCacheFile(message.content, AppwriteConfig.bucketId)) {
              debugPrint("File already exists in cache: ${message.content}");
              final image = Image.file(
                io.File(
                  "${(await getTemporaryDirectory()).path}/$AppwriteConfig.bucketId/${getFileidFromUrl(message.content)}",
                ),
              );
              images[message.id] = image;
              continue;
            }
            final image = Image.network(message.content);
            images[message.id] = image;
          } catch (e) {
            debugPrint("Error loading image for ${message.id}: $e");
          }
        }
      }
      emit(
        MessageLoaded(
          messages: allMessages,
          groupMessage: finalGroupMessage,
          others: others,
          meId: me,
          hasMoreMessages: true,
          videoPlayers: videoPlayers,
          images: images,
          lastSuccessMessage: allMessages.isNotEmpty ? allMessages.first : null,
        ),
      );
    } catch (error) {
      debugPrint("Error loading messages: $error");
      emit(MessageError(error.toString()));
    }
  }

  Future<Either<String, GroupMessage>> _getOrCreateGroupMessage(
    GroupMessage? groupMessage,
    appUser.User? otherUser,
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

  void _debouncedUpdateSeenStatus(MessageModel message) {
    _seenStatusDebouncer?.cancel();
    _seenStatusDebouncer = Timer(const Duration(milliseconds: 500), () {
      add(AddMeSeenMessageEvent(message));
    });
  }

  Future<bool> isCacheFile(String url, String filePath) async {
    if (filePath.isEmpty) {
      return false;
    }
    final String fileid = getFileidFromUrl(url);
    final Directory cacheDir = await getTemporaryDirectory();
    final String dirPath = '${cacheDir.path}/$filePath/$fileid';
    final dart.File file = dart.File(dirPath);
    return file.existsSync();
  }

  String getFileidFromUrl(String url) {
    try {
      final Uri uri = Uri.parse(url);

      if (!uri.host.contains('appwrite.io') ||
          !uri.path.contains('/storage/buckets/')) {
        debugPrint('Not a valid Appwrite storage URL: $url');
        throw Exception('Not a valid Appwrite storage URL');
      }

      final List<String> segments = uri.pathSegments;
      final int filesIndex = segments.indexOf('files');

      if (filesIndex == -1 || filesIndex + 1 >= segments.length) {
        debugPrint('URL format not recognized: $url');
        throw Exception('URL format not recognized');
      }

      final String fileId = segments[filesIndex + 1];
      debugPrint('Extracted fileId: $fileId from URL');
      return fileId;
    } catch (e) {
      debugPrint('Error extracting file info from URL: $e');
      throw Exception('Failed to extract fileId from URL');
    }
  }

  Future<void> _onUpdateAvatar(
    MessageUpdateGroupAvatarEvent event,
    Emitter<MessageState> emit,
  ) async {
    try {
      if (state is MessageLoaded) {
        final currentState = state as MessageLoaded;
        final me = await meId;

        if (currentState.groupMessage.createrId != me) {
          emit(MessageError('Only group admin can update group avatar'));
          return;
        }
        final file = await chatRepository.uploadFile(event.newAvatarUrl, me);
        final String url = generateUrl(file);
        GroupMessage updatedGroup = currentState.groupMessage.copyWith(
          avatarGroupUrl: url,
        );
        updatedGroup = await appwriteRepository.updateGroupMessage(
          updatedGroup,
        );

        // Create notification message
        final admin = currentState.groupMessage.users.firstWhere(
          (user) => user.id == me,
        );
        final message = "${admin.name} has changed the group photo";
        add(MessageSendEvent(message));

        emit(
          currentState.copyWith(
            groupMessage: updatedGroup,
            successMessage: 'Group avatar updated successfully',
          ),
        );

        emit(
          currentState.copyWith(
            groupMessage: updatedGroup,
            successMessage: null,
          ),
        );
      }
    } catch (e) {
      emit(MessageError(e.toString()));
    }
  }

  Future<void> _onAddMember(
    MessageAddGroupMemberEvent event,
    Emitter<MessageState> emit,
  ) async {
    try {
      if (state is! MessageLoaded) return;
      final currentState = state as MessageLoaded;
      final me = await meId;
      if (currentState.groupMessage.createrId?.trim() != me.trim()) {
        emit(MessageError('Only group admin can add members'));
        return;
      }
      final GroupMessage newGroupMessage = event.newGroupMessage;

      emit(
        currentState.copyWith(
          groupMessage: newGroupMessage,
          others: _updateOthers(newGroupMessage, me),
        ),
      );
    } catch (e) {
      emit(MessageError(e.toString()));
    }
  }
}

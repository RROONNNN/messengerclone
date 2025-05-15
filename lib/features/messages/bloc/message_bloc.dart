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
import 'package:messenger_clone/features/chat/data/data_sources/remote/appwrite_repository.dart';
import 'package:messenger_clone/features/chat/model/group_message.dart';
import 'package:messenger_clone/features/chat/model/user.dart' as appUser;
import 'package:messenger_clone/features/messages/data/repositories/chat_repository_impl.dart';
import 'package:messenger_clone/features/messages/domain/models/message_model.dart';
import 'package:messenger_clone/features/messages/enum/message_status.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;

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
    on<AddMeSeenMessageEvent>(_onAddMeSeenMessageEvent);
  }

  void _onAddMeSeenMessageEvent(
    AddMeSeenMessageEvent event,
    Emitter<MessageState> emit,
  ) async {
    if (state is MessageLoaded) {
      final currentState = state as MessageLoaded;
      final MessageModel message = event.message;
      if (message.idFrom != currentState.meId &&
          message.isContains(currentState.meId)) {
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
          // if (messages[index].reactions.length ==
          //     event.message.reactions.length) {
          //   return;
          // }

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
    await _chatStreamSubscription?.cancel();
    _chatStreamSubscription = null;
    await _messagesStreamSubscription?.cancel();
    _messagesStreamSubscription = null;

    if (state is MessageLoaded) {
      final currentState = state as MessageLoaded;
      // Dispose video players
      for (var controller in currentState.videoPlayers.values) {
        await controller.dispose();
      }
    }

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

  void _onMessageSendEvent(
    MessageSendEvent event,
    Emitter<MessageState> emit,
  ) async {
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
      final result = await chatRepository.sendMessage(newMessage, groupMessage);
      final String tempId = newMessage.id;
      if (state is MessageLoaded) {
        final latestState = state as MessageLoaded;
        final latestMessages = List<MessageModel>.from(latestState.messages);
        final int index = latestMessages.indexWhere(
          (message) => message.id == tempId,
        );

        if (index != -1) {
          result.fold(
            (error) {
              debugPrint("Error sending message: $error");
              latestMessages[index] = latestMessages[index].copyWith(
                status: MessageStatus.failed,
              );
            },
            (success) {
              debugPrint("Message sent successfully");
              latestMessages[index] = latestMessages[index].copyWith(
                id: tempId,
                status: MessageStatus.sent,
              );
            },
          );
          emit(latestState.copyWith(messages: latestMessages));
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

  void _onMessageLoadMoreEvent(
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

  void _onMessageLoadEvent(
    MessageLoadEvent event,
    Emitter<MessageState> emit,
  ) async {
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

      final finalGroupMessage =
          groupResult.fold((_) => null, (group) => group)!;
      MessageModel? lastMessage = finalGroupMessage.lastMessage;
      if (lastMessage != null &&
          lastMessage.idFrom != me &&
          !lastMessage.usersSeen.contains(appUser.User.createMeUser(me))) {
        lastMessage.addUserSeen(appUser.User.createMeUser(me));
      }
      final List<appUser.User> others =
          (finalGroupMessage.users.length > 1)
              ? finalGroupMessage.users.where((user) => user.id != me).toList()
              : (finalGroupMessage.users).toList();

      // Fetch messages with timeout handling
      final List<MessageModel> messages = await chatRepository
          .getMessages(finalGroupMessage.groupMessagesId, _limit, 0)
          .timeout(
            const Duration(seconds: 10),
            onTimeout:
                () =>
                    throw Exception(
                      "Request timed out. Please check your connection.",
                    ),
          );

      Map<String, VideoPlayerController> videoPlayers = {};
      Map<String, Image> images = {};

      for (final MessageModel message in messages) {
        if (message.type == "video") {
          try {
            if (await isCacheFile(message.content, AppWriteService.bucketId)) {
              debugPrint("File already exists in cache: ${message.content}");
              final controller = VideoPlayerController.file(
                io.File(
                  "${(await getTemporaryDirectory()).path}/$AppWriteService.bucketId/${getFileidFromUrl(message.content)}",
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
              AppWriteService.bucketId,
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
            if (await isCacheFile(message.content, AppWriteService.bucketId)) {
              debugPrint("File already exists in cache: ${message.content}");
              final image = Image.file(
                io.File(
                  "${(await getTemporaryDirectory()).path}/$AppWriteService.bucketId/${getFileidFromUrl(message.content)}",
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
          messages: messages,
          groupMessage: finalGroupMessage,
          others: others,
          meId: me,
          hasMoreMessages: messages.length >= _limit,
          videoPlayers: videoPlayers,
          images: images,
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

  // Future<String> downloadFile(String url, String filePath) async {
  //   try {
  //     final Future<http.Response> responseFuture = http.get(Uri.parse(url));
  //     final Directory cacheDir = await getTemporaryDirectory();
  //     final String dirPath = '${cacheDir.path}/$filePath';
  //     final String fullPath = '$dirPath/$url';
  //     final file = dart.File(fullPath);
  //     final Future<void> dirCreationFuture = dart.Directory(
  //       dirPath,
  //     ).create(recursive: true);
  //     final results = await Future.wait([dirCreationFuture, responseFuture]);
  //     final http.Response response = results[1] as http.Response;
  //     if (response.statusCode != 200) {
  //       throw Exception("Failed to download file: ${response.statusCode}");
  //     }
  //     final bytes = response.bodyBytes;

  //     await file.writeAsBytes(bytes);

  //     debugPrint("File downloaded and saved to $fullPath");
  //     return fullPath;
  //   } catch (error) {
  //     debugPrint("Failed to download file: $error");
  //     throw Exception("Failed to download file: $error");
  //   }
  // }

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
}

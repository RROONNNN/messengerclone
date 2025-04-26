import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:messenger_clone/features/chat/data/data_sources/remote/appwrite_repository.dart';
import 'package:messenger_clone/features/chat/model/chat_item.dart';
import 'package:messenger_clone/features/chat/model/group_message.dart';

part 'chat_item_event.dart';
part 'chat_item_state.dart';

class ChatItemBloc extends Bloc<ChatItemEvent, ChatItemState> {
  final AppwriteRepository appwriteRepository;
  ChatItemBloc({required this.appwriteRepository}) : super(ChatItemLoading()) {
    on<GetChatItemEvent>((event, emit) async {
      emit(ChatItemLoading());
      try {
        final List<GroupMessage> groupMessages = await appwriteRepository
            .getGroupMessagesByUserId(event.userId);

        List<ChatItem> chatItems = [];
        for (var groupMessage in groupMessages) {
          if (groupMessage.latestMessage == null) {
            continue;
          }
          for (var user in groupMessage.users) {
            if (user != user.id) {
              final isTheLatestMessSentByMe =
                  groupMessage.latestMessage!.idFrom == user.id;
              chatItems.add(
                ChatItem(
                  groupMessage: groupMessage,
                  time: groupMessage.latestMessage!.timestamp,
                  hasUnread:
                      (isTheLatestMessSentByMe)
                          ? false
                          : groupMessage.latestMessage!.isSeen,
                ),
              );
            }
          }
        }
        emit(ChatItemLoaded(chatItems: chatItems));
      } catch (error) {
        emit(ChatItemError(message: error.toString()));
      }
    });
  }
}

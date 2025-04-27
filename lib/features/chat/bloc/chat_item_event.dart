part of 'chat_item_bloc.dart';

sealed class ChatItemEvent extends Equatable {
  const ChatItemEvent();

  @override
  List<Object> get props => [];
}

class GetChatItemEvent extends ChatItemEvent {
  final String userid;
  const GetChatItemEvent({required this.userid});
  @override
  List<Object> get props => [userid];
}

class UpdateChatItemEvent extends ChatItemEvent {
  final String groupChatId;
  const UpdateChatItemEvent({required this.groupChatId});
}

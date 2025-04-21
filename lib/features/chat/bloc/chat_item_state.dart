part of 'chat_item_bloc.dart';

sealed class ChatItemState extends Equatable {
  const ChatItemState();

  @override
  List<Object> get props => [];
}

final class ChatItemLoading extends ChatItemState {}

final class ChatItemLoaded extends ChatItemState {
  final List<ChatItem> chatItems;
  const ChatItemLoaded({required this.chatItems});

  @override
  List<Object> get props => [chatItems];
}

final class ChatItemError extends ChatItemState {
  final String message;
  const ChatItemError({required this.message});

  @override
  List<Object> get props => [message];
}

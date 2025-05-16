part of 'chat_item_bloc.dart';

sealed class ChatItemState extends Equatable {
  const ChatItemState();

  @override
  List<Object> get props => [];
}

final class ChatItemLoading extends ChatItemState {}

final class ChatItemLoaded extends ChatItemState {
  final List<ChatItem> chatItems;
  final String meId;
  const ChatItemLoaded({required this.chatItems, required this.meId});

  ChatItemLoaded copyWith({
    List<GroupMessage>? groupMessages,
    List<ChatItem>? chatItems,
    String? meId,
  }) {
    return ChatItemLoaded(
      chatItems: chatItems ?? this.chatItems,
      meId: meId ?? this.meId,
    );
  }

  @override
  List<Object> get props => [chatItems, meId];
}

final class ChatItemError extends ChatItemState {
  final String message;
  const ChatItemError({required this.message});

  @override
  List<Object> get props => [message];
}

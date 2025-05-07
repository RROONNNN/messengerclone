part of 'message_bloc.dart';

sealed class MessageState extends Equatable {
  const MessageState();

  @override
  List<Object> get props => [];
}

final class MessageInitial extends MessageState {}

final class MessageLoading extends MessageState {}

final class MessageLoaded extends MessageState {
  final List<MessageModel> messages;
  final GroupMessage groupMessage;
  final bool isLoadingMore;
  final bool hasMoreMessages;
  final List<User> others;
  final String meId;
  const MessageLoaded({
    required this.messages,
    required this.groupMessage,
    this.isLoadingMore = false,
    this.hasMoreMessages = true,
    required this.others,
    required this.meId,
  });
  @override
  List<Object> get props => [messages, groupMessage];
  MessageLoaded copyWith({
    List<MessageModel>? messages,
    GroupMessage? groupMessage,
    bool? isLoadingMore,
    bool? hasMoreMessages,
    List<User>? others,
    String? meId,
  }) {
    return MessageLoaded(
      messages: messages ?? this.messages,
      groupMessage: groupMessage ?? this.groupMessage,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMoreMessages: hasMoreMessages ?? this.hasMoreMessages,
      others: others ?? this.others,
      meId: meId ?? this.meId,
    );
  }
}

final class MessageError extends MessageState {
  final String error;
  const MessageError(this.error);
  @override
  List<Object> get props => [error];
}

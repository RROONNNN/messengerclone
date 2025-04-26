part of 'group_messages_bloc.dart';

sealed class GroupMessagesState extends Equatable {
  const GroupMessagesState();
  
  @override
  List<Object> get props => [];
}

final class GroupMessagesInitial extends GroupMessagesState {}

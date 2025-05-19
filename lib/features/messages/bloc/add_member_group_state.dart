import 'package:equatable/equatable.dart';
import 'package:messenger_clone/features/chat/model/group_message.dart';
import 'package:messenger_clone/features/chat/model/user.dart';

enum AddMemberGroupStatus { initial, loading, adding, success, error }

abstract class AddMemberGroupState extends Equatable {
  const AddMemberGroupState();

  @override
  List<Object?> get props => [];
}

class AddMemberGroupInitial extends AddMemberGroupState {
  const AddMemberGroupInitial();

  @override
  List<Object?> get props => [];
}

class AddMemberGroupLoading extends AddMemberGroupState {
  const AddMemberGroupLoading();

  @override
  List<Object?> get props => [];
}

class AddMemberGroupLoaded extends AddMemberGroupState {
  final List<User> friends;
  final Set<String> selectedFriends;
  final List<User>? filteredFriends;
  final AddMemberGroupStatus status;
  final GroupMessage? groupMessage;

  const AddMemberGroupLoaded({
    required this.friends,
    required this.selectedFriends,
    this.filteredFriends,
    this.status = AddMemberGroupStatus.initial,
    this.groupMessage,
  }) : assert(
         status != AddMemberGroupStatus.success || groupMessage != null,
         'groupMessage must not be null when status is success',
       );

  AddMemberGroupLoaded copyWith({
    List<User>? friends,
    Set<String>? selectedFriends,
    List<User>? filteredFriends,
    AddMemberGroupStatus? status,
    GroupMessage? groupMessage,
  }) {
    return AddMemberGroupLoaded(
      friends: friends ?? this.friends,
      selectedFriends: selectedFriends ?? this.selectedFriends,
      filteredFriends: filteredFriends ?? this.filteredFriends,
      status: status ?? this.status,
      groupMessage: groupMessage ?? this.groupMessage,
    );
  }

  @override
  List<Object?> get props => [
    friends,
    filteredFriends,
    selectedFriends,
    status,
    groupMessage,
  ];
}

class AddMemberGroupError extends AddMemberGroupState {
  final String message;

  const AddMemberGroupError({required this.message});

  @override
  List<Object?> get props => [message];
}

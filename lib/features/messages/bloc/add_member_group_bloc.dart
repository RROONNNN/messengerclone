import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:messenger_clone/common/services/hive_service.dart';
import 'package:messenger_clone/features/chat/data/data_sources/remote/appwrite_repository.dart';
import 'package:messenger_clone/features/chat/model/group_message.dart';
import 'package:messenger_clone/features/chat/model/user.dart';
import 'package:messenger_clone/features/messages/bloc/add_member_group_event.dart';
import 'package:messenger_clone/features/messages/bloc/add_member_group_state.dart';

class AddMemberGroupBloc
    extends Bloc<AddMemberGroupEvent, AddMemberGroupState> {
  final AppwriteRepository _appwriteRepository;
  final GroupMessage _groupMessage;

  AddMemberGroupBloc({
    AppwriteRepository? appwriteRepository,
    required GroupMessage groupMessage,
  }) : _appwriteRepository = appwriteRepository ?? AppwriteRepository(),
       _groupMessage = groupMessage,
       super(const AddMemberGroupInitial()) {
    on<LoadFriendsEvent>(_onLoadFriends);
    on<SearchFriendsEvent>(_onSearchFriends);
    on<SelectFriendEvent>(_onSelectFriend);
    on<DeselectFriendEvent>(_onDeselectFriend);
    on<SubmitAddMembersEvent>(_onSubmitAddMembers);
  }

  Future<void> _onLoadFriends(
    LoadFriendsEvent event,
    Emitter<AddMemberGroupState> emit,
  ) async {
    try {
      emit(const AddMemberGroupLoading());
      final currentUserId = HiveService.instance.currentUserId;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }
      final friends = await _appwriteRepository.getFriendsList(currentUserId);
      final filteredFriends =
          friends
              .where((friend) => !event.userEnjoyedIds.contains(friend.id))
              .toList();
      emit(
        AddMemberGroupLoaded(
          friends: friends,
          selectedFriends: const {},
          filteredFriends: filteredFriends,
          status: AddMemberGroupStatus.initial,
        ),
      );
    } catch (e) {
      emit(AddMemberGroupError(message: e.toString()));
    }
  }

  void _onSearchFriends(
    SearchFriendsEvent event,
    Emitter<AddMemberGroupState> emit,
  ) {
    if (state is AddMemberGroupLoaded) {
      final currentState = state as AddMemberGroupLoaded;
      if (event.query.isEmpty) {
        emit(currentState.copyWith(filteredFriends: currentState.friends));
      } else {
        final filteredFriends =
            currentState.friends
                .where(
                  (friend) => friend.name.toLowerCase().contains(
                    event.query.toLowerCase(),
                  ),
                )
                .toList();
        emit(currentState.copyWith(filteredFriends: filteredFriends));
      }
    }
  }

  void _onSelectFriend(
    SelectFriendEvent event,
    Emitter<AddMemberGroupState> emit,
  ) {
    if (state is AddMemberGroupLoaded) {
      final currentState = state as AddMemberGroupLoaded;
      final updatedSelectedFriends = {
        ...currentState.selectedFriends,
        event.friendId,
      };
      emit(currentState.copyWith(selectedFriends: updatedSelectedFriends));
    }
  }

  void _onDeselectFriend(
    DeselectFriendEvent event,
    Emitter<AddMemberGroupState> emit,
  ) {
    if (state is AddMemberGroupLoaded) {
      final currentState = state as AddMemberGroupLoaded;
      final updatedSelectedFriends = {...currentState.selectedFriends}
        ..remove(event.friendId);
      emit(currentState.copyWith(selectedFriends: updatedSelectedFriends));
    }
  }

  Future<void> _onSubmitAddMembers(
    SubmitAddMembersEvent event,
    Emitter<AddMemberGroupState> emit,
  ) async {
    if (state is AddMemberGroupLoaded) {
      final currentState = state as AddMemberGroupLoaded;
      try {
        emit(currentState.copyWith(status: AddMemberGroupStatus.adding));
        Set<String> memberIds =
            _groupMessage.users.map((user) => user.id).toSet();
        memberIds.addAll(currentState.selectedFriends.toList());
        final newGroupMessage = await _appwriteRepository.updateMemberOfGroup(
          _groupMessage.groupMessagesId,
          memberIds,
        );
        emit(
          currentState.copyWith(
            status: AddMemberGroupStatus.success,
            groupMessage: newGroupMessage,
          ),
        );
      } catch (e) {
        emit(AddMemberGroupError(message: e.toString()));
      }
    }
  }
}

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:messenger_clone/common/services/auth_service.dart';
import 'package:messenger_clone/common/services/common_function.dart';
import 'package:messenger_clone/features/chat/model/group_message.dart';
import 'package:messenger_clone/features/chat/model/user.dart';
import 'package:messenger_clone/features/chat/data/data_sources/remote/appwrite_repository.dart';
import 'package:messenger_clone/features/messages/data/data_sources/remote/appwrite_chat_repository.dart';
import 'package:appwrite/models.dart' as appwrite;
part 'create_group_event.dart';
part 'create_group_state.dart';

class CreateGroupBloc extends Bloc<CreateGroupEvent, CreateGroupState> {
  final AppwriteRepository _appwriteRepository;
  final AppwriteChatRepository _chatRepository;
  appwrite.User? _currentUser;

  CreateGroupBloc({AppwriteRepository? appwriteRepository})
    : _appwriteRepository = appwriteRepository ?? AppwriteRepository(),
      _chatRepository = AppwriteChatRepository(),
      super(CreateGroupInitial()) {
    on<LoadFriendsEvent>(_onLoadFriends);
    on<SearchFriendsEvent>(_onSearchFriends);
    on<SelectFriendEvent>(_onSelectFriend);
    on<DeselectFriendEvent>(_onDeselectFriend);
    on<UpdateGroupNameEvent>(_onUpdateGroupName);
    on<SubmitCreateGroupEvent>(_onCreateGroup);
  }

  String _generateGroupName(List<User> friends) {
    if (friends.isEmpty) return '';
    final firstNames =
        friends.map((user) {
          final nameParts = user.name.trim().split(' ');
          return nameParts.isNotEmpty ? nameParts.first : user.name.trim();
        }).toList();
    return firstNames.join(', ');
  }

  Future<void> _onLoadFriends(
    LoadFriendsEvent event,
    Emitter<CreateGroupState> emit,
  ) async {
    emit(CreateGroupLoading());
    try {
      _currentUser = await AuthService.getCurrentUser();
      if (_currentUser == null) throw Exception('User not logged in');

      final friends = await _appwriteRepository.getFriendsList(
        _currentUser!.$id,
      );
      emit(
        CreateGroupLoaded(
          friends: friends,
          selectedFriends: const [],
          groupName: '',
          status: CreateGroupStatus.idle,
          filteredFriends: null,
        ),
      );
    } catch (e) {
      emit(CreateGroupError(e.toString()));
    }
  }

  Future<void> _onSearchFriends(
    SearchFriendsEvent event,
    Emitter<CreateGroupState> emit,
  ) async {
    if (state is CreateGroupLoaded) {
      final loaded = state as CreateGroupLoaded;
      final String query = event.query.trim().toLowerCase();
      final filteredFriends =
          query.isEmpty
              ? null
              : loaded.friends
                  .where(
                    (user) =>
                        user.name.toLowerCase().contains(query) ||
                        user.aboutMe.toLowerCase().contains(query),
                  )
                  .toList();
      emit(loaded.copyWith(filteredFriends: filteredFriends));
    }
  }

  void _onSelectFriend(
    SelectFriendEvent event,
    Emitter<CreateGroupState> emit,
  ) {
    if (state is CreateGroupLoaded) {
      final loaded = state as CreateGroupLoaded;
      final updated = List<String>.from(loaded.selectedFriends)
        ..add(event.friendId);
      emit(loaded.copyWith(selectedFriends: updated));
    }
  }

  void _onDeselectFriend(
    DeselectFriendEvent event,
    Emitter<CreateGroupState> emit,
  ) {
    if (state is CreateGroupLoaded) {
      final loaded = state as CreateGroupLoaded;
      final updated = List<String>.from(loaded.selectedFriends)
        ..remove(event.friendId);
      emit(loaded.copyWith(selectedFriends: updated));
    }
  }

  void _onUpdateGroupName(
    UpdateGroupNameEvent event,
    Emitter<CreateGroupState> emit,
  ) {
    if (state is CreateGroupLoaded) {
      final loaded = state as CreateGroupLoaded;
      emit(loaded.copyWith(groupName: event.groupName));
    }
  }

  Future<void> _onCreateGroup(
    SubmitCreateGroupEvent event,
    Emitter<CreateGroupState> emit,
  ) async {
    if (state is CreateGroupLoaded) {
      emit(
        (state as CreateGroupLoaded).copyWith(
          status: CreateGroupStatus.creating,
        ),
      );
      try {
        _currentUser ??= await AuthService.getCurrentUser();
        final Set<String> allUserInvolveMeId = {_currentUser!.$id};

        final currentState = state as CreateGroupLoaded;
        allUserInvolveMeId.addAll(currentState.selectedFriends);
        String groupId = CommonFunction.generateGroupId(
          allUserInvolveMeId.toList(),
        );
        final groupMess = await _chatRepository.createGroupMessages(
          groupName: currentState.groupName,
          userIds: allUserInvolveMeId.toList(),
          groupId: groupId,
          isGroup: true,
          createrId: _currentUser!.$id,
        );

        emit(
          (state as CreateGroupLoaded).copyWith(
            status: CreateGroupStatus.success,
            createdGroup: groupMess,
          ),
        );
      } catch (e) {
        emit(CreateGroupError(e.toString()));
      }
    }
  }
}

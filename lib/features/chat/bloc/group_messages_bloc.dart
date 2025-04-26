import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'group_messages_event.dart';
part 'group_messages_state.dart';

class GroupMessagesBloc extends Bloc<GroupMessagesEvent, GroupMessagesState> {
  GroupMessagesBloc() : super(GroupMessagesInitial()) {
    on<GroupMessagesEvent>((event, emit) {
      // TODO: implement event handler
    });
  }
}

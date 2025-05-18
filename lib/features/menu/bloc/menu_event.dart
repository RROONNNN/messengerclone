part of 'menu_bloc.dart';

abstract class MenuEvent extends Equatable {
  const MenuEvent();

  @override
  List<Object> get props => [];
}

class FetchUserData extends MenuEvent {}

class FetchNotificationCounts extends MenuEvent {}

class SignOut extends MenuEvent {}

class DeleteAccount extends MenuEvent {
  final String password;

  const DeleteAccount(this.password);

  @override
  List<Object> get props => [password];
}

class RefreshData extends MenuEvent {}
part of 'menu_bloc.dart';

abstract class MenuState extends Equatable {
  const MenuState();

  String? get userName => null;
  String? get userId => null;
  String? get email => null;
  String? get aboutMe => null;
  String? get photoUrl => null;
  int? get pendingMessagesCount => null;
  int? get friendRequestsCount => null;

  @override
  List<Object?> get props => [
    userName,
    userId,
    email,
    aboutMe,
    photoUrl,
    pendingMessagesCount,
    friendRequestsCount,
  ];
}

class MenuInitial extends MenuState {}

class MenuLoading extends MenuState {}

class MenuLoaded extends MenuState {
  @override
  final String? userName;
  @override
  final String? userId;
  @override
  final String? email;
  @override
  final String? aboutMe;
  @override
  final String? photoUrl;
  @override
  final int? pendingMessagesCount;
  @override
  final int? friendRequestsCount;

  const MenuLoaded({
    this.userName,
    this.userId,
    this.email,
    this.aboutMe,
    this.photoUrl,
    this.pendingMessagesCount,
    this.friendRequestsCount,
  });

  @override
  List<Object?> get props => [
    userName,
    userId,
    email,
    aboutMe,
    photoUrl,
    pendingMessagesCount,
    friendRequestsCount,
  ];
}

class MenuError extends MenuState {
  final String message;

  const MenuError(this.message);

  @override
  List<Object?> get props => [message];
}

class AccountSignOutSuccess extends MenuState {}

class AccountDeletionSuccess extends MenuState {}
import 'package:flutter/material.dart';
import 'package:messenger_clone/features/chat/model/group_message.dart';
import 'package:messenger_clone/features/chat/model/user.dart';
import 'package:messenger_clone/features/messages/pages/messages_page.dart';
import 'package:page_transition/page_transition.dart';

class Routes {
  static const String welcome = "home";
  static const String chat = "chat";
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case chat:
        if (settings.arguments is GroupMessage) {
          final GroupMessage groupMessage = settings.arguments as GroupMessage;
          return PageTransition(
            type: PageTransitionType.rightToLeft,
            settings: settings,
            child: MessagesPage(groupMessage: groupMessage),
          );
        } else if (settings.arguments is User) {
          final User user = settings.arguments as User;
          return PageTransition(
            type: PageTransitionType.rightToLeft,
            settings: settings,
            child: MessagesPage(otherUsers: [user]),
          );
        } else if (settings.arguments is List<User>) {
          final List<User> argumentsList = settings.arguments as List<User>;
          if (argumentsList.isNotEmpty) {
            final List<User> users = argumentsList;
            return PageTransition(
              type: PageTransitionType.rightToLeft,
              settings: settings,
              child: MessagesPage(otherUsers: users),
            );
          }
        }
        return PageTransition(
          type: PageTransitionType.rightToLeft,
          settings: settings,
          child: const Scaffold(
            body: Center(child: Text('Invalid arguments for chat page')),
          ),
        );

      default:
        return MaterialPageRoute(
          builder:
              (context) => const Scaffold(
                body: Center(child: Text('No page route provided')),
              ),
        );
    }
  }
}

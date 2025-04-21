import 'package:flutter/material.dart';
import 'package:messenger_clone/features/chat/model/user.dart';
import 'package:messenger_clone/features/messages/pages/messages_page.dart';
import 'package:page_transition/page_transition.dart';

class Routes {
  static const String welcome = "home";
  static const String chat = "chat";
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case chat:
        if (settings.arguments is! User) {
          return MaterialPageRoute(
            builder:
                (context) => const Scaffold(
                  body: Center(
                    child: Text('Error: Missing or invalid User argument'),
                  ),
                ),
          );
        }
        final User user = settings.arguments as User;
        return PageTransition(
          type: PageTransitionType.rightToLeft,
          settings: settings,
          child: MessagesPage(other: user),
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

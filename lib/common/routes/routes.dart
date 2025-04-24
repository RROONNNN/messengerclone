import 'package:flutter/material.dart';

class Routes {
  static const String welcome = "home";

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
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

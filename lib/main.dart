import 'package:flutter/material.dart';
import 'package:messenger_clone/features/main_page/main.dart';
import 'package:provider/provider.dart';

import 'common/extensions/custom_theme_extension.dart';
import 'common/routes/routes.dart';
import 'common/themes/theme_provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MessengerClone(),
    ),
  );
}

class MessengerClone extends StatefulWidget {
  const MessengerClone({super.key});

  @override
  State<MessengerClone> createState() => _MessengerCloneState();
}

class _MessengerCloneState extends State<MessengerClone> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeNotifier.value,
      onGenerateRoute: Routes.onGenerateRoute,
      theme: lightTheme,
      darkTheme: darkTheme,
      home: const MainPage(),
    );
  }
}

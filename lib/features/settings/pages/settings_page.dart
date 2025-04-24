import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../common/extensions/custom_theme_extension.dart';
import '../../../common/themes/theme_provider.dart';
import '../../../common/widgets/custom_text_style.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String avatar = "";

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: context.theme.bg,
      appBar: AppBar(
        title: const TitleText("Settings"),
        backgroundColor: context.theme.appBar,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () {
                themeProvider.setTheme(ThemeMode.light);
              },
              child: const Text('Light Theme'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                themeProvider.setTheme(ThemeMode.dark);
              },
              child: const Text('Dark Theme'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                themeProvider.setTheme(ThemeMode.system);
              },
              child: const Text('Setting'),
            ),
          ],
        ),
      ),
    );
  }
}

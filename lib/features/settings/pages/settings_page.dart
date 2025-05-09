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
  String avatar = ""; // Giữ nguyên biến, dù không dùng

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final ThemeMode themeMode = themeProvider.themeNotifier.value;

    bool isDarkMode;
    switch (themeMode) {
      case ThemeMode.dark:
        isDarkMode = true;
        break;
      case ThemeMode.light:
        isDarkMode = false;
        break;
      case ThemeMode.system:
        isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;
        break;
    }

    Color containerBackgroundColor = isDarkMode
        ? const Color.fromARGB(255, 46, 45, 45)
        : Colors.grey[200]!;

    Color iconColor = isDarkMode ? Colors.white.withOpacity(0.7) : Colors.grey[700]!;

    return Scaffold(
      backgroundColor: context.theme.bg,
      appBar: AppBar(
        title: const TitleText("Settings"),
        backgroundColor: context.theme.appBar,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tiêu đề và mô tả
                Text(
                  "Cài đặt",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: context.theme.textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Tùy chỉnh ứng dụng theo sở thích của bạn",
                  style: TextStyle(
                    fontSize: 16,
                    color: context.theme.textColor.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 24),

                // Container Theme
                Container(
                  decoration: BoxDecoration(
                    color: containerBackgroundColor,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildThemeItem(
                        context,
                        icon: Icons.wb_sunny,
                        title: 'Light Theme',
                        iconColor: iconColor,
                        onTap: () {
                          themeProvider.setTheme(ThemeMode.light);
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 72.0),
                        child: Divider(
                          color: context.theme.textColor.withOpacity(0.3),
                          thickness: 0.5,
                        ),
                      ),
                      _buildThemeItem(
                        context,
                        icon: Icons.nightlight_round,
                        title: 'Dark Theme',
                        iconColor: iconColor,
                        onTap: () {
                          themeProvider.setTheme(ThemeMode.dark);
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 72.0),
                        child: Divider(
                          color: context.theme.textColor.withOpacity(0.3),
                          thickness: 0.5,
                        ),
                      ),
                      _buildThemeItem(
                        context,
                        icon: Icons.settings_system_daydream,
                        title: 'Account', // Đổi thành "Account"
                        iconColor: iconColor,
                        onTap: () {
                          themeProvider.setTheme(ThemeMode.system);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThemeItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: context.theme.textColor,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: iconColor,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
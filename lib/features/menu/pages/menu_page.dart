import 'package:flutter/material.dart';
import 'package:messenger_clone/common/extensions/custom_theme_extension.dart';
import 'package:messenger_clone/common/widgets/custom_text_style.dart';
import 'package:messenger_clone/features/auth/pages/login_screen.dart';
import 'package:messenger_clone/features/settings/pages/settings_page.dart';
import '../../../common/services/app_write_service.dart';
import '../../../common/widgets/dialog/loading_dialog.dart';

class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.bg,
      appBar: AppBar(
        title: const TitleText("Menu Page"),
        backgroundColor: context.theme.appBar,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const ContentText("Menu Page"),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                );
              },
              child: const Text('System Theme'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) =>
                  const LoadingDialog(
                    message: "Đang đăng xuất...",
                  ),
                );
                try {
                  await AppWriteService.signOut();
                  Navigator.of(context).pop();
                  Navigator.pushAndRemoveUntil(
                    context ,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                    (route) => false,
                  );
                } catch (e) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Logout failed: $e')),
                  );
                }
              },
              child: const Text('LogOut'),
            ),
          ],
        ),
      ),
    );
  }
}
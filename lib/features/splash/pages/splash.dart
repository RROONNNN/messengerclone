import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:messenger_clone/features/main_page/main_page.dart';

import '../../../common/services/auth_service.dart';
import '../../../common/widgets/dialog/custom_alert_dialog.dart';
import '../../auth/pages/login_screen.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    redirect();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image.asset(
          "assets/images/aeck_logo.png",
          width: MediaQuery.of(context).size.width * 0.6,
        ),
      ),
    );
  }

  Future<void> redirect() async {
    await Future.delayed(const Duration(seconds: 1));
    try {
      final currentUser = await AuthService.getCurrentUser();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder:
              (BuildContext context) =>
                  currentUser != null ? MainPage() : LoginScreen(),
        ),
            (route) => false
        ,
      );
    } catch (e) {
      await CustomAlertDialog.show(
        context: context,
        title: "Error System",
        message: "An error occurred : $e.",
      );
      SystemNavigator.pop();
    }
  }
}

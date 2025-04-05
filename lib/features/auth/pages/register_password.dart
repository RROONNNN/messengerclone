import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:messenger_clone/features/auth/pages/confirmation_code_screen.dart';

import '../../../common/services/app_write_service.dart';
import '../../../common/services/store.dart';
import '../../../common/widgets/dialog/custom_alert_dialog.dart';
import '../../../common/widgets/dialog/loading_dialog.dart';
import 'login_screen.dart';

class CreatePasswordScreen extends StatefulWidget {
  const CreatePasswordScreen({super.key});

  @override
  State<CreatePasswordScreen> createState() => _CreatePasswordScreenState();
}

class _CreatePasswordScreenState extends State<CreatePasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  String? _passwordError;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF162127),
      appBar: AppBar(
        backgroundColor: const Color(0xFF162127),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () async {
            final email = await Store.getEmailRegistered();
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context)  => ConfirmationCodeScreen(
                        email: email)
                ));
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              "Create a password",
              style: TextStyle(
                fontSize: 29,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Create a password with at least 8 characters including letters and numbers . It should be something others can't guess .",
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 40),
            TextField(
              controller: _passwordController,
              obscureText: false,
              decoration: InputDecoration(
                labelText: 'Password',
                isDense: true,
                labelStyle: TextStyle(
                    color: _passwordError != null ? Colors.red
                        : const Color(0xFF9eabb3)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: Colors.blue),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
                errorText: _passwordError,
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_passwordError != null)
                      const Icon(Icons.error, color: Colors.red),
                  ],
                ),
                errorStyle: const TextStyle(color: Colors.red),
              ),
              style: const TextStyle(
                color: Colors.white,
              ),
              onChanged: (value) {
                setState(() {
                  _passwordError = null;
                });
              },
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  _validatePassword();
                  if (_passwordError == null) {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const LoadingDialog(
                        message: "Đang tao tai khoan...",
                      ),
                    );

                    try {
                      await AppWriteService.signUp(
                        email: await Store.getEmailRegistered(),
                        password: _passwordController.text,
                        name: await Store.getNameRegistered(),
                      );

                      Navigator.of(context).pop();

                      await CustomAlertDialog.show(
                        context: context,
                        title: "Thành công",
                        message: "Tài khoản đã được tạo thành công.",
                      );

                      await Store.setEmailRegistered("");
                      await Store.setNameRegistered("");

                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => LoginScreen()),
                        (route) => false,
                      );

                    } on AppwriteException catch (e) {
                      Navigator.of(context).pop();

                      String errorMessage = "Lỗi khi tạo tài khoản";
                      if (e.code == 409) {
                        errorMessage = "Email đã được đăng ký";
                      } else if (e.code == 400) {
                        errorMessage = "Thông tin không hợp lệ";
                      }

                      await CustomAlertDialog.show(
                        context: context,
                        title: "Lỗi",
                        message: errorMessage,
                      );

                    } catch (e) {
                      Navigator.of(context).pop();
                      await CustomAlertDialog.show(
                        context: context,
                        title: "Lỗi ",
                        message: "Đã xảy ra lỗi không mong muốn : ${e.toString()}",
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'Next',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const Spacer(),
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                  );
                },
                child: const Text(
                  'I already have an account',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.blue,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
  void _validatePassword() {
    setState(() {
      if (_passwordController.text.isEmpty) {
        _passwordError = 'Password cannot be empty.';
      } else if (_passwordController.text.length <= 8) {
        _passwordError = 'Password must be greater than 8 characters long.';
      } else if (!_isStrongPassword(_passwordController.text)) {
        _passwordError =
        'Password must contain at least one uppercase letter, one lowercase letter, and one number.';
      } else {
        _passwordError = null;
      }
    });
  }

  bool _isStrongPassword(String password) {
    bool hasUpperCase = password.contains(RegExp(r'[A-Z]'));
    bool hasLowerCase = password.contains(RegExp(r'[a-z]'));
    bool hasNumber = password.contains(RegExp(r'[0-9]'));
    return hasUpperCase && hasLowerCase && hasNumber;
  }
}
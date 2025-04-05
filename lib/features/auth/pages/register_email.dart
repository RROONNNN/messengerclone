import 'package:flutter/material.dart';
import 'package:messenger_clone/common/services/opt_email_service.dart';

import '../../../common/services/app_write_service.dart';
import '../../../common/widgets/dialog/custom_alert_dialog.dart';
import '../../../common/widgets/dialog/loading_dialog.dart';
import 'confirmation_code_screen.dart';
import 'login_screen.dart';

class EmailInputScreen extends StatefulWidget {
  const EmailInputScreen({super.key});

  @override
  State<EmailInputScreen> createState() => _EmailInputScreenState();
}

class _EmailInputScreenState extends State<EmailInputScreen> {
  final TextEditingController _emailController = TextEditingController();
  String? _emailError;

  void _validateInputs() {
    setState(() {
      _emailError = _emailController.text.isEmpty ? 'Please enter your email' : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF162127),
      appBar: AppBar(
        backgroundColor: const Color(0xFF162127),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              "What's your email ?",
              style: TextStyle(
                fontSize: 29,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Enter the email where you can be contacted . No one will see this on your profile .",
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                isDense: true,
                labelStyle: TextStyle(
                  color:   _emailError != null ? Colors.red : Color(0xFF9eabb3)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: Colors.blue),
                ),
                errorText: _emailError,
                suffixIcon: _emailError != null
                    ? const Icon(Icons.error, color: Colors.red)
                    : null,
                errorStyle: const TextStyle(color: Colors.red),
                contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
              ),
              style: const TextStyle(
                color: Colors.white,
              ),
              onChanged: (value) {
                setState(() {
                  _emailError = null;
                });
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: ()  async {
                  _validateInputs();
                  if (_emailController.text.isNotEmpty) {
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_emailController.text)) {
                      await CustomAlertDialog.show(
                        context: context,
                        title: "Email không hợp lệ",
                        message: "Vui lòng nhập đúng định dạng email",
                      );
                      return;
                    }
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const LoadingDialog(
                        message: "Đang kiem tra email...",
                      ),
                    );
                    try {
                      final isRegistered = await AppWriteService.isEmailRegistered(_emailController.text);
                      Navigator.of(context).pop();
                      if (isRegistered) {
                        await CustomAlertDialog.show(
                          context: context,
                          title: "Email đã tồn tại",
                          message: "Email này đã được đăng ký. Vui lòng sử dụng email khác.",
                        );
                      } else {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => const LoadingDialog(
                            message: "Đang gửi OTP...",
                          ),
                        );
                        final otp = OTPEmailService.generateOTP();
                        await OTPEmailService.sendOTPEmail(_emailController.text, otp);
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ConfirmationCodeScreen(email: _emailController.text),
                          ),
                              (route) => false,
                        );
                      }
                    } catch (e) {
                      Navigator.of(context).pop();
                      await CustomAlertDialog.show(
                        context: context,
                        title: "Lỗi hệ thống",
                        message: "Không thể kiểm tra email. Vui lòng thử lại sau.",
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
            const SizedBox(height: 16),
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
}
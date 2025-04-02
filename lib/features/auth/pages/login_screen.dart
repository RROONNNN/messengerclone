import 'package:flutter/material.dart';
import 'package:messenger_clone/features/auth/pages/register_name.dart';
import 'package:messenger_clone/features/main_page/main_page.dart';

import '../../../common/services/app_write_service.dart';
import '../../../common/services/opt_email_service.dart';
import '../../../common/widgets/dialog/custom_alert_dialog.dart';
import '../../../common/widgets/dialog/loading_dialog.dart';
import 'confirmation_code_screen.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() =>LoginScreenState();
}


class LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _obscurePassword = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF162127),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SizedBox(height: 150),
            Image.asset(
              "assets/images/logo.png",
              width: 80,
              height: 80,
              fit: BoxFit.contain,
            ),
            SizedBox(height: 100),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Enter your email address',
                isDense: true,
                labelStyle: TextStyle(color: Color(0xFF9eabb3)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: Colors.blue),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 20),
              ),
              style: TextStyle(
                color: Colors.white ,
              ),
            ),
            SizedBox(height: 15),
            TextField(
              controller: passwordController,
              obscureText: _obscurePassword ? false : true,
              decoration: InputDecoration(
                labelText: 'Enter your password',
                labelStyle: TextStyle(color:  Color(0xFF9eabb3)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: Colors.blue),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 20),
                suffixIcon: IconButton(
                  icon:  Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              style: TextStyle(
                color: Colors.white ,
              ),
            ),
            SizedBox(height: 20),
            // Login Button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  if(emailController.text.isEmpty || passwordController.text.isEmpty){
                    await CustomAlertDialog.show(
                      context: context,
                      title: "Cảnh báo",
                      message: "Vui lòng nhập đầy đủ thông tin.",
                    );
                  } else {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const LoadingDialog(
                        message: "Đang đăng nhập...",
                      ),
                    );
                    try {
                      await AppWriteService.signIn(
                        email: emailController.text,
                        password: passwordController.text,
                      );
                      final String? userID = await AppWriteService
                          .getCurrentUserId();
                      if (userID == null) {
                        throw Exception('Không thể lấy thông tin người dùng');
                      }
                      bool check = await AppWriteService
                          .hasUserLoggedInFromThisDevice(userID);
                      if (check) {
                        await AppWriteService.saveLoginDeviceInfo(userID);
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (context) => MainPage()),
                            (route) => false
                        );
                      } else {
                        await AppWriteService.signOut();
                        final otp = OTPEmailService.generateOTP();
                        debugPrint('OTP: $otp');
                        await OTPEmailService.sendOTPEmail(emailController.text, otp);
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ConfirmationCodeScreen(
                                email: emailController.text ,
                                nextScreen: () => MainPage(),
                                action: () async {
                                  await AppWriteService.signIn(
                                    email: emailController.text,
                                    password: passwordController.text,
                                  );
                                  final String? userID = await AppWriteService
                                      .getCurrentUserId();
                                  if (userID == null) {
                                    throw Exception('Không thể lấy thông tin người dùng');
                                  }
                                  await AppWriteService.saveLoginDeviceInfo(userID);
                                },
                            ),
                          ),
                              (route) => false,
                        );
                      }
                    }  catch (e) {
                      try {
                        await AppWriteService.signOut();
                        Navigator.of(context).pop();
                        debugPrint(e.toString());
                        await CustomAlertDialog.show(
                          context: context,
                          title: "Lỗi đăng nhập",
                          message: "Đã có lỗi xảy ra : $e",
                        );
                      }
                      catch(e) {
                        Navigator.of(context).pop();
                        debugPrint(e.toString());
                        await CustomAlertDialog.show(
                          context: context,
                          title: "Lỗi đăng nhập",
                          message: "Sai email hoac mat khau",
                        );
                      }
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text('Login',
                    style: TextStyle(
                        color: Colors.white ,
                        fontSize: 20)),
              ),
            ),
            SizedBox(height: 10),
            GestureDetector(
              onTap: () {},
              child: Center(
                child: Text(
                  'Forgot your password ?',
                  style: TextStyle(color: Colors.white , fontSize: 20),
                ),
              ),
            ),
            SizedBox(height: 20),
            Spacer(),
            SizedBox(height: 20),
            SizedBox(
              height: 50,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => NameInputScreen()),
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.blue),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  'Create new account',
                  style: TextStyle(
                      color: Colors.blue ,
                      fontSize: 18
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:messenger_clone/common/services/auth_service.dart';
import 'package:messenger_clone/common/services/device_service.dart';
import 'package:messenger_clone/common/services/hive_service.dart';
import 'package:messenger_clone/features/auth/pages/register_name.dart';
import 'package:messenger_clone/features/main_page/main_page.dart';
import '../../../common/services/opt_email_service.dart';
import '../../../common/widgets/dialog/custom_alert_dialog.dart';
import '../../../common/widgets/dialog/loading_dialog.dart';
import 'confirmation_code_screen.dart';
import 'forgot_password.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = false;

  @override
  void initState() {
    _emailController.text = "hvnguyen902993@gmail.com";
    _passwordController.text = "123456789R@n";
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF162127),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SizedBox(height: MediaQuery
                .of(context)
                .size
                .height * 0.1),
            Image.asset(
              "assets/images/logo.png",
              width: 80,
              height: 80,
              fit: BoxFit.contain,
            ),
            SizedBox(height: MediaQuery
                .of(context)
                .size
                .height * 0.07),
            TextField(
              controller: _emailController,
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
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 20,
                ),
              ),
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(height: 15),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword ? false : true,
              decoration: InputDecoration(
                labelText: 'Enter your password',
                labelStyle: TextStyle(color: Color(0xFF9eabb3)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: Colors.blue),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 20,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
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
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(height: 20),
            // Login Button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  if (_emailController.text.isEmpty ||
                      _passwordController.text.isEmpty) {
                    await CustomAlertDialog.show(
                      context: context,
                      title: "Warning",
                      message: "Please enter complete information.",
                    );
                  } else if (!RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                  ).hasMatch(_emailController.text) ||
                      _passwordController.text.length <= 8) {
                    await CustomAlertDialog.show(
                      context: context,
                      title: "Login error",
                      message: "Wrong email or password.",
                    );
                  } else {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder:
                          (context) =>
                      const LoadingDialog(message: "Logging in..."),
                    );
                    try {
                      debugPrint('login');
                      final String? userID =
                      await AuthService.getUserIdFromEmailAndPassword(
                        _emailController.text,
                        _passwordController.text,
                      );
                      debugPrint('userID: $userID');
                      if (userID == null) {
                        if (!context.mounted) return;
                        Navigator.of(context).pop();
                        await CustomAlertDialog.show(
                          context: context,
                          title: "Login error",
                          message: "Wrong email or password.",
                        );
                      } else {
                        bool check =
                        await DeviceService.hasUserLoggedInFromThisDevice(
                          userID,
                        );
                        debugPrint('check: $check');
                        if (check) {
                          await AuthService.signIn(
                            email: _emailController.text,
                            password: _passwordController.text,
                          );
                          await DeviceService.saveLoginDeviceInfo(userID);
                          if (!context.mounted) return;
                          while (true) {
                            final currentUser =  await AuthService.isLoggedIn();
                            if (currentUser != null) {
                              debugPrint('currentUser: $currentUser');
                              HiveService.instance.saveCurrentUserId(userID);
                              if (context.mounted) {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(builder: (context) => MainPage()),
                                    (route) => false,
                                );
                              }
                              break;
                            }
                            else {
                              debugPrint('delay 1s');
                              await Future.delayed(const Duration(seconds: 1));
                            }
                          }
                        } else {
                          final otp = OTPEmailService.generateOTP();
                          debugPrint('OTP: $otp');
                          await OTPEmailService.sendOTPEmail(
                            _emailController.text,
                            otp,
                          );
                          if (!context.mounted) return;
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                  ConfirmationCodeScreen(
                                    email: _emailController.text,
                                    nextScreen: () => MainPage(),
                                    action: () async {
                                      String? isLogin ;
                                      while(isLogin == null) {
                                        isLogin = await AuthService.isLoggedIn();
                                      }
                                      debugPrint('isLogin: $isLogin');
                                      HiveService.instance.saveCurrentUserId(userID);
                                      // đảm bảo đã đăng nhập
                                      await AuthService.signIn(
                                        email: _emailController.text,
                                        password: _passwordController.text,
                                      );
                                      await DeviceService.saveLoginDeviceInfo(
                                        userID,
                                      );
                                    },
                                  ),
                            ),
                                (route) => false,
                          );
                        }
                      }
                    } catch (e) {
                      if (e.toString().contains('No internet connection')) {
                        if (!context.mounted) return;
                        Navigator.of(context).pop();
                        await CustomAlertDialog.show(
                          context: context,
                          title: "Login error",
                          message: "No network connection",
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
                child: Text(
                  'Login',
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
              ),
            ),
            SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ForgotPasswordScreen()),
                );
              },
              child: const Center(
                child: Text(
                  'Forgot your password?',
                  style: TextStyle(color: Colors.white, fontSize: 20),
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
                  style: TextStyle(color: Colors.blue, fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:messenger_clone/common/extensions/custom_theme_extension.dart';
import 'package:messenger_clone/common/widgets/custom_text_style.dart';
import 'package:messenger_clone/features/auth/pages/login_screen.dart';
import 'package:messenger_clone/features/meta_ai/pages/meta_ai_page.dart';
import 'package:messenger_clone/features/settings/pages/settings_page.dart';
import 'package:messenger_clone/common/services/app_write_service.dart';
import 'package:messenger_clone/common/widgets/dialog/loading_dialog.dart';
import 'package:provider/provider.dart'; // Thêm import Provider
import 'package:messenger_clone/common/themes/theme_provider.dart'; // Thêm import ThemeProvider

class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  Future<bool> _showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'OK',
    String cancelText = 'Hủy',
  }) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF162127)
                  : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              title: Text(
                title,
                style: TextStyle(
                  color: context.theme.textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Text(
                message,
                style: TextStyle(
                  color: context.theme.textColor,
                  fontSize: 16,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                  child: Text(
                    cancelText,
                    style: TextStyle(
                      color: context.theme.textColor.withOpacity(0.7),
                      fontSize: 16,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                  child: Text(
                    confirmText,
                    style: TextStyle(
                      color: context.theme.blue,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<void> _executeWithLoading({
    required BuildContext context,
    required Future<void> Function() action,
    required String loadingMessage,
    required String errorMessage,
    VoidCallback? onSuccess,
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => LoadingDialog(message: loadingMessage),
    );
    try {
      await action();
      Navigator.of(context).pop();
      if (onSuccess != null) onSuccess();
    } catch (e) {
      Navigator.of(context).pop();
      String detailedError = errorMessage;
      if (e.toString().contains('network')) {
        detailedError = 'Lỗi kết nối mạng. Vui lòng kiểm tra kết nối của bạn.';
      } else if (e.toString().contains('unauthorized')) {
        detailedError = 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
      }
      await _showConfirmationDialog(
        context: context,
        title: 'Lỗi',
        message: detailedError,
        confirmText: 'Đóng',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Lấy ThemeMode từ ThemeProvider
    final themeProvider = Provider.of<ThemeProvider>(context);
    final ThemeMode themeMode = themeProvider.themeNotifier.value;

    // Xác định chế độ dark/light dựa trên ThemeMode
    bool isDarkMode;
    switch (themeMode) {
      case ThemeMode.dark:
        isDarkMode = true;
        break;
      case ThemeMode.light:
        isDarkMode = false;
        break;
      case ThemeMode.system:
        // Nếu là system, kiểm tra độ sáng hệ thống
        isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;
        break;
    }

    // Định nghĩa màu nền dựa trên isDarkMode
    Color containerBackgroundColor = isDarkMode
        ? const Color.fromARGB(255, 46, 45, 45)
        : Colors.grey[200]!;

    return Scaffold(
      backgroundColor: context.theme.bg,
      appBar: AppBar(
        backgroundColor: context.theme.bg,
        elevation: 0,
        title: const TitleText("Menu"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Vùng 1: Nguyễn Minh Thuận và Cài đặt
                Container(
                  decoration: BoxDecoration(
                    color: containerBackgroundColor,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundImage: NetworkImage(
                                'https://picsum.photos/100?random=${'Nguyen Minh Thuan'.hashCode}',
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Nguyễn Minh Thuận',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: context.theme.textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Chuyện trang cá nhân',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: context.theme.textColor.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.edit,
                                color: context.theme.textColor.withOpacity(0.7),
                                size: 20,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const MetaAiPage(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 72.0),
                        child: Divider(
                          color: context.theme.textColor.withOpacity(0.3),
                          thickness: 0.5,
                        ),
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.settings,
                        title: 'Cài đặt',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SettingsPage()),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Vùng 2: Marketplace, Tin nhắn dạng chó, Kho lưu trữ
                Container(
                  decoration: BoxDecoration(
                    color: containerBackgroundColor,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      _buildMenuItem(
                        context,
                        icon: Icons.store,
                        title: 'Marketplace',
                        onTap: () {},
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 72.0),
                        child: Divider(
                          color: context.theme.textColor.withOpacity(0.3),
                          thickness: 0.5,
                        ),
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.message,
                        title: 'Tin nhắn đang chờ',
                        onTap: () {},
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 72.0),
                        child: Divider(
                          color: context.theme.textColor.withOpacity(0.3),
                          thickness: 0.5,
                        ),
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.archive,
                        title: 'Kho lưu trữ',
                        onTap: () {},
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Vùng 3: Lời mời kết bạn và Tạo AI
                Container(
                  decoration: BoxDecoration(
                    color: containerBackgroundColor,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      _buildMenuItem(
                        context,
                        icon: Icons.group_add,
                        title: 'Lời mời kết bạn',
                        onTap: () {},
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 72.0),
                        child: Divider(
                          color: context.theme.textColor.withOpacity(0.3),
                          thickness: 0.5,
                        ),
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.add_circle_outline,
                        title: 'Tạo AI',
                        onTap: () {},
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Vùng 4: Tạo cộng đồng
                Container(
                  decoration: BoxDecoration(
                    color: containerBackgroundColor,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Cộng đồng',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: context.theme.textColor.withOpacity(0.7),
                            ),
                          ),
                        ),
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.add_circle_outline,
                        title: 'Tạo cộng đồng',
                        onTap: () {},
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Vùng 5: Nhóm Facebook
                Container(
                  decoration: BoxDecoration(
                    color: containerBackgroundColor,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Nhóm Facebook',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: context.theme.textColor.withOpacity(0.7),
                            ),
                          ),
                        ),
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.group,
                        title: 'DUT - Đại Học Bách Khoa Đà Nẵng',
                        onTap: () {},
                        leadingImage: 'https://picsum.photos/50?random=${'Dự Án'.hashCode}',
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 72.0),
                        child: Divider(
                          color: context.theme.textColor.withOpacity(0.3),
                          thickness: 0.5,
                        ),
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.group,
                        title: 'Backend & Frontend Developer Vie...',
                        onTap: () {},
                        leadingImage: 'https://picsum.photos/50?random=${'Backend'.hashCode}',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Vùng 6: Đăng xuất và Xóa tài khoản
                Container(
                  decoration: BoxDecoration(
                    color: containerBackgroundColor,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      _buildMenuItem(
                        context,
                        icon: Icons.logout,
                        title: 'Đăng xuất',
                        onTap: () async {
                          final confirm = await _showConfirmationDialog(
                            context: context,
                            title: 'Xác nhận',
                            message: 'Bạn có chắc chắn muốn đăng xuất?',
                            confirmText: 'Đăng xuất',
                            cancelText: 'Hủy',
                          );
                          if (confirm) {
                            await _executeWithLoading(
                              context: context,
                              action: () async => await AppWriteService.signOut(),
                              loadingMessage: 'Đang đăng xuất...',
                              errorMessage: 'Đăng xuất thất bại.',
                              onSuccess: () {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                                  (route) => false,
                                );
                              },
                            );
                          }
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 72.0),
                        child: Divider(
                          color: context.theme.textColor.withOpacity(0.3),
                          thickness: 0.5,
                        ),
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.delete_forever,
                        title: 'Xóa tài khoản',
                        onTap: () async {
                          final confirm = await _showConfirmationDialog(
                            context: context,
                            title: 'Xác nhận',
                            message: 'Bạn có chắc chắn muốn xóa tài khoản? Hành động này không thể hoàn tác.',
                            confirmText: 'Xóa',
                            cancelText: 'Hủy',
                          );
                          if (confirm) {
                            await _executeWithLoading(
                              context: context,
                              action: () async => await AppWriteService.deleteAccount(),
                              loadingMessage: 'Đang xóa tài khoản...',
                              errorMessage: 'Xóa tài khoản thất bại.',
                              onSuccess: () async {
                                await _showConfirmationDialog(
                                  context: context,
                                  title: 'Thông báo',
                                  message: 'Yêu cầu đã được gửi đi. Tài khoản sẽ được xóa hoàn toàn sau ít phút.',
                                  confirmText: 'Đóng',
                                );
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                                  (route) => false,
                                );
                              },
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    String? leadingImage,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            const SizedBox(width: 16),
            leadingImage != null
                ? CircleAvatar(
                    radius: 20,
                    backgroundImage: NetworkImage(leadingImage),
                  )
                : Icon(
                    icon,
                    color: context.theme.textColor.withOpacity(0.7),
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
              color: context.theme.textColor.withOpacity(0.7),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}












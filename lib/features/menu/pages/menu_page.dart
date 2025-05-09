import 'package:flutter/material.dart';
import 'package:messenger_clone/common/extensions/custom_theme_extension.dart';
import 'package:messenger_clone/common/widgets/custom_text_style.dart';
import 'package:messenger_clone/features/auth/pages/login_screen.dart';
import 'package:messenger_clone/features/meta_ai/pages/meta_ai_page.dart';
import 'package:messenger_clone/features/settings/pages/settings_page.dart';
import 'package:messenger_clone/common/services/app_write_service.dart';
import '../dialog/dialog_utils.dart';
import 'edit_profile_page.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  String? userName;
  String? userId;
  String? email;
  String? aboutMe;
  String? photoUrl;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final result = await AppWriteService.fetchUserData();
    if (result.containsKey('error')) {
      setState(() {
        errorMessage = result['error'] as String?;
        isLoading = false;
      });
    } else {
      setState(() {
        userName = result['userName'] as String?;
        userId = result['userId'] as String?;
        email = result['email'] as String?;
        aboutMe = result['aboutMe'] as String?;
        photoUrl = result['photoUrl'] as String?;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.bg,
      appBar: AppBar(
        backgroundColor: context.theme.bg,
        elevation: 0,
        title: const TitleText(
          'Menu',
          fontSize: 25,
          fontWeight: FontWeight.bold,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildUserInfo(context),
                const SizedBox(height: 16),
                _buildMenuItem(context, icon: Icons.settings, title: 'Cài đặt', onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsPage()),
                  );
                }),
                _buildMenuItem(context, icon: Icons.chat_bubble, title: 'Tin nhắn đang chờ', onTap: () {}),
                _buildMenuItem(context, icon: Icons.archive, title: 'Kho lưu trữ', onTap: () {}),
                const SizedBox(height: 16),
                TitleText(
                  'Xem thêm',
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: context.theme.textColor.withOpacity(0.7),
                ),
                const SizedBox(height: 8),
                _buildMenuItem(context, icon: Icons.group, title: 'Lời mời kết bạn', onTap: () {}),
                _buildMenuItem(context, icon: Icons.group_add, title: 'Tìm bạn bè', onTap: () {}),
                _buildMenuItem(context, icon: Icons.star, title: 'Đoạn chat trong AI Studio', onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MetaAiPage()),
                  );
                }),
                TitleText(
                  'Vùng nguy hiểm',
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: context.theme.textColor.withOpacity(0.7),
                ),
                const SizedBox(height: 16),
                _buildMenuGroupActions(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfo(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (errorMessage != null) {
      return TitleText(
        errorMessage!,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: context.theme.red,
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: context.theme.grey,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: photoUrl != null
                  ? (photoUrl!.startsWith('http')
                  ? NetworkImage(photoUrl!)
                  : const AssetImage('assets/images/avatar.png') as ImageProvider)
                  : const AssetImage('assets/images/avatar.png'),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TitleText(
                    userName ?? 'Không có tên',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: context.theme.textColor,
                  ),
                  TitleText(
                    '@${userId ?? 'Không có ID'}',
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: context.theme.textColor.withOpacity(0.7),
                  ),
                  TitleText(
                    aboutMe ?? 'Ruby chan (>ω<)',
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: context.theme.textColor.withOpacity(0.7),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditProfilePage(
                      initialName: userName,
                      initialEmail: email,
                      initialAboutMe: aboutMe,
                      initialPhotoUrl: photoUrl,
                      userId: userId ?? '',
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
      BuildContext context, {
        required IconData icon,
        required String title,
        required VoidCallback onTap,
      }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Icon(
              icon,
              color: context.theme.textColor.withOpacity(0.7),
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TitleText(
                title,
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: context.theme.textColor,
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

  Widget _buildMenuGroupActions(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.theme.grey,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          _buildMenuItem(
            context,
            icon: Icons.logout,
            title: 'Đăng xuất',
            onTap: () async {
              final confirm = await DialogUtils.showConfirmationDialog(
                context: context,
                title: 'Xác nhận',
                message: 'Bạn có chắc chắn muốn đăng xuất?',
                confirmText: 'Đăng xuất',
                cancelText: 'Hủy',
              );
              if (confirm) {
                await DialogUtils.executeWithLoading(
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
              final confirm = await DialogUtils.showConfirmationDialog(
                context: context,
                title: 'Xác nhận',
                message: 'Bạn có chắc chắn muốn xóa tài khoản? Hành động này không thể hoàn tác.',
                confirmText: 'Xóa',
                cancelText: 'Hủy',
              );
              if (confirm) {
                await DialogUtils.executeWithLoading(
                  context: context,
                  action: () async => await AppWriteService.deleteAccount(),
                  loadingMessage: 'Đang xóa tài khoản...',
                  errorMessage: 'Xóa tài khoản thất bại.',
                  onSuccess: () async {
                    await DialogUtils.showConfirmationDialog(
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
    );
  }
}
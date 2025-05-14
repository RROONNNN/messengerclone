import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:messenger_clone/common/extensions/custom_theme_extension.dart';
import 'package:messenger_clone/common/services/user_service.dart';
import 'dart:io';
import 'package:messenger_clone/features/tin/widgets/story_item.dart';

import '../../../common/services/auth_service.dart';
import '../../../common/services/story_service.dart';

class StoryUploadPage extends StatefulWidget {
  final File? selectedImage;

  const StoryUploadPage({super.key, this.selectedImage});

  @override
  State<StoryUploadPage> createState() => _StoryUploadPageState();
}

class _StoryUploadPageState extends State<StoryUploadPage> {
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _selectedImage = widget.selectedImage;
  }

  Future<void> _pickMedia() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) setState(() => _selectedImage = File(pickedFile.path));
  }

  Future<void> _uploadStory() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ảnh trước khi đăng!')),
      );
      return;
    }
    final userId = await AuthService.isLoggedIn() ?? 'current_user';
    try {
      await StoryService.postStory(
        userId: userId,
        mediaFile: _selectedImage!,
        mediaType: 'image',
      );
      final newStory = StoryItem(
        userId: userId,
        title: 'Bạn',
        imageUrl: '',
        avatarUrl: (await UserService.fetchUserDataById(userId))['photoUrl'] as String? ?? '',
        isVideo: false,
        postedAt: DateTime.now(),
        totalStories: 1,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã đăng tin thành công!')),
        );
        Navigator.pop(context, newStory);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi khi tải lên: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: _selectedImage != null
                ? Image.file(_selectedImage!, fit: BoxFit.cover, width: double.infinity, height: double.infinity)
                : const Text('Chọn ảnh để bắt đầu', style: TextStyle(color: Colors.white, fontSize: 20)),
          ),
          Positioned(
            top: 40,
            left: 8,
            right: 8,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                IconButton(
                  icon: const Icon(Icons.photo_library, color: Colors.white),
                  onPressed: _pickMedia,
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              backgroundColor: context.theme.blue,
              elevation: 6,
              onPressed: _uploadStory,
              child: const Icon(Icons.send, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
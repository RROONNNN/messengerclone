import 'package:hive_flutter/adapters.dart';
import 'package:messenger_clone/common/services/app_write_service.dart';

class HiveService {
  static const String _CurrentUserBoxName = 'currentUserBox';
  late final Future<Box<String>> _box;
  HiveService() {
    _box = _initializeBox();
  }

  Future<Box<String>> _initializeBox() async {
    return await Hive.openBox<String>(_CurrentUserBoxName);
  }

  Future<void> saveCurrentUserId(String userId) async {
    final box = await _box;
    await box.put('currentUserId', userId);
  }

  Future<void> clearCurrentUserId() async {
    final box = await _box;
    await box.delete('currentUserId');
  }

  Future<String> getCurrentUserId() async {
    try {
      final box = await _box;
      return box.get('currentUserId') ??
          (await AppWriteService.getCurrentUser())!.$id;
    } catch (e) {
      print('Error getting current user ID: $e');
    }
    throw Exception('Failed to get current user ID');
  }
}

import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';

import 'auth_service.dart';

class HiveService {
  static final HiveService instance = HiveService._internal();
  late final Future<Box<String>> _box;

  factory HiveService() {
    return instance;
  }

  HiveService._internal() {
    _box = _initializeBox();
  }

  Future<Box<String>> _initializeBox() async {
    final box = await Hive.openBox<String>('currentUserBox');
    return box;
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
      final currentUser = await AuthService.isLoggedIn();
      return box.get('currentUserId') ??
          (currentUser ?? '');
    } catch (e) {
      debugPrint('Error getting current user ID: $e');
    }
    return '';
  }
}

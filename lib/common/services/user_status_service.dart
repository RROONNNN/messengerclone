import 'dart:async';

import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'app_write_config.dart';
import 'auth_service.dart';

class UserStatusService with WidgetsBindingObserver {
  static final UserStatusService _instance = UserStatusService._internal();
  factory UserStatusService() => _instance;

  final Client _client = Client()
      .setEndpoint(AppwriteConfig.endpoint)
      .setProject(AppwriteConfig.projectId);
  late final Databases _databases;
  Timer? _updateTimer;
  bool _isInitialized = false;

  UserStatusService._internal() {
    _databases = Databases(_client);
  }

  Future<void> initialize() async {
    if (_isInitialized) return;
    WidgetsBinding.instance.addObserver(this);
    _isInitialized = true;
    _startPeriodicUpdates();
  }

  void _startPeriodicUpdates() {
    _updateTimer = Timer.periodic(const Duration(seconds: 600), (timer) {
      _updateUserStatus(true);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _updateUserStatus(true);
        _startPeriodicUpdates();
        break;
      case AppLifecycleState.paused:
        _updateUserStatus(false);
        _updateTimer?.cancel();
        break;
      case AppLifecycleState.detached:
        _updateUserStatus(false);
        _updateTimer?.cancel();
        break;
      default:
        break;
    }
  }

  Future<void> _updateUserStatus(bool isActive) async {
    try {
      final currentUser = await AuthService.getCurrentUser();
      if (currentUser == null) return;

      await _databases.updateDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.userCollectionId,
        documentId: currentUser.$id,
        data: {
          'isActive': isActive,
          'lastSeen': DateTime.now().toUtc().toIso8601String(),
        },
      );
    } catch (e) {
      debugPrint('Error updating user status: $e');
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _updateTimer?.cancel();
    _updateUserStatus(false);
  }
}

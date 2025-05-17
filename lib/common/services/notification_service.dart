import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../features/messages/elements/call_page.dart';
import 'auth_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Xử lý thông báo nền: ${message.messageId}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  late final FlutterLocalNotificationsPlugin _localNotifications;
  late final FirebaseMessaging _firebaseMessaging;
  GlobalKey<NavigatorState>? navigatorKey;

  NotificationService._internal() {
    _localNotifications = FlutterLocalNotificationsPlugin();
    _firebaseMessaging = FirebaseMessaging.instance;
    initializeNotifications();
  }

  void setNavigatorKey(GlobalKey<NavigatorState> key) {
    navigatorKey = key;
  }

  Future<void> initializeNotifications() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    await _localNotifications.initialize(
      const InitializationSettings(
        android: androidSettings,
      ),
      onDidReceiveNotificationResponse: _handleNotificationResponse,
    );

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTapBackground);
  }

  void _handleNotificationResponse(NotificationResponse response) {
    debugPrint('Thông báo được nhấn: ${response.payload}, Hành động: ${response.actionId}');
    final payloadString = response.payload;
    if (payloadString != null) {
      try {
        final payload = Map<String, dynamic>.from(jsonDecode(payloadString));
        if (response.actionId == 'accept') {
          _navigateToCallPage(payload);
        } else if (response.actionId == 'reject') {
          debugPrint('Thông báo bị từ chối, đóng thông báo');
        }
      } catch (e) {
        debugPrint('Lỗi phân tích payload thông báo: $e');
      }
    }
  }

  void _handleNotificationTapBackground(RemoteMessage message) {
    debugPrint('Thông báo nền được nhấn: ${message.messageId}');
    _navigateToCallPage(message.data);
  }

  Future<void> _navigateToCallPage(Map<String, dynamic> payload) async {
    final currentUser = await AuthService.getCurrentUser();
    if (payload['type'] == 'video_call') {
      final callId = payload['callId'] as String? ?? '';
      final callerId = payload['callerId'] as String? ?? '';
      final callerName = payload['callerName'] as String? ?? 'Unknown Caller';
      final userId = currentUser?.$id ?? callerId ;

      if (callId.isNotEmpty && callerId.isNotEmpty && navigatorKey?.currentState != null) {
        navigatorKey!.currentState!.push(
          MaterialPageRoute(
            builder: (context) => CallPage(
              callID: callId,
              userID: userId,
              userName: currentUser?.name ?? 'Unknown User',
              callerName: callerName,
            ),
          ),
        );
      } else {
        debugPrint('Thiếu thông tin cuộc gọi hoặc navigatorKey không hợp lệ');
      }
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('Nhận thông báo tiền cảnh: ${message.messageId}');

    await _showLocalNotification(
      title: message.notification?.title ?? 'Thông báo mới',
      body: message.notification?.body ?? '',
      payload: jsonEncode(message.data),
    );
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'video_call_channel',
      'Kênh cuộc gọi video',
      importance: Importance.max,
      priority: Priority.high,
      actions: [
        AndroidNotificationAction(
          'accept',
          'Nhận cuộc gọi',
          showsUserInterface: true,
        ),
        AndroidNotificationAction(
          'reject',
          'Từ chối',
          cancelNotification: true,
        ),
      ],
    );

    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      const NotificationDetails(
        android: androidDetails,
      ),
      payload: payload,
    );
  }

  Future<String?> getFCMToken() async {
    return await _firebaseMessaging.getToken();
  }
}
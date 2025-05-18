import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:messenger_clone/common/routes/routes.dart';
import 'package:messenger_clone/features/chat/data/data_sources/remote/appwrite_repository.dart';
import 'package:messenger_clone/features/chat/model/group_message.dart';
import '../../features/messages/elements/call_page.dart';
import 'auth_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling background notification: ${message.messageId}');

  // Initialize the plugin for background context
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  String? type = message.data['type'];
  String title =
      message.notification?.title ??
      (type == 'video_call' ? 'Incoming Call' : 'New Message');
  String body = message.notification?.body ?? '';

  if (type == 'video_call') {
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

    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch,
      title,
      body,
      const NotificationDetails(android: androidDetails),
      payload: jsonEncode(message.data),
    );
  } else {
    const androidDetails = AndroidNotificationDetails(
      'message_channel',
      'Message Channel',
      importance: Importance.high,
      priority: Priority.high,
    );

    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch,
      title,
      body,
      const NotificationDetails(android: androidDetails),
      payload: jsonEncode(message.data),
    );
  }
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

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings),
      onDidReceiveNotificationResponse: _handleNotificationResponse,
    );

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(
      _handleNotificationTapBackground,
    );
  }

  void _handleNotificationResponse(NotificationResponse response) {
    debugPrint(
      'Thông báo được nhấn: ${response.payload}, Hành động: ${response.actionId}',
    );
    final payloadString = response.payload;
    if (payloadString != null) {
      try {
        final payload = Map<String, dynamic>.from(jsonDecode(payloadString));
        if (payload['type'] == 'video_call') {
          if (response.actionId == 'accept') {
            _navigateToCallPage(payload);
          } else if (response.actionId == 'reject') {
            debugPrint('Call notification rejected');
          }
        } else {
          // Handle message notification tap
          _navigateToMessagePage(payload);
        }
      } catch (e) {
        debugPrint('Lỗi phân tích payload thông báo: $e');
      }
    }
  }

  void _handleNotificationTapBackground(RemoteMessage message) {
    debugPrint('Background notification tapped: ${message.messageId}');
    if (message.data['type'] == 'video_call') {
      _navigateToCallPage(message.data);
    } else {
      _navigateToMessagePage(message.data);
    }
  }

  Future<void> _navigateToMessagePage(Map<String, dynamic> payload) async {
    if (navigatorKey?.currentState != null) {
      AppwriteRepository appwriteRepository = AppwriteRepository();
      GroupMessage groupMessage = await appwriteRepository.getGroupMessageById(
        payload['groupMessageId'],
      );
      navigatorKey!.currentState!.pushNamed(
        Routes.chat,
        arguments: groupMessage,
      );
    }
  }

  Future<void> _navigateToCallPage(Map<String, dynamic> payload) async {
    final currentUser = await AuthService.getCurrentUser();
    if (payload['type'] == 'video_call') {
      final callId = payload['callId'] as String? ?? '';
      final callerId = payload['callerId'] as String? ?? '';
      final callerName = payload['callerName'] as String? ?? 'Unknown Caller';
      final userId = currentUser?.$id ?? callerId;

      if (callId.isNotEmpty &&
          callerId.isNotEmpty &&
          navigatorKey?.currentState != null) {
        navigatorKey!.currentState!.push(
          MaterialPageRoute(
            builder:
                (context) => CallPage(
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

  //TODO:
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('Nhận thông báo tiền cảnh: ${message.messageId}');

    if (message.data['type'] == 'video_call') {
      await _showCallNotification(
        _localNotifications,
        message.notification?.title ?? 'Cuộc gọi đến',
        message.notification?.body ?? '',
        message.data,
      );
    } else {
      await _showMessageNotification(
        _localNotifications,
        message.notification?.title ?? 'Tin nhắn mới',
        message.notification?.body ?? '',
        message.data,
      );
    }
  }

  Future<void> _showCallNotification(
    FlutterLocalNotificationsPlugin notifications,
    String title,
    String body,
    Map<String, dynamic> payload,
  ) async {
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

    await notifications.show(
      DateTime.now().millisecond,
      title,
      body,
      const NotificationDetails(android: androidDetails),
      payload: jsonEncode(payload),
    );
  }

  Future<void> _showMessageNotification(
    FlutterLocalNotificationsPlugin notifications,
    String title,
    String body,
    Map<String, dynamic> payload,
  ) async {
    const androidDetails = AndroidNotificationDetails(
      'message_channel',
      'Message Channel',
      importance: Importance.high,
      priority: Priority.high,
    );

    await notifications.show(
      DateTime.now().millisecond,
      title,
      body,
      const NotificationDetails(android: androidDetails),
      payload: jsonEncode(payload),
    );
  }

  Future<String?> getFCMToken() async {
    return await _firebaseMessaging.getToken();
  }
}

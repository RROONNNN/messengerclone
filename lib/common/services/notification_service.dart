import 'dart:async';
import 'dart:convert';
import 'dart:math';
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

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  String? type = message.data['type'];
  String? callId = message.data['callId'];
  int notificationId =
      message.messageId?.hashCode ?? Random().nextInt(0x7FFFFFFF);

  if (type == 'call_ended' && callId != null) {
    await flutterLocalNotificationsPlugin.cancel(callId.hashCode);
    debugPrint('Cancelled call notification for callId: $callId');
    return;
  }

  String title =
      type == 'video_call'
          ? 'Cuộc gọi đến'
          : (message.notification?.title ?? 'New Message');
  String body =
      type == 'video_call'
          ? 'Từ ${message.data['callerName'] ?? 'Người gọi không xác định'}'
          : (message.notification?.body ?? '');

  if (type == 'video_call') {
    final androidDetails = AndroidNotificationDetails(
      'video_call_channel',
      'Kênh cuộc gọi video',
      importance: Importance.max,
      priority: Priority.high,
      color: const Color(0xFF4CAF50), // Green color
      fullScreenIntent: true, // Full-screen intent
      timeoutAfter: 30000, // Cancel after 30 seconds
      styleInformation: const BigTextStyleInformation(''), // Compact display
      actions: const [
        AndroidNotificationAction('accept', 'Nhận', showsUserInterface: true),
        AndroidNotificationAction(
          'reject',
          'Từ chối',
          cancelNotification: true,
        ),
      ],
    );

    await flutterLocalNotificationsPlugin.show(
      callId?.hashCode ?? notificationId,
      title,
      body,
      NotificationDetails(android: androidDetails),
      payload: jsonEncode({
        ...message.data,
        'notificationId': callId?.hashCode ?? notificationId,
      }),
    );
  } else {
    const androidDetails = AndroidNotificationDetails(
      'message_channel',
      'Message Channel',
      importance: Importance.high,
      priority: Priority.high,
    );

    await flutterLocalNotificationsPlugin.show(
      notificationId,
      title,
      body,
      const NotificationDetails(android: androidDetails),
      payload: jsonEncode({...message.data, 'notificationId': notificationId}),
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
  final Completer<void> _navigatorReady = Completer<void>();

  NotificationService._internal() {
    _localNotifications = FlutterLocalNotificationsPlugin();
    _firebaseMessaging = FirebaseMessaging.instance;
    _initializeFirebaseMessaging();
  }

  void setNavigatorKey(GlobalKey<NavigatorState> key) {
    navigatorKey = key;
    if (navigatorKey?.currentState != null && !_navigatorReady.isCompleted) {
      _navigatorReady.complete();
      debugPrint('NavigatorKey đã sẵn sàng');
    }
  }

  Future<void> _initializeFirebaseMessaging() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    debugPrint('Quyền thông báo: ${settings.authorizationStatus}');

    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
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

    RemoteMessage? initialMessage =
        await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint(
        'Handling initial message in terminated state: ${initialMessage.messageId}',
      );
      await _handleInitialMessage(initialMessage);
    } else {
      debugPrint('No initial message found');
    }

    Future.delayed(Duration(seconds: 5), () async {
      RemoteMessage? retryMessage =
          await _firebaseMessaging.getInitialMessage();
      if (retryMessage != null && navigatorKey?.currentState != null) {
        debugPrint('Retry handling initial message: ${retryMessage.messageId}');
        await _handleInitialMessage(retryMessage);
      }
    });

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(
      _handleNotificationTapBackground,
    );
  }

  void _handleNotificationResponse(NotificationResponse response) {
    debugPrint(
      'Thông báo được nhấn: ${response.payload}, Hành động: ${response.actionId}',
    );
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
            if (payload['notificationId'] != null) {
              _localNotifications.cancel(payload['notificationId']);
              debugPrint('Cancelled call notification on reject');
            }
          }
        } else {
          _navigateToMessagePage(payload);
        }
      } catch (e) {
        debugPrint('Lỗi phân tích payload thông báo: $e');
      }
    }
  }

  void _handleNotificationTapBackground(RemoteMessage message) {
    debugPrint('Background notification tapped: ${message.messageId}');
    if (message.data['type'] == 'call_ended') {
      if (message.data['callId'] != null) {
        _localNotifications.cancel(message.data['callId'].hashCode);
        debugPrint(
          'Cancelled call notification for callId: ${message.data['callId']}',
        );
      }
      return;
    }
    if (message.data['type'] == 'video_call') {
      _navigateToCallPage(message.data);
    } else {
      _navigateToMessagePage(message.data);
    }
  }

  Future<void> _handleInitialMessage(RemoteMessage message) async {
    debugPrint(
      'Processing initial message: ${message.messageId}, type: ${message.data['type']}, payload: ${message.data}',
    );

    if (!_navigatorReady.isCompleted) {
      debugPrint('Waiting for navigatorKey to be ready...');
      bool isReady = false;
      for (int i = 0; i < 40; i++) {
        if (navigatorKey?.currentState != null) {
          isReady = true;
          if (!_navigatorReady.isCompleted) {
            _navigatorReady.complete();
          }
          break;
        }
        await Future.delayed(Duration(milliseconds: 500));
        debugPrint('Retry $i: Waiting for navigatorKey...');
      }
      if (!isReady) {
        debugPrint('NavigatorKey không sẵn sàng sau 20 giây');
        return;
      }
    }

    if (message.data['type'] == 'call_ended') {
      if (message.data['callId'] != null) {
        _localNotifications.cancel(message.data['callId'].hashCode);
        debugPrint(
          'Cancelled call notification for callId: ${message.data['callId']}',
        );
      }
      return;
    }

    if (message.data['type'] == 'video_call') {
      debugPrint('Navigating to CallPage from terminated state');
      await _navigateToCallPage(message.data);
    } else {
      debugPrint('Navigating to MessagePage from terminated state');
      await _navigateToMessagePage(message.data);
    }
  }

  Future<void> _navigateToMessagePage(Map<String, dynamic> payload) async {
    if (navigatorKey?.currentState == null) {
      debugPrint('NavigatorKey chưa sẵn sàng để điều hướng đến trang tin nhắn');
      return;
    }

    try {
      AppwriteRepository appwriteRepository = AppwriteRepository();
      GroupMessage groupMessage = await appwriteRepository.getGroupMessageById(
        payload['groupMessageId'],
      );
      navigatorKey!.currentState!.pushNamed(
        Routes.chat,
        arguments: groupMessage,
      );
    } catch (e) {
      debugPrint('Lỗi điều hướng đến trang tin nhắn: $e');
      if (navigatorKey?.currentState != null) {
        ScaffoldMessenger.of(navigatorKey!.currentState!.context).showSnackBar(
          SnackBar(content: Text('Không thể mở trang tin nhắn: $e')),
        );
      }
    }
  }

  Future<void> _navigateToCallPage(Map<String, dynamic> payload) async {
    if (navigatorKey?.currentState == null) {
      debugPrint('NavigatorKey chưa sẵn sàng để điều hướng đến CallPage');
      return;
    }

    try {
      debugPrint('Payload for CallPage: $payload');
      final callId = payload['callId'] as String? ?? '';
      final callerId = payload['callerId'] as String? ?? '';
      final callerName = payload['callerName'] as String? ?? 'Unknown Caller';

      String userId = callerId;
      String userName = 'Unknown User';
      try {
        final currentUser = await AuthService.getCurrentUser();
        userId = currentUser?.$id ?? callerId;
        userName = currentUser?.name ?? 'Unknown User';
      } catch (e) {
        debugPrint('Lỗi lấy thông tin người dùng: $e');
      }

      if (callId.isNotEmpty && callerId.isNotEmpty) {
        debugPrint('Pushing CallPage with callId: $callId, userId: $userId');
        navigatorKey!.currentState!.push(
          MaterialPageRoute(
            builder:
                (context) => CallPage(
                  callID: callId,
                  userID: userId,
                  userName: userName,
                  callerName: callerName,
                ),
          ),
        );
      } else {
        debugPrint(
          'Thiếu thông tin cuộc gọi: callId=$callId, callerId=$callerId',
        );
        if (navigatorKey?.currentState != null) {
          ScaffoldMessenger.of(
            navigatorKey!.currentState!.context,
          ).showSnackBar(SnackBar(content: Text('Thiếu thông tin cuộc gọi')));
        }
      }
    } catch (e) {
      debugPrint('Lỗi điều hướng đến CallPage: $e');
      if (navigatorKey?.currentState != null) {
        ScaffoldMessenger.of(navigatorKey!.currentState!.context).showSnackBar(
          SnackBar(content: Text('Không thể mở trang cuộc gọi: $e')),
        );
      }
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('Nhận thông báo tiền cảnh: ${message.messageId}');

    if (message.data['type'] == 'call_ended' &&
        message.data['callId'] != null) {
      await _localNotifications.cancel(message.data['callId'].hashCode);
      debugPrint(
        'Cancelled call notification for callId: ${message.data['callId']}',
      );
      return;
    }

    if (message.data['type'] == 'video_call') {
      await _showCallNotification(
        _localNotifications,
        message.notification?.title ?? 'Cuộc gọi đến',
        'Từ ${message.data['callerName'] ?? 'Người gọi không xác định'}',
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
    int notificationId =
        payload['callId']?.hashCode ?? Random().nextInt(0x7FFFFFFF);
    final androidDetails = AndroidNotificationDetails(
      'video_call_channel',
      'Kênh cuộc gọi video',
      importance: Importance.max,
      priority: Priority.high,
      color: const Color(
        0xFF4CAF50,
      ), // Green color/ Custom sound, will address beloion pattern
      fullScreenIntent: true, // Full-screen intent
      timeoutAfter: 30000, // Cancel after 30 seconds
      styleInformation: const BigTextStyleInformation(''), // Compact display
      actions: const [
        AndroidNotificationAction('accept', 'Nhận', showsUserInterface: true),
        AndroidNotificationAction(
          'reject',
          'Từ chối',
          cancelNotification: true,
        ),
      ],
    );

    await notifications.show(
      notificationId,
      title,
      body,
      NotificationDetails(android: androidDetails),
      payload: jsonEncode({...payload, 'notificationId': notificationId}),
    );
  }

  Future<void> _showMessageNotification(
    FlutterLocalNotificationsPlugin notifications,
    String title,
    String body,
    Map<String, dynamic> payload,
  ) async {
    int notificationId =
        payload['messageId']?.hashCode ?? Random().nextInt(0x7FFFFFFF);
    const androidDetails = AndroidNotificationDetails(
      'message_channel',
      'Message Channel',
      importance: Importance.high,
      priority: Priority.high,
    );

    await notifications.show(
      notificationId,
      title,
      body,
      const NotificationDetails(android: androidDetails),
      payload: jsonEncode({...payload, 'notificationId': notificationId}),
    );
  }

  Future<String?> getFCMToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      debugPrint('FCM Token: $token');
      return token;
    } catch (e) {
      debugPrint('Lỗi lấy FCM token: $e');
      return null;
    }
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:messenger_clone/common/services/app_write_config.dart';
import 'package:messenger_clone/common/services/call_service.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';
import 'package:messenger_clone/common/extensions/custom_theme_extension.dart';
import 'package:messenger_clone/common/widgets/dialog/custom_alert_dialog.dart';
import 'package:messenger_clone/features/chat/model/user.dart';
import '../../../common/widgets/dialog/custom_call_dialog.dart';
import 'custom_messages_appbar.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void _initZegoUIKit() {
  ZegoUIKit().initLog();
  ZegoUIKitPrebuiltCallInvitationService().init(
    appID: 890267908,
    appSign: AppwriteConfig.zegoSignId,
    userID: '',
    userName: '',
    plugins: [ZegoUIKitSignalingPlugin()],
  );
}

class CallPage extends StatefulWidget {
  final String callID;
  final String userID;
  final String userName;
  final User? caller;
  final List<String>? participants;

  const CallPage({
    super.key,
    required this.callID,
    required this.userID,
    required this.userName,
    this.caller,
    this.participants,
  });

  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  bool _isInCall = false;
  String? _callDocumentId;
  bool _isInitiator = false;
  late String _effectiveCallID;

  @override
  void initState() {
    super.initState();
    _effectiveCallID = widget.callID;
    _checkAndJoinOrInitiateCall();
    _initializeCallInvitationService();
    _initZegoUIKit();
  }

  void _initializeCallInvitationService() {
    ZegoUIKitPrebuiltCallInvitationService().setNavigatorKey(navigatorKey);
    ZegoUIKitPrebuiltCallInvitationService().init(
      appID: 890267908,
      appSign: AppwriteConfig.zegoSignId,
      userID: widget.userID,
      userName: widget.userName,
      plugins: [ZegoUIKitSignalingPlugin()],
    );
  }

  Future<void> _checkAndJoinOrInitiateCall() async {
    try {
      if (widget.caller != null) {
        final existingCall = await CallService.checkExistingCall(
          userId: widget.userID,
          callerId: widget.caller!.id,
        );

        if (existingCall != null) {
          _callDocumentId = existingCall['callDocumentId'] as String?;
          _effectiveCallID = existingCall['callID'] as String;
          if (existingCall['status'] == 'pending') {
            _showCallNotification();
          } else if (existingCall['status'] == 'active') {
            setState(() {
              _isInCall = true;
              _isInitiator = false;
            });
          }
          return;
        }
      }

      if (widget.caller != null && widget.participants != null) {
        await _initiateCall();
        setState(() {
          _isInitiator = true;
        });
        _joinCall();
      }
    } catch (e) {
      CustomAlertDialog.show(
        context: context,
        title: 'Lỗi',
        message: 'Không thể kiểm tra hoặc bắt đầu cuộc gọi: $e',
      );
    }
  }

  void _showCallNotification() {
    CustomCallDialog.show(
      context: context,
      title: 'Cuộc gọi đến',
      message: 'Cuộc gọi từ ${widget.caller?.name ?? 'Người dùng'}',
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            _endCall();
          },
          child: const Text('Từ chối'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            _joinCall();
          },
          child: const Text('Chấp nhận'),
        ),
      ],
    );
  }

  Future<void> _initiateCall() async {
    try {
      _callDocumentId = await CallService.createCall(
        callID: widget.callID,
        initiatorId: widget.userID,
        participants: widget.participants!,
      );
      await CallService.updateCallStatus(
        callDocumentId: _callDocumentId!,
        status: 'pending',
      );
      _effectiveCallID = widget.callID;
    } catch (e) {
      CustomAlertDialog.show(
        context: context,
        title: 'Lỗi',
        message: 'Không thể bắt đầu cuộc gọi: $e',
      );
    }
  }

  void _joinCall() {
    setState(() {
      _isInCall = true;
      if (!_isInitiator) {
        _isInitiator = false;
      }
    });
    if (_callDocumentId != null) {
      CallService.updateCallStatus(
        callDocumentId: _callDocumentId!,
        status: 'active',
      );
    }
  }

  void _endCall() {
    setState(() => _isInCall = false);
    if (_callDocumentId != null) {
      CallService.updateCallStatus(
        callDocumentId: _callDocumentId!,
        status: 'ended',
      );
    }
    Navigator.pop(context);
  }

  @override
  void dispose() {
    if (_isInCall && _callDocumentId != null) {
      CallService.updateCallStatus(
        callDocumentId: _callDocumentId!,
        status: 'ended',
      ).catchError((e) => print('Error ending call: $e'));
    }
    ZegoUIKitPrebuiltCallInvitationService().uninit();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomMessagesAppBar(
        user:
            widget.caller ??
            User(
              id: widget.userID,
              name: widget.userName,
              photoUrl: '',
              lastSeen: DateTime.now(),
              isActive: true,
              aboutMe: '',
              email: '',
            ),
        isMe: false,
        callFunc: _isInCall ? null : _joinCall,
        videoCallFunc: _isInCall ? null : _joinCall,
        onTapAvatar: () {},
      ),
      body: Stack(
        children: [
          if (_isInCall)
            ZegoUIKitPrebuiltCall(
              appID: 890267908,
              appSign: AppwriteConfig.zegoSignId,
              userID: widget.userID,
              userName: widget.userName,
              callID: _effectiveCallID, // Sử dụng callID thực tế
              config:
                  ZegoUIKitPrebuiltCallConfig.groupVideoCall()
                    ..topMenuBarConfig.isVisible = false
                    ..bottomMenuBarConfig.isVisible = true,
              events: ZegoUIKitPrebuiltCallEvents(
                onCallEnd: (callID, reason) {
                  _endCall();
                },
              ),
            ),
          if (!_isInCall && _callDocumentId != null && !_isInitiator)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Đang chờ cuộc gọi...',
                    style: TextStyle(
                      fontSize: 20,
                      color: context.theme.textColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: _joinCall,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.theme.blue,
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(15),
                        ),
                        child: const Icon(
                          Icons.phone,
                          size: 30,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 20),
                      ElevatedButton(
                        onPressed: _endCall,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(15),
                        ),
                        child: const Icon(
                          Icons.call_end,
                          size: 30,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          if (_isInCall)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: _endCall,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(15),
                  ),
                  child: const Icon(
                    Icons.call_end,
                    size: 30,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

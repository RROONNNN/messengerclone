import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';

import '../../../common/services/app_write_config.dart';

final navigatorKey = GlobalKey<NavigatorState>();

class CallPage extends StatefulWidget {
  final String callID;
  final String userID;
  final String userName;
  final String? callerName;

  const CallPage({
    super.key,
    required this.callID,
    required this.userID,
    required this.userName,
    this.callerName,
  });

  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  @override
  void initState() {
    super.initState();
    _initializeZego();
  }

  void _initializeZego() {
    ZegoUIKit().initLog();
    ZegoUIKitPrebuiltCallInvitationService()
      ..setNavigatorKey(navigatorKey)
      ..init(
        appID: 890267908,
        appSign: AppwriteConfig.zegoSignId,
        userID: widget.userID,
        userName: widget.userName,
        plugins: [ZegoUIKitSignalingPlugin()],
      );
  }

  void _endCall() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.callerName ?? 'Video Call'),
      ),
      body: Stack(
        children: [
          ZegoUIKitPrebuiltCall(
            appID: 890267908,
            appSign: AppwriteConfig.zegoSignId,
            userID: widget.userID,
            userName: widget.userName,
            callID: widget.callID,
            config: ZegoUIKitPrebuiltCallConfig.groupVideoCall()
              ..topMenuBarConfig.isVisible = false
              ..bottomMenuBarConfig.isVisible = true,
            events: ZegoUIKitPrebuiltCallEvents(
              onCallEnd: (callID, reason) {
                _endCall();
              },
            ),
          ),
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
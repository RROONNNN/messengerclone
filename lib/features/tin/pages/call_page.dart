import 'dart:math';

import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';


final userID = Random().nextInt(1000000).toString();

class CallPage extends StatelessWidget {
  const CallPage({super.key, required this.callID});
  final String callID;

  @override
  Widget build(BuildContext context) {
    return ZegoUIKitPrebuiltCall(
      appID: 890267908,
      appSign: '8666a74a545ad2e21e688a29faee944e14648db378dbf3974a2f7bc538e1dff6',
      userID: userID,
      userName: 'user $userID',
      callID: callID,
      config: ZegoUIKitPrebuiltCallConfig.groupVideoCall(),
    );
  }
}
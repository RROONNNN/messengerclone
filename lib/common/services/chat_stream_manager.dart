import 'dart:async';
import 'package:appwrite/appwrite.dart';
import 'package:flutter/foundation.dart';

import 'app_write_config.dart';

class ChatStreamManager {
  static final Client _client = Client()
      .setEndpoint(AppwriteConfig.endpoint)
      .setProject(AppwriteConfig.projectId);

  static Realtime get realtime => Realtime(_client);

  StreamSubscription<RealtimeMessage>? _subscription;
  final Set<String> _subscribedGroupIds = <String>{};
  final Function(RealtimeMessage) _onMessageReceived;
  final Function(dynamic) _onError;

  ChatStreamManager({
    required Function(RealtimeMessage) onMessageReceived,
    required Function(dynamic) onError,
  }) : _onMessageReceived = onMessageReceived,
       _onError = onError;

  Future<void> initialize(String userId, List<String> initialGroupIds) async {
    await _subscription?.cancel();
    _subscribedGroupIds.clear();
    _subscribedGroupIds.addAll(initialGroupIds);

    _createSubscription(userId);
  }

  void _createSubscription(String userId) {
    List<String> channels = [
      'databases.${AppwriteConfig.databaseId}.collections.${AppwriteConfig.userCollectionId}.documents.$userId',
    ];
    for (String groupId in _subscribedGroupIds) {
      channels.add(
        'databases.${AppwriteConfig.databaseId}.collections.${AppwriteConfig.groupMessagesCollectionId}.documents.$groupId',
      );
    }
    debugPrint('Subscribing to channels: $channels');
    final subscription = realtime.subscribe(channels);
    _subscription = subscription.stream.listen(
      _onMessageReceived,
      onError: _onError,
    );
  }

  Future<void> addGroupMessage(String userId, String groupId) async {
    if (_subscribedGroupIds.contains(groupId)) return;

    debugPrint('Adding group message to subscription: $groupId');
    _subscribedGroupIds.add(groupId);
    await _subscription?.cancel();
    _createSubscription(userId);
  }

  Future<void> removeGroupMessage(String userId, String groupId) async {
    if (!_subscribedGroupIds.contains(groupId)) return;

    debugPrint('Removing group message from subscription: $groupId');
    _subscribedGroupIds.remove(groupId);
    await _subscription?.cancel();
    _createSubscription(userId);
  }

  List<String> get subscribedGroupIds => List.unmodifiable(_subscribedGroupIds);

  bool isSubscribedToGroup(String groupId) =>
      _subscribedGroupIds.contains(groupId);

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscribedGroupIds.clear();
  }
}

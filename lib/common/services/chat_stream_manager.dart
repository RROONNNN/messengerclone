import 'dart:async';
import 'package:appwrite/appwrite.dart';
import 'package:flutter/foundation.dart';

import 'app_write_config.dart';
import 'package:messenger_clone/features/chat/model/group_message.dart';

class ChatStreamManager {
  static final Client _client = Client()
      .setEndpoint(AppwriteConfig.endpoint)
      .setProject(AppwriteConfig.projectId);

  static Realtime get realtime => Realtime(_client);

  StreamSubscription<RealtimeMessage>? _subscription;
  final Set<GroupMessage> _subscribedGroupIds = {};
  final Function(RealtimeMessage) _onMessageReceived;
  final Function(dynamic) _onError;

  ChatStreamManager({
    required Function(RealtimeMessage) onMessageReceived,
    required Function(dynamic) onError,
  }) : _onMessageReceived = onMessageReceived,
       _onError = onError;

  Future<void> initialize(
    String userId,
    List<GroupMessage> initialGroupIds,
  ) async {
    await _subscription?.cancel();
    _subscribedGroupIds.clear();
    _subscribedGroupIds.addAll(initialGroupIds);

    _createSubscription(userId);
  }

  void _createSubscription(String userId) {
    List<String> channels = [
      'databases.${AppwriteConfig.databaseId}.collections.${AppwriteConfig.userCollectionId}.documents.$userId',
    ];
    for (GroupMessage group in _subscribedGroupIds) {
      channels.add(
        'databases.${AppwriteConfig.databaseId}.collections.${AppwriteConfig.groupMessagesCollectionId}.documents.${group.groupMessagesId}',
      );

      if (group.lastMessage != null) {
        channels.add(
          'databases.${AppwriteConfig.databaseId}.collections.${AppwriteConfig.messageCollectionId}.documents.${group.lastMessage!.id}',
        );
        debugPrint('Subscribing to message: ${group.lastMessage!.id}');
      }
    }
    debugPrint('Subscribing to channels: $channels');
    final subscription = realtime.subscribe(channels);
    _subscription = subscription.stream.listen(
      _onMessageReceived,
      onError: _onError,
    );
  }

  Future<void> addGroupMessage(String userId, GroupMessage group) async {
    if (_subscribedGroupIds.contains(group)) return;

    debugPrint(
      'Adding group message to subscription: ${group.groupMessagesId}',
    );
    _subscribedGroupIds.add(group);
    await _subscription?.cancel();
    _createSubscription(userId);
  }

  Future<void> removeGroupMessage(String userId, GroupMessage group) async {
    if (!_subscribedGroupIds.contains(group)) return;

    debugPrint(
      'Removing group message from subscription: ${group.groupMessagesId}',
    );
    _subscribedGroupIds.remove(group);
    await _subscription?.cancel();
    _createSubscription(userId);
  }

  List<String> get subscribedGroupIds => List.unmodifiable(_subscribedGroupIds);

  bool isSubscribedToGroup(GroupMessage group) =>
      _subscribedGroupIds.contains(group);

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscribedGroupIds.clear();
  }
}

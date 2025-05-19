import 'package:hive_flutter/adapters.dart';

class MetaAiServiceHive {
  static const String _conversationsBox = 'conversations';
  static const String _offlineQueueBox = 'offline_queue';
  static const String _metadataBox = 'metadata';
  static const String _lastSyncKey = 'last_sync_timestamp';
  static List<int>? _encryptionKey;

  static Future<void> init() async {
    await Hive.initFlutter();
    _encryptionKey = Hive.generateSecureKey();
  }

  static Future<Box> _openBox(String boxName) async {
    if (_encryptionKey == null) {
      throw Exception('Hive is not initialized yet. Call MetaAiServiceHive.init() first.');
    }
    return await Hive.openBox(
      boxName,
      encryptionCipher: HiveAesCipher(_encryptionKey!),
    );
  }

  static Future<List<Map<String, dynamic>>> getConversations() async {
    final box = await _openBox(_conversationsBox);
    final conversations = box.get('list', defaultValue: <Map<String, dynamic>>[]);
    return List<Map<String, dynamic>>.from(conversations);
  }

  static Future<void> saveConversations(List<Map<String, dynamic>> conversations) async {
    final box = await _openBox(_conversationsBox);
    await box.put('list', conversations);
  }

  static Future<List<Map<String, String>>> getMessages(String conversationId) async {
    final box = await _openBox('messages_$conversationId');
    final messages = box.get('list', defaultValue: <Map<String, String>>[]);
    return List<Map<String, String>>.from(messages);
  }

  static Future<void> saveMessages(String conversationId, List<Map<String, String>> messages) async {
    final box = await _openBox('messages_$conversationId');
    await box.put('list', messages);
  }

  static Future<void> deleteConversation(String conversationId) async {
    final convBox = await _openBox(_conversationsBox);
    final conversations = await getConversations();
    conversations.removeWhere((conv) => conv['id'] == conversationId);
    await convBox.put('list', conversations);
    await Hive.deleteBoxFromDisk('messages_$conversationId');
  }

  static Future<void> queueOfflineAction(Map<String, dynamic> action) async {
    final box = await _openBox(_offlineQueueBox);
    final actions = box.get('actions', defaultValue: <Map<String, dynamic>>[]);
    actions.add(action);
    await box.put('actions', actions);
  }

  static Future<List<Map<String, dynamic>>> getOfflineActions() async {
    final box = await _openBox(_offlineQueueBox);
    return List<Map<String, dynamic>>.from(box.get('actions', defaultValue: <Map<String, dynamic>>[]));
  }

  static Future<void> clearOfflineActions() async {
    final box = await _openBox(_offlineQueueBox);
    await box.put('actions', []);
  }

  static Future<void> saveLastSyncTimestamp() async {
    final box = await _openBox(_metadataBox);
    await box.put(_lastSyncKey, DateTime.now().toIso8601String());
  }

  static Future<bool> isDataStale() async {
    final box = await _openBox(_metadataBox);
    final lastSync = box.get(_lastSyncKey);
    if (lastSync == null) return true;
    final lastSyncTime = DateTime.parse(lastSync);
    return DateTime.now().difference(lastSyncTime).inMinutes > 5;
  }
}
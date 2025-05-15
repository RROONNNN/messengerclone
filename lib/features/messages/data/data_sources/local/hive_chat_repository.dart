import 'package:hive_flutter/adapters.dart';
import 'package:messenger_clone/features/messages/domain/models/message_model.dart';

class HiveChatRepository {
  static final HiveChatRepository instance = HiveChatRepository._internal();
  static const String _boxName = 'messagesBox';
  late final Future<Box<List<MessageModel>>> _box;

  factory HiveChatRepository() {
    return instance;
  }

  HiveChatRepository._internal() {
    _box = _initializeBox();
  }

  Future<Box<List<MessageModel>>> _initializeBox() async {
    return await Hive.openBox<List<MessageModel>>(_boxName);
  }

  Future<void> saveMessages(String groupId, List<MessageModel> messages) async {
    final box = await _box;
    await box.put(groupId, messages);
  }

  Future<List<MessageModel>?> getMessages(String groupId) async {
    final box = await _box;
    return box.get(groupId);
  }

  Future<void> clearMessages(String groupId) async {
    final box = await _box;
    await box.delete(groupId);
  }

  Future<void> clearAllMessages() async {
    final box = await _box;
    await box.clear();
  }
}

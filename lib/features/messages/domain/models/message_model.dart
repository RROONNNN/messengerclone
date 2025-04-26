import 'package:messenger_clone/common/constants/appwrite_database_constants.dart';
import 'package:messenger_clone/common/services/common_function.dart';

class MessageModel {
  final String idFrom;
  final String timestamp;
  final String content;
  final String type;
  bool isSeen;
  final String groupMessagesId;
  MessageModel({
    required this.idFrom,
    required this.timestamp,
    required this.content,
    required this.type,
    this.isSeen = false,
    required this.groupMessagesId,
  });

  Map<String, dynamic> toJson() {
    return {
      AppwriteDatabaseConstants.idFrom: this.idFrom,
      AppwriteDatabaseConstants.timestamp: this.timestamp,
      AppwriteDatabaseConstants.content: this.content,
      AppwriteDatabaseConstants.type: this.type,
      AppwriteDatabaseConstants.isSeen: this.isSeen,
      AppwriteDatabaseConstants.groupMessagesId: this.groupMessagesId,
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      idFrom: map[AppwriteDatabaseConstants.idFrom] as String,
      timestamp: map[AppwriteDatabaseConstants.timestamp] as String,
      content: map[AppwriteDatabaseConstants.content] as String,
      type: map[AppwriteDatabaseConstants.type] as String,
      isSeen: map[AppwriteDatabaseConstants.isSeen] as bool? ?? false,
      groupMessagesId: map[AppwriteDatabaseConstants.groupMessagesId] as String,
    );
  }
}

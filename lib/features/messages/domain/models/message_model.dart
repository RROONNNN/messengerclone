import 'package:messenger_clone/common/constants/appwrite_database_constants.dart';
import 'package:messenger_clone/common/services/common_function.dart';

class MessageModel {
  final String idFrom;
  final String idTo;
  final String timestamp;
  final String content;
  final String type;
  bool isSeen;
  late final String? groupChatId;
  MessageModel({
    required this.idFrom,
    required this.idTo,
    required this.timestamp,
    required this.content,
    required this.type,
    this.isSeen = false,
    this.groupChatId,
  });

  Map<String, dynamic> toJson() {
    return {
      AppwriteDatabaseConstants.idFrom: this.idFrom,
      AppwriteDatabaseConstants.idTo: this.idTo,
      AppwriteDatabaseConstants.timestamp: this.timestamp,
      AppwriteDatabaseConstants.content: this.content,
      AppwriteDatabaseConstants.type: this.type,
      AppwriteDatabaseConstants.isSeen: this.isSeen,
      AppwriteDatabaseConstants.groupChatId:
          this.groupChatId ?? CommonFunction.getGroupChatId(idFrom, idTo),
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      idFrom: map[AppwriteDatabaseConstants.idFrom] as String,
      idTo: map[AppwriteDatabaseConstants.idTo] as String,
      timestamp: map[AppwriteDatabaseConstants.timestamp] as String,
      content: map[AppwriteDatabaseConstants.content] as String,
      type: map[AppwriteDatabaseConstants.type] as String,
      isSeen: map[AppwriteDatabaseConstants.isSeen] as bool? ?? false,
      groupChatId: map[AppwriteDatabaseConstants.groupChatId] as String,
    );
  }
}

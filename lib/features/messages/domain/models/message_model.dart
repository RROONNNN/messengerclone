import 'package:messenger_clone/common/constants/appwrite_database_constants.dart';
import 'package:messenger_clone/common/services/date_time_format.dart';

class MessageModel {
  final String idFrom;
  DateTime createdAt;
  final String content;
  final String type;
  bool isSeen;
  final String groupMessagesId;
  MessageModel({
    required this.idFrom,
    required this.content,
    required this.type,
    this.isSeen = false,
    required this.groupMessagesId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().toUtc();

  Map<String, dynamic> toJson() {
    return {
      AppwriteDatabaseConstants.idFrom: this.idFrom,
      AppwriteDatabaseConstants.content: this.content,
      AppwriteDatabaseConstants.type: this.type,
      AppwriteDatabaseConstants.isSeen: this.isSeen,
      AppwriteDatabaseConstants.groupMessagesId: this.groupMessagesId,
    };
  }

  DateTime get vietnamTime {
    final utcTime = createdAt.toUtc();
    return utcTime.add(const Duration(hours: 7));
  }

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    MessageModel result = MessageModel(
      idFrom: map[AppwriteDatabaseConstants.idFrom] as String,
      content: map[AppwriteDatabaseConstants.content] as String,
      type: map[AppwriteDatabaseConstants.type] as String,
      isSeen: map[AppwriteDatabaseConstants.isSeen] as bool? ?? false,
      groupMessagesId: map[AppwriteDatabaseConstants.groupMessagesId] as String,
    );
    result.createdAt = DateTimeFormat.parseToDateTime(map['\$createdAt']);
    return result;
  }
}

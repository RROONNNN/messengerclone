import 'package:appwrite/appwrite.dart';
import 'package:messenger_clone/common/constants/appwrite_database_constants.dart';
import 'package:messenger_clone/common/services/common_function.dart';
import 'package:messenger_clone/common/services/date_time_format.dart';
import 'package:messenger_clone/features/messages/enum/message_status.dart';

class MessageModel {
  String id;
  final String idFrom;
  DateTime createdAt;
  final String content;
  final String type;
  final String groupMessagesId;
  List<String> reactions;
  MessageStatus? status;

  MessageModel({
    String? id,
    required this.idFrom,
    required this.content,
    required this.type,
    required this.groupMessagesId,
    DateTime? createdAt,
    this.reactions = const [],
    this.status,
  }) : id = id ?? ID.unique(),
       createdAt = createdAt ?? DateTime.now().toUtc();

  Map<String, dynamic> toJson() {
    return {
      AppwriteDatabaseConstants.idFrom: idFrom,
      AppwriteDatabaseConstants.content: content,
      AppwriteDatabaseConstants.type: type,
      AppwriteDatabaseConstants.groupMessagesId: groupMessagesId,
      'reactions': CommonFunction.reactionsToString(reactions),
    };
  }

  void addReaction(String reaction) {
    reactions.add(reaction);
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
      groupMessagesId: map[AppwriteDatabaseConstants.groupMessagesId] as String,
      reactions: CommonFunction.reactionsFromString(map['reactions']),
      id: map['\$id'] as String,
    );

    result.createdAt = DateTimeFormat.parseToDateTime(map['\$createdAt']);
    return result;
  }
  //copyWith
  MessageModel copyWith({
    String? id,
    String? idFrom,
    DateTime? createdAt,
    String? content,
    String? type,
    String? groupMessagesId,
    List<String>? reactions,
    MessageStatus? status,
  }) {
    return MessageModel(
      id: id ?? this.id,
      idFrom: idFrom ?? this.idFrom,
      createdAt: createdAt ?? this.createdAt,
      content: content ?? this.content,
      type: type ?? this.type,
      groupMessagesId: groupMessagesId ?? this.groupMessagesId,
      reactions: reactions ?? this.reactions,
      status: status ?? this.status,
    );
  }
}

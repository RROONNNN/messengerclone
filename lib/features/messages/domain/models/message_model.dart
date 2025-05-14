import 'package:appwrite/appwrite.dart';
import 'package:messenger_clone/common/constants/appwrite_database_constants.dart';
import 'package:messenger_clone/common/services/common_function.dart';
import 'package:messenger_clone/common/services/date_time_format.dart';
import 'package:messenger_clone/features/chat/model/user.dart';
import 'package:messenger_clone/features/messages/enum/message_status.dart';

class MessageModel {
  String id;
  late final String idFrom;
  DateTime createdAt;
  final String content;
  final String type;
  final String groupMessagesId;
  List<String> reactions;
  MessageStatus? status;
  List<User> usersSeen;
  final User sender;

  MessageModel({
    String? id,
    required this.sender,
    required this.content,
    required this.type,
    required this.groupMessagesId,
    DateTime? createdAt,
    this.reactions = const [],
    this.status,
    this.usersSeen = const [],
  }) : id = id ?? ID.unique(),
       createdAt = createdAt ?? DateTime.now().toUtc() {
    idFrom = sender.id;
  }

  Map<String, dynamic> toJson() {
    return {
      'sender': idFrom,
      AppwriteDatabaseConstants.content: content,
      AppwriteDatabaseConstants.type: type,
      AppwriteDatabaseConstants.groupMessagesId: groupMessagesId,
      'reactions': CommonFunction.reactionsToString(reactions),
      'usersSeen': usersSeen.map((e) => e.id).toList(),
    };
  }

  void addReaction(String reaction) {
    reactions.add(reaction);
  }

  void addUserSeen(User user) {
    if (!isSeenBy(user.id)) {
      usersSeen.add(user);
    }
  }

  bool isSeenBy(String userId) {
    return usersSeen.any((element) => element.id == userId);
  }

  bool isContains(String id) {
    return usersSeen.any((element) => element.id == id);
  }

  DateTime get vietnamTime {
    final utcTime = createdAt.toUtc();
    return utcTime.add(const Duration(hours: 7));
  }

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    MessageModel result = MessageModel(
      sender: User.fromMap(map['sender'] as Map<String, dynamic>),
      content: map[AppwriteDatabaseConstants.content] as String,
      type: map[AppwriteDatabaseConstants.type] as String,
      groupMessagesId: map[AppwriteDatabaseConstants.groupMessagesId] as String,
      reactions: CommonFunction.reactionsFromString(map['reactions']),
      id: map['\$id'] as String,
      usersSeen:
          (map['usersSeen'] as List<dynamic>?)
              ?.map((e) => User.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

    result.createdAt = DateTimeFormat.parseToDateTime(map['\$createdAt']);
    return result;
  }
  //copyWith
  MessageModel copyWith({
    String? id,
    User? sender,
    DateTime? createdAt,
    String? content,
    String? type,
    String? groupMessagesId,
    List<String>? reactions,
    MessageStatus? status,
    List<User>? usersSeen,
  }) {
    return MessageModel(
      id: id ?? this.id,
      sender: sender ?? this.sender,
      createdAt: createdAt ?? this.createdAt,
      content: content ?? this.content,
      type: type ?? this.type,
      groupMessagesId: groupMessagesId ?? this.groupMessagesId,
      reactions: reactions ?? this.reactions,
      status: status ?? this.status,
      usersSeen: usersSeen ?? this.usersSeen,
    );
  }
}

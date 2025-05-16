import 'package:hive_flutter/adapters.dart';

part 'message_status.g.dart';

@HiveType(typeId: 2)
enum MessageStatus {
  @HiveField(0)
  sent,
  @HiveField(1)
  sending,
  @HiveField(2)
  failed,
}

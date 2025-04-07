import 'package:appwrite/appwrite.dart';
import 'package:dartz/dartz.dart';
import 'package:messenger_clone/features/messages/domain/models/message_model.dart';

abstract class AbstractChatRepository {
  Future<Either<String, List<MessageModel>>> getMessages(
    String groupChatId,
    int limit,
    int offset,
  );
  Future<Either<String, void>> sendMessage(MessageModel message);
  Future<Either<String, Stream<RealtimeMessage>>> getChatStream(
    String groupChatId,
  );
}

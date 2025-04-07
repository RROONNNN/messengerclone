import 'package:appwrite/src/realtime_message.dart';
import 'package:dartz/dartz.dart';
import 'package:messenger_clone/features/messages/data/data_sources/remote/appwrite_chat_repository.dart';
import 'package:messenger_clone/features/messages/domain/models/message_model.dart';
import 'package:messenger_clone/features/messages/domain/repositories/abstract_chat_repository.dart';

class ChatRepositoryImpl implements AbstractChatRepository {
  late final AppwriteChatRepository appwriteChatRepository;
  ChatRepositoryImpl() {
    appwriteChatRepository = AppwriteChatRepository();
  }
  @override
  Future<Either<String, Stream<RealtimeMessage>>> getChatStream(
    String groupChatId,
  ) async {
    try {
      final response = await appwriteChatRepository.getChatStream(groupChatId);
      return Right(response);
    } catch (error) {
      return Left("Failed to fetch chat stream: $error");
    }
  }

  @override
  Future<Either<String, List<MessageModel>>> getMessages(
    String groupChatId,
    int limit,
    int offset,
  ) async {
    try {
      final response = await appwriteChatRepository.getMessages(
        groupChatId,
        limit,
        offset,
      );
      return Right(response);
    } catch (error) {
      return Left("Failed to fetch messages: $error");
    }
  }

  @override
  Future<Either<String, void>> sendMessage(MessageModel message) async {
    try {
      final response = await appwriteChatRepository.sendMessage(message);
      return Right(response);
    } catch (error) {
      return Left("Failed to send message: $error");
    }
  }
}

import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:messenger_clone/common/services/hive_service.dart';
import 'package:messenger_clone/common/services/store.dart';
import 'package:messenger_clone/features/messages/data/data_sources/local/hive_chat_repository.dart';

import '../../features/meta_ai/data/meta_ai_message_hive.dart';
import 'app_write_config.dart';
import 'network_utils.dart';

class AuthService {
  static final Client _client = Client()
      .setEndpoint(AppwriteConfig.endpoint)
      .setProject(AppwriteConfig.projectId);

  static Account get account => Account(_client);
  static Databases get databases => Databases(_client);
  static Realtime get realtime => Realtime(_client);
  static Functions get functions => Functions(_client);
  static Storage get storage => Storage(_client);
  static Future<String?> getUserIdFromEmail(String email) async {
    return NetworkUtils.withNetworkCheck(() async {
      try {
        final documents = await databases.listDocuments(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.userCollectionId,
          queries: [Query.equal('email', email)],
        );
        if (documents.documents.isEmpty) return null;
        return documents.documents.first.$id;
      } catch (e) {
        return null;
      }
    });
  }

  static Future<String?> getUserIdFromEmailAndPassword(
    String email,
    String password,
  ) async {
    return NetworkUtils.withNetworkCheck(() async {
      try {
        await signIn(email: email, password: password);
        final user = await account.get().timeout(const Duration(seconds: 20));
        await signOut();
        return user.$id;
      } on AppwriteException {
        await signOut();
        return null;
      }
    });
  }

  static Future<bool> isEmailRegistered(String email) async {
    return NetworkUtils.withNetworkCheck(() async {
      try {
        final documents = await databases.listDocuments(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.userCollectionId,
          queries: [Query.equal('email', email)],
        );
        return documents.documents.isNotEmpty;
      } catch (e) {
        return false;
      }
    });
  }

  static Future<void> resetPassword({
    required String userId,
    required String newPassword,
  }) async {
    return NetworkUtils.withNetworkCheck(() async {
      try {
        final execution = await functions.createExecution(
          functionId: AppwriteConfig.resetPasswordFunctionId,
          body: jsonEncode({'userId': userId, 'newPassword': newPassword}),
        );
        final response = jsonDecode(execution.responseBody);
        if (!response['success']) {
          throw Exception(response['message'] ?? 'Unknown error');
        }
      } on AppwriteException catch (e) {
        throw Exception('Failed to reset password: ${e.message}');
      } catch (e) {
        throw Exception('Error resetting password: $e');
      }
    });
  }

  static Future<void> updateUserAuth({
    required String userId,
    String? name,
    String? email,
    String? password,
  }) async {
    return NetworkUtils.withNetworkCheck(() async {
      try {
        if (name != null) {
          await account.updateName(name: name);
        }
        if (email != null) {
          final currentUser = await account.get().timeout(
            const Duration(seconds: 20),
          );
          await account.updateEmail(email: email, password: password!);
          await databases.updateDocument(
            databaseId: AppwriteConfig.databaseId,
            collectionId: AppwriteConfig.userCollectionId,
            documentId: currentUser.$id,
            data: {'email': email},
          );
        }
      } on AppwriteException catch (e) {
        throw Exception(
          'Failed to update authentication details: ${e.message}',
        );
      } catch (e) {
        throw Exception('Error updating authentication details: $e');
      }
    });
  }

  static Future<models.User> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    return NetworkUtils.withNetworkCheck(() async {
      try {
        final user = await account.create(
          userId: ID.unique(),
          email: email,
          password: password,
          name: name,
        );
        await _registerUser(user);
        return user;
      } on AppwriteException catch (e) {
        throw Exception('Sign up failed: ${e.message}');
      }
    });
  }

  static Future<void> _registerUser(models.User user) async {
    return NetworkUtils.withNetworkCheck(() async {
      try {
        await databases.createDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.userCollectionId,
          documentId: user.$id,
          data: {
            'email': user.email,
            'name': user.name,
            'pushTargets': <String>[],
          },
        );
      } on AppwriteException catch (e) {
        throw Exception('Failed to register user: ${e.message}');
      }
    });
  }

  static Future<models.Session> signIn({
    required String email,
    required String password,
  }) async {
    return NetworkUtils.withNetworkCheck(() async {
      try {
        models.Session session = await account.createEmailPasswordSession(
          email: email,
          password: password,
        );
        final fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken != null) {
          final targetId = ID.unique();
          await account.createPushTarget(
            targetId: targetId,
            identifier: fcmToken,
            providerId: AppwriteConfig.fcmProjectId,
          );
          await Store.setTargetId(targetId);
          final user = await account.get().timeout(const Duration(seconds: 20));
          HiveService.instance.saveCurrentUserId(user.$id);
          final document = await databases.getDocument(
            databaseId: AppwriteConfig.databaseId,
            collectionId: AppwriteConfig.userCollectionId,
            documentId: user.$id,
          );
          final List<String> pushTargets = List<String>.from(
            document.data['pushTargets'] ?? [],
          );
          if (!pushTargets.contains(targetId)) {
            pushTargets.add(targetId);
            await databases.updateDocument(
              databaseId: AppwriteConfig.databaseId,
              collectionId: AppwriteConfig.userCollectionId,
              documentId: user.$id,
              data: {'pushTargets': pushTargets},
            );
          }
        }
        return session;
      } on AppwriteException catch (e) {
        throw Exception('Sign in failed: ${e.message}');
      }
    });
  }

  static Future<void> signOut() async {
    return NetworkUtils.withNetworkCheck(() async {
      try {
        String targetId = await Store.getTargetId();
        if (targetId.isNotEmpty) {
          String userId = await HiveService.instance.getCurrentUserId();
          final document = await databases.getDocument(
            databaseId: AppwriteConfig.databaseId,
            collectionId: AppwriteConfig.userCollectionId,
            documentId: userId,
          );
          await account.deletePushTarget(targetId: targetId);
          final List<String> pushTargets = List<String>.from(
            document.data['pushTargets'] ?? [],
          );
          await Store.setTargetId('');
          pushTargets.remove(targetId);
          await databases.updateDocument(
            databaseId: AppwriteConfig.databaseId,
            collectionId: AppwriteConfig.userCollectionId,
            documentId: userId,
            data: {'pushTargets': pushTargets},
          );
        }
        MetaAiServiceHive.clearAllBoxes();
        HiveService.instance.clearCurrentUserId();
        HiveChatRepository.instance.clearAllMessages();
        await account.deleteSession(sessionId: 'current');
      } on AppwriteException {
        return;
      } catch (e) {
        return;
      }
    });
  }

  static Future<models.User?> getCurrentUser() async {
    try {
      return await account.get().timeout(const Duration(seconds: 20));
    } on AppwriteException catch (e) {
      if (e.code == 401) {
        return null;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<String?> isLoggedIn() async {
    try {
      final user = await account.get().timeout(const Duration(seconds: 20));
      return user.$id;
    } on AppwriteException catch (e) {
      if (e.code == 401) {
        return null;
      }
      throw Exception('Error checking login status: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error checking login status: $e');
    }
  }

  static Future<void> deleteAccount() async {
    return NetworkUtils.withNetworkCheck(() async {
      try {
        final user = await getCurrentUser();
        final userId = user?.$id;
        HiveService.instance.clearCurrentUserId();
        await HiveChatRepository.instance.clearAllMessages();
        await _deleteUserDocuments(userId!);
        await _deleteDeviceRecords(userId);

        await account.updateStatus();
      } on AppwriteException catch (e) {
        throw Exception('Failed to delete account: ${e.message}');
      } catch (e) {
        throw Exception('An error occurred while deleting account: $e');
      }
    });
  }

  static Future<void> _deleteUserDocuments(String userId) async {
    try {
      await databases.deleteDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.userCollectionId,
        documentId: userId,
      );
    } on AppwriteException catch (e) {
      if (e.code != 404) {
        throw Exception('Failed to delete user documents: ${e.message}');
      }
    }
  }

  static Future<void> _deleteDeviceRecords(String userId) async {
    try {
      final deviceRecords = await databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.deviceCollectionId,
        queries: [Query.equal('userId', userId)],
      );

      for (final doc in deviceRecords.documents) {
        await databases.deleteDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.deviceCollectionId,
          documentId: doc.$id,
        );
      }
    } on AppwriteException catch (e) {
      throw Exception('Failed to delete device records: ${e.message}');
    }
  }
}

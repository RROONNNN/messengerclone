import 'dart:io';
import 'package:appwrite/appwrite.dart';
import 'package:flutter/cupertino.dart';
import 'package:messenger_clone/common/services/auth_service.dart';
import 'package:path_provider/path_provider.dart';

import 'app_write_config.dart';
import 'network_utils.dart';

class UserService {
  static final Client _client = Client()
      .setEndpoint(AppwriteConfig.endpoint)
      .setProject(AppwriteConfig.projectId);

  static Account get account => Account(_client);
  static Databases get databases => Databases(_client);
  static Storage get storage => Storage(_client);

  static Future<List<String>> getPushTargets(String userId) async {
    try {
      final document = await databases.getDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.userCollectionId,
        documentId: userId,
      );
      return List<String>.from(document.data['pushTargets'] ?? []);
    } on AppwriteException catch (e) {
      throw Exception('Failed to get push targets: ${e.message}');
    }
  }

  static Future<Map<String, dynamic>> fetchUserDataById(String userId) async {
    return NetworkUtils.withNetworkCheck(() async {
      try {
        final userDoc = await databases.getDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.userCollectionId,
          documentId: userId,
        );
        return {
          'userName': userDoc.data['name'] as String?,
          'photoUrl': userDoc.data['photoUrl'] as String?,
          'userId': userDoc.$id,
          'aboutMe': userDoc.data['aboutMe'] as String?,
          'email': userDoc.data['email'] as String?,
          'isActive': userDoc.data['isActive'] as bool? ?? false,
        };
      } on AppwriteException catch (e) {
        throw Exception('Failed to fetch user data: ${e.message}');
      }
    });
  }

  static Future<void> updateUserProfile({
    required String userId,
    String? name,
    String? email,
    String? aboutMe,
    String? photoUrl,
  }) async {
    try {
      await databases.updateDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.userCollectionId,
        documentId: userId,
        data: {
          if (name != null) 'name': name,
          if (email != null) 'email': email,
          if (aboutMe != null) 'aboutMe': aboutMe,
          if (photoUrl != null) 'photoUrl': photoUrl,
        },
      );
    } catch (e) {
      throw Exception('Error updating profile: $e');
    }
  }

  static Future<void> updateUserAuth({
    required String userId,
    String? name,
    String? email,
    required String password,
  }) async {
    try {
      if (name != null) {
        await account.updateName(name: name);
      }
      if (email != null) {
        await account.updateEmail(email: email, password: password);
      }
    } on AppwriteException catch (e) {
      throw Exception('Failed to update authentication details: ${e.message}');
    } catch (e) {
      throw Exception('Error updating authentication details: $e');
    }
  }

  static Future<String?> getNameUser(String userId) async {
    try {
      final userDoc = await databases.getDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.userCollectionId,
        documentId: userId,
      );
      return userDoc.data['name'] as String?;
    } on AppwriteException catch (e) {
      throw Exception('Failed to get user name: ${e.message}');
    }
  }

  static Future<String> updatePhotoUrl({
    required File imageFile,
    required String userId,
  }) async {
    try {
      final uploadedFile = await storage.createFile(
        bucketId: AppwriteConfig.storageId,
        fileId: ID.unique(),
        file: InputFile.fromPath(
          path: imageFile.path,
          filename: 'avatar.png',
        ),
      );

      final newPhotoUrl =
          'https://fra.cloud.appwrite.io/v1/storage/buckets/${AppwriteConfig.storageId}/files/${uploadedFile.$id}/view?project=${AppwriteConfig.projectId}&mode=admin';

      await databases.updateDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.userCollectionId,
        documentId: userId,
        data: {'photoUrl': newPhotoUrl},
      );

      return newPhotoUrl;
    } catch (e) {
      throw Exception('Error uploading image: $e');
    }
  }

  static Future<String> uploadAndUpdatePhoto(File imageFile, String userId) async {
    return NetworkUtils.withNetworkCheck(() async {
      try {
        final directory = await getTemporaryDirectory();
        final imagePath = await imageFile.copy('${directory.path}/temp_avatar.png');

        final uploadedFile = await storage.createFile(
          bucketId: AppwriteConfig.storageId,
          fileId: ID.unique(),
          file: InputFile.fromPath(
            path: imagePath.path,
            filename: 'avatar.png',
          ),
        );

        final newPhotoUrl = 'https://fra.cloud.appwrite.io/v1/storage/buckets/${AppwriteConfig.storageId}/files/${uploadedFile.$id}/view?project=${AppwriteConfig.projectId}&mode=admin';

        await databases.updateDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.userCollectionId,
          documentId: userId,
          data: {'photoUrl': newPhotoUrl},
        );

        return newPhotoUrl;
      } on AppwriteException catch (e) {
        throw Exception('Failed to upload and update photo: ${e.message}');
      } catch (e) {
        throw Exception('Error uploading photo: $e');
      }
    });
  }
}
import 'dart:io';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';

class AppWriteService {
  const AppWriteService._();

  static final Client _publicClient = Client()
      .setEndpoint('https://cloud.appwrite.io/v1')
      .setProject('67e7a7eb001c9cd8d6ad')
      .addHeader('X-Appwrite-Key', 'standard_a8eb9a9f20ca95f65b224f78345b4f54f8f5b443a7f1344e4a2e638fb098a72c72ac78411b0e90107e3ac62c706631d9666affd00d8b0078c531c52ea0844545c4502372fbc097870a5fb977ae1949f3829b7476173879a53a49db29182146d567d9d7526370b4defc5491f279ccbc969920e669c5384843a86a55d54e1201b4')
      .setSelfSigned();

  static final Client _sessionClient = Client()
      .setEndpoint('https://cloud.appwrite.io/v1')
      .setProject('67e7a7eb001c9cd8d6ad')
      .setSelfSigned();

  static Account get account => Account(_sessionClient);
  static Databases get publicDatabases  => Databases(_publicClient);
  static Databases get privateDatabases  => Databases(_sessionClient);

  static const String _databaseId = '67e90080000a47b1eba4';
  static const String _userCollectionUser = '67e904b9002db65c933b';
  static const String _deviceCollection = '67ed42540013471695d3';

  static Future<models.User> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
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
  }

  static Future<void> _registerUser(models.User user) async {
    try {
      await publicDatabases.createDocument(
        databaseId: _databaseId,
        collectionId: _userCollectionUser,
        documentId: user.$id,
        data: {
          'email': user.email,
          'name': user.name,
        },
      );
    } on AppwriteException catch (e) {
      throw Exception('Failed to register email: ${e.message}');
    }
  }



  static Future<models.Session> signIn({
    required String email,
    required String password,
  }) async {
    return await account.createEmailPasswordSession(
      email: email,
      password: password,
    );
  }

  static Future<void> signOut() async {
    try {
      await account.deleteSession(sessionId: 'current');
    } on AppwriteException catch (e) {
      throw (e, 'Đăng xuất thất bại');
    }
  }

  static Future<models.User?> getCurrentUser() async {
    try {
      return await account.get();
    } on AppwriteException catch (e) {
      if (e.code == 401) {
        return null;
      }
    }
    return null;
  }
  static Future<String?> getCurrentUserId() async {
    try {
      final user = await account.get();
      return user.$id;
    } on AppwriteException catch (e) {
      if (e.code == 401) {
        return null;
      }
      throw Exception('Failed to get current user: ${e.message}');
    }
  }

  static Future<bool> isEmailRegistered(String email) async {
    try {
      final result = await publicDatabases.listDocuments(
        databaseId: _databaseId,
        collectionId: _userCollectionUser,
        queries: [
          Query.equal('email', email)
        ],
      );

      return result.documents.isNotEmpty;
    } on AppwriteException catch (e) {
      throw Exception('Error checking email: ${e.message}');
    }
  }

  static Future<bool> hasUserLoggedInFromThisDevice(String userId) async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      String deviceId;

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? '';
      } else {
        throw PlatformException(
          code: 'UNSUPPORTED_PLATFORM',
          message: 'Device info is only supported on Android and iOS',
        );
      }
      
      final isExitUserAndDevice = await privateDatabases.listDocuments(
        databaseId: _databaseId,
        collectionId: _deviceCollection,
        queries: [
          Query.equal('userId', userId),
          Query.equal('deviceId', deviceId),
          Query.limit(1)
        ],
      );
      if(isExitUserAndDevice.documents.isNotEmpty){
        return true ;
      }
      return false;
    } catch (e) {
      throw Exception('Failed to check device login history: $e');
    }
  }

  static Future<void> saveLoginDeviceInfo(String userId) async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      String deviceId;
      String platform;

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id;
        platform = 'Android';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? '';
        platform = 'iOS';
      } else {
        throw PlatformException(
          code: 'UNSUPPORTED_PLATFORM',
          message: 'Device info is only supported on Android and iOS',
        );
      }

      final existingDevice = await privateDatabases.listDocuments(
        databaseId: _databaseId,
        collectionId: _deviceCollection,
        queries: [
          Query.equal('userId', userId),
          Query.equal('deviceId', deviceId),
          Query.limit(1),
        ],
      );

      if (existingDevice.documents.isNotEmpty) {
        await privateDatabases.updateDocument(
          databaseId: _databaseId,
          collectionId: _deviceCollection,
          documentId: existingDevice.documents.first.$id,
          data: {
            'lastLogin': DateTime.now().toIso8601String(),
          },
        );
      } else {
        await privateDatabases.createDocument(
          databaseId: _databaseId,
          collectionId: _deviceCollection,
          documentId: ID.unique(),
          data: {
            'userId': userId,
            'deviceId': deviceId,
            'platform': platform,
            'lastLogin': DateTime.now().toIso8601String(),
          },
        );
      }
    } on AppwriteException catch (e) {
      throw Exception('Failed to save device info: ${e.message}');
    }
  }
}
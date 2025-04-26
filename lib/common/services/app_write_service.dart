import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class AppWriteService {
  const AppWriteService._();

  static final Client _client = Client()
      .setEndpoint('https://cloud.appwrite.io/v1')
      .setProject('67e7a7eb001c9cd8d6ad');

  static Account get account => Account(_client);
  static Databases get databases => Databases(_client);
  static Functions get functions => Functions(_client);

  static const String _databaseId = '67e90080000a47b1eba4';
  static const String _userCollectionUser = '67e904b9002db65c933b';
  static const String _deviceCollection = '67ed42540013471695d3';

  static const String _functionMetaAIId = '680b45a1003d0c997a24';

  static Future<models.User> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    return withNetworkCheck(() async {
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
    return withNetworkCheck(() async {
      try {
        await databases.createDocument(
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
    });
  }

  static Future<models.Session> signIn({
    required String email,
    required String password,
  }) async {
    return withNetworkCheck(() async {
      return await account.createEmailPasswordSession(
        email: email,
        password: password,
      );
    });
  }

  static Future<void> signOut() async {
    return withNetworkCheck(() async {
      try {
        await account.deleteSession(sessionId: 'current');
      } on AppwriteException {
        return;
      }
    });
  }

  static Future<models.User?> getCurrentUser() async {
      try {
        return await account.get();
      } on AppwriteException catch (e) {
        if (e.code == 401) {
          return null;
        }
        return null;
      }
  }

  static Future<String?> getUserIdFromEmailAndPassword(
      String email, String password) async {
    return withNetworkCheck(() async {
      try {
        await signIn(email: email, password: password);
        final user = await account.get();
        await signOut();
        return user.$id;
      } on AppwriteException {
        await signOut();
        return null;
      }
    });
  }

  static Future<bool> isEmailRegistered(String email) async {
    return withNetworkCheck(() async {
      try {
        final result = await databases.listDocuments(
          databaseId: _databaseId,
          collectionId: _userCollectionUser,
          queries: [Query.equal('email', email)],
        );
        return result.documents.isNotEmpty;
      } on AppwriteException catch (e) {
        throw Exception('Error checking email: ${e.message}');
      }
    });
  }

  static Future<bool> hasUserLoggedInFromThisDevice(String userId) async {
    return withNetworkCheck(() async {
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
          return false;
        }

        final isExitUserAndDevice = await databases.listDocuments(
          databaseId: _databaseId,
          collectionId: _deviceCollection,
          queries: [
            Query.equal('userId', userId),
            Query.equal('deviceId', deviceId),
            Query.limit(1)
          ],
        );
        if (isExitUserAndDevice.documents.isNotEmpty) {
          return true;
        }
        return false;
      } catch (e) {
        throw Exception('Failed to check device login history: $e');
      }
    });
  }

  static Future<void> saveLoginDeviceInfo(String userId) async {
    return withNetworkCheck(() async {
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

        final existingDevice = await databases.listDocuments(
          databaseId: _databaseId,
          collectionId: _deviceCollection,
          queries: [
            Query.equal('userId', userId),
            Query.equal('deviceId', deviceId),
            Query.limit(1),
          ],
        );

        if (existingDevice.documents.isNotEmpty) {
          await databases.updateDocument(
            databaseId: _databaseId,
            collectionId: _deviceCollection,
            documentId: existingDevice.documents.first.$id,
            data: {
              'lastLogin': DateTime.now().toIso8601String(),
            },
          );
        } else {
          await databases.createDocument(
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
    });
  }

  static Future<bool> _checkAppwriteConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isEmpty || result[0].rawAddress.isEmpty) {
        return false;
      }

      final response = await http.get(
          Uri.parse('https://cloud.appwrite.io/v1/avatars/initials')
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } on SocketException catch (_) {
      return false;
    } on http.ClientException catch (_) {
      return false;
    } on TimeoutException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }

  static Future<T> withNetworkCheck<T>(Future<T> Function() apiCall) async {
    if (!await _checkAppwriteConnection()) {
      throw Exception('No internet connection available');
    }
    return await apiCall();
  }

  static Future<void> deleteAccount() async {
    return withNetworkCheck(() async {
      try {
        final user =  await getCurrentUser();
        final userId = user?.$id;

        await _deleteUserDocuments(userId!);

        await _deleteDeviceRecords(userId);

        await account.updateStatus();
        //= block + function = delete ( do khoong xoa truc tiep duoc )

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
        databaseId: _databaseId,
        collectionId: _userCollectionUser,
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
        databaseId: _databaseId,
        collectionId: _deviceCollection,
        queries: [Query.equal('userId', userId)],
      );


      for (final doc in deviceRecords.documents) {
        await databases.deleteDocument(
          databaseId: _databaseId,
          collectionId: _deviceCollection,
          documentId: doc.$id,
        );
      }
    } on AppwriteException catch (e) {
      throw Exception('Failed to delete device records: ${e.message}');
    }
  }

  static Future<Map<String, dynamic>> callMetaAIFunction(List<Map<String, String>> history, int maxTokens) async {
    try {
      final execution = await functions.createExecution(
        functionId: _functionMetaAIId,
        body: jsonEncode({
          'body': {
            'history': history,
            'max_new_tokens': maxTokens,
          }
        }),
      );
      final response = jsonDecode(execution.responseBody);
      final responseData = response['body'] ?? response;
      if (responseData is! Map<String, dynamic>) {
        throw Exception('Invalid response format');
      }
      return responseData;
    } catch (e) {
      throw Exception('Failed to call AI function: ${e.toString()}');
    }
  }
}
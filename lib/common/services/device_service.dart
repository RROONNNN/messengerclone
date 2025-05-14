import 'dart:io';
import 'package:appwrite/appwrite.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';

import 'app_write_config.dart';
import 'network_utils.dart';

class DeviceService {
  static final Client _client = Client()
      .setEndpoint(AppwriteConfig.endpoint)
      .setProject(AppwriteConfig.projectId);

  static Databases get databases => Databases(_client);

  static Future<List<Map<String, dynamic>>> getUserDevices(String userId) async {
    return NetworkUtils.withNetworkCheck(() async {
      try {
        final deviceInfo = DeviceInfoPlugin();
        String currentDeviceId;

        if (Platform.isAndroid) {
          final androidInfo = await deviceInfo.androidInfo;
          currentDeviceId = androidInfo.id;
        } else if (Platform.isIOS) {
          final iosInfo = await deviceInfo.iosInfo;
          currentDeviceId = iosInfo.identifierForVendor ?? '';
        } else {
          throw PlatformException(
            code: 'UNSUPPORTED_PLATFORM',
            message: 'Device info is only supported on Android and iOS',
          );
        }

        final response = await databases.listDocuments(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.deviceCollectionId,
          queries: [
            Query.equal('userId', userId),
          ],
        );

        return response.documents.map((doc) {
          return {
            'documentId': doc.$id,
            'deviceId': doc.data['deviceId'] as String,
            'platform': doc.data['platform'] as String,
            'lastLogin': doc.data['lastLogin'] as String,
            'isCurrentDevice': doc.data['deviceId'] == currentDeviceId,
          };
        }).toList();
      } on AppwriteException catch (e) {
        throw Exception('Failed to fetch user devices: ${e.message}');
      } catch (e) {
        throw Exception('Error fetching user devices: $e');
      }
    });
  }

  static Future<void> removeDevice(String documentId) async {
    return NetworkUtils.withNetworkCheck(() async {
      try {
        await databases.deleteDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.deviceCollectionId,
          documentId: documentId,
        );
      } on AppwriteException catch (e) {
        throw Exception('Failed to remove device: ${e.message}');
      }
    });
  }

  static Future<bool> hasUserLoggedInFromThisDevice(String userId) async {
    return NetworkUtils.withNetworkCheck(() async {
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
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.deviceCollectionId,
          queries: [
            Query.equal('userId', userId),
            Query.equal('deviceId', deviceId),
            Query.limit(1),
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
    return NetworkUtils.withNetworkCheck(() async {
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
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.deviceCollectionId,
          queries: [
            Query.equal('userId', userId),
            Query.equal('deviceId', deviceId),
            Query.limit(1),
          ],
        );

        if (existingDevice.documents.isNotEmpty) {
          await databases.updateDocument(
            databaseId: AppwriteConfig.databaseId,
            collectionId: AppwriteConfig.deviceCollectionId,
            documentId: existingDevice.documents.first.$id,
            data: {
              'lastLogin': DateTime.now().toIso8601String(),
            },
          );
        } else {
          await databases.createDocument(
            databaseId: AppwriteConfig.databaseId,
            collectionId: AppwriteConfig.deviceCollectionId,
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
}
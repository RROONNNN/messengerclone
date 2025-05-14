import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class AppWriteService {
  const AppWriteService._();

  static final Client _client = Client()
      .setEndpoint('https://cloud.appwrite.io/v1')
      .setProject('67e7a7eb001c9cd8d6ad');

  static final zegoSignId = '8666a74a545ad2e21e688a29faee944e14648db378dbf3974a2f7bc538e1dff6';

  static Account get account => Account(_client);
  static Databases get databases => Databases(_client);
  static Storage get storage => Storage(_client);
  static Functions get functions => Functions(_client);

  static const String _databaseId = '67e90080000a47b1eba4';
  static const String _userCollectionUser = '67e904b9002db65c933b';
  static const String _deviceCollection = '67ed42540013471695d3';
  static const String _storageId = '67e8ee480012c2579b40';
  static const String _friendsID = '681e335200295fd8c1e7';
  static const String _storiesCollectionId = '6820ad53003e5e2b783e';
  static Realtime get realtime => Realtime(_client);

  static const String projectId = '67e7a7eb001c9cd8d6ad';
  static const String databaseId = '67e90080000a47b1eba4';
  static const String groupMessagesCollectionId = '67e908ed003b62a3f44a';
  static const String messageCollectionId = '67e9013c002a978980fa';
  static const String bucketId = '67e8ee480012c2579b40';
  static const String _functionMetaAIId = '680b45a1003d0c997a24';
  static const String userCollectionid = '67e904b9002db65c933b';

  static const String _callsCollectionId = '68216a0900371e85d22e';

  static Future<String> createCall({
    required String callID,
    required String initiatorId,
    required List<String> participants,
  }) async {
    return withNetworkCheck(() async {
      try {
        final document = await databases.createDocument(
          databaseId: _databaseId,
          collectionId: _callsCollectionId,
          documentId: ID.unique(),
          data: {
            'callID': callID,
            'initiatorId': initiatorId,
            'participants': participants,
            'status': 'pending',
            'createdAt': DateTime.now().toIso8601String(),
          },
        );
        return document.$id;
      } on AppwriteException catch (e) {
        throw Exception('Failed to create call: ${e.message}');
      }
    });
  }
  static Future<Map<String, dynamic>?> checkExistingCall({
    required String userId,
    required String callerId,
  }) async {
    return withNetworkCheck(() async {
      try {
        final response = await databases.listDocuments(
          databaseId: _databaseId,
          collectionId: _callsCollectionId,
          queries: [
            Query.equal('participants', userId),
            Query.equal('initiatorId', callerId),
            Query.or([
              Query.equal('status', 'pending'),
              Query.equal('status', 'active'),
            ]),
            Query.limit(1),
          ],
        );

        if (response.documents.isNotEmpty) {
          final doc = response.documents.first;
          return {
            'callID': doc.data['callID'] as String?,
            'initiatorId': doc.data['initiatorId'] as String?,
            'status': doc.data['status'] as String?,
            'callDocumentId': doc.$id,
            'participants': List<String>.from(doc.data['participants'] ?? []),
          };
        }
        return null;
      } on AppwriteException catch (e) {
        throw Exception('Failed to check existing call: ${e.message}');
      }
    });
  }

  static Future<void> updateCallStatus({
    required String callDocumentId,
    required String status,
  }) async {
    return withNetworkCheck(() async {
      try {
        await databases.updateDocument(
          databaseId: _databaseId,
          collectionId: _callsCollectionId,
          documentId: callDocumentId,
          data: {'status': status},
        );
      } on AppwriteException catch (e) {
        throw Exception('Failed to update call status: ${e.message}');
      }
    });
  }

  static Future<Map<String, dynamic>> callMetaAIFunction(
      List<Map<String, String>> history,
      int maxTokens,
      ) async {
    try {
      final execution = await functions.createExecution(
        functionId: _functionMetaAIId,
        body: jsonEncode({
          'body': {'history': history, 'max_new_tokens': maxTokens},
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

  static Future<String> postStory({
    required String userId,
    required File mediaFile,
    required String mediaType,
  }) async {
    return withNetworkCheck(() async {
      try {
        final file = await storage.createFile(
          bucketId: _storageId,
          fileId: ID.unique(),
          file: InputFile.fromPath(
            path: mediaFile.path,
            filename: mediaFile.path.split('/').last,
          ),
        );

        final mediaUrl = 'https://fra.cloud.appwrite.io/v1/storage/buckets/$_storageId/files/${file.$id}/view?project=67e7a7eb001c9cd8d6ad';

        final now = DateTime.now();
        final twentyFourHoursAgo = now.subtract(const Duration(hours: 24)).toIso8601String();
        final response = await databases.listDocuments(
          databaseId: _databaseId,
          collectionId: _storiesCollectionId,
          queries: [
            Query.equal('userId', userId),
            Query.greaterThan('createdAt', twentyFourHoursAgo),
          ],
        );
        final totalStories = response.documents.length + 1;

        await databases.createDocument(
          databaseId: _databaseId,
          collectionId: _storiesCollectionId,
          documentId: ID.unique(),
          data: {
            'userId': userId,
            'mediaUrl': mediaUrl,
            'mediaType': mediaType,
            'createdAt': now.toIso8601String(),
            'totalStories': totalStories,
          },
        );

        return mediaUrl;
      } on AppwriteException catch (e) {
        throw Exception('Failed to post story: ${e.message} (Code: ${e.code}, Type: ${e.type})');
      } catch (e) {
        throw Exception('Unexpected error while posting story: $e');
      }
    });
  }

  static Future<List<Map<String, dynamic>>> fetchFriendsStories(String userId) async {
    return withNetworkCheck(() async {
      try {
        final friendsList = await getFriendsList(userId);
        final friendIds = friendsList.map((friend) => friend['userId'] as String).toList();

        final allIds = [...friendIds, userId];

        final now = DateTime.now();
        final twentyFourHoursAgo = now.subtract(const Duration(hours: 24)).toIso8601String();

        final response = await databases.listDocuments(
          databaseId: _databaseId,
          collectionId: _storiesCollectionId,
          queries: [
            Query.equal('userId', allIds),
            Query.greaterThan('createdAt', twentyFourHoursAgo),
            Query.orderDesc('createdAt'),
          ],
        );

        return response.documents.map((doc) => {
          'userId': doc.data['userId'] as String,
          'mediaUrl': doc.data['mediaUrl'] as String,
          'mediaType': doc.data['mediaType'] as String,
          'createdAt': doc.data['createdAt'] as String,
          'totalStories': doc.data['totalStories'] as int,
        }).toList();
      } on AppwriteException catch (e) {
        throw Exception('Failed to fetch friends\' stories: ${e.message}');
      }
    });
  }

  static Future<void> deleteStory(String documentId, String fileId) async {
    return withNetworkCheck(() async {
      try {
        await storage.deleteFile(
          bucketId: _storageId,
          fileId: fileId,
        );
        await databases.deleteDocument(
          databaseId: _databaseId,
          collectionId: _storiesCollectionId,
          documentId: documentId,
        );
      } on AppwriteException catch (e) {
        throw Exception('Failed to delete story: ${e.message}');
      }
    });
  }

  static Future<Map<String, String>> getFriendshipStatus(String currentUserId, String otherUserId) async {
    return withNetworkCheck(() async {
      try {
        final sentResponse = await databases.listDocuments(
          databaseId: _databaseId,
          collectionId: _friendsID,
          queries: [
            Query.equal('userId', currentUserId),
            Query.equal('friendId', otherUserId),
            Query.limit(1),
          ],
        );

        if (sentResponse.documents.isNotEmpty) {
          final doc = sentResponse.documents.first;
          return {
            'status': doc.data['status'] as String,
            'requestId': doc.$id,
            'direction': 'sent',
          };
        }

        final receivedResponse = await databases.listDocuments(
          databaseId: _databaseId,
          collectionId: _friendsID,
          queries: [
            Query.equal('userId', otherUserId),
            Query.equal('friendId', currentUserId),
            Query.limit(1),
          ],
        );

        if (receivedResponse.documents.isNotEmpty) {
          final doc = receivedResponse.documents.first;
          return {
            'status': doc.data['status'] as String,
            'requestId': doc.$id,
            'direction': 'received',
          };
        }

        return {
          'status': 'none',
          'requestId': '',
          'direction': '',
        };
      } on AppwriteException catch (e) {
        throw Exception('Failed to check friendship status: ${e.message}');
      }
    });
  }

  static Future<List<Map<String, dynamic>>> getFriendsList(String userId) async {
    return withNetworkCheck(() async {
      try {
        final sentFriends = await databases.listDocuments(
          databaseId: _databaseId,
          collectionId: _friendsID,
          queries: [
            Query.equal('userId', userId),
            Query.equal('status', 'accepted'),
          ],
        );
        final receivedFriends = await databases.listDocuments(
          databaseId: _databaseId,
          collectionId: _friendsID,
          queries: [
            Query.equal('friendId', userId),
            Query.equal('status', 'accepted'),
          ],
        );

        final friendIds = <String, String>{};
        for (var doc in sentFriends.documents) {
          friendIds[doc.data['friendId'] as String] = doc.$id;
        }
        for (var doc in receivedFriends.documents) {
          friendIds[doc.data['userId'] as String] = doc.$id;
        }

        final friendsList = await Future.wait(friendIds.entries.map((entry) async {
          final friendId = entry.key;
          final requestId = entry.value;
          final friendData = await fetchUserDataById(friendId);
          return {
            'userId': friendId,
            'name': friendData['userName'] as String?,
            'photoUrl': friendData['photoUrl'] as String?,
            'aboutMe': friendData['aboutMe'] as String? ?? 'No description',
            'requestId': requestId,
          };
        }).toList());

        return friendsList;
      } on AppwriteException catch (e) {
        throw Exception('Failed to fetch friends list: ${e.message}');
      } catch (e) {
        throw Exception('Error fetching friends list: $e');
      }
    });
  }

  static Future<void> cancelFriendRequest(String requestId) async {
    return withNetworkCheck(() async {
      try {
        await databases.deleteDocument(
          databaseId: _databaseId,
          collectionId: _friendsID,
          documentId: requestId,
        );
      } on AppwriteException catch (e) {
        throw Exception('Failed to cancel friend request: ${e.message}');
      }
    });
  }

  static Future<List<Map<String, dynamic>>> searchUsersByName(String name) async {
    return withNetworkCheck(() async {
      try {
        final response = await databases.listDocuments(
          databaseId: _databaseId,
          collectionId: _userCollectionUser,
          queries: [
            Query.search('name', name),
            Query.limit(20),
          ],
        );
        return response.documents.map((doc) => {
          'userId': doc.$id,
          'name': doc.data['name'] as String?,
          'photoUrl': doc.data['photoUrl'] as String?,
          'aboutMe': doc.data['aboutMe'] as String?,
          'email': doc.data['email'] as String?,
          'isActive': doc.data['isActive'] as bool? ?? false,
        }).toList();
      } on AppwriteException catch (e) {
        throw Exception('Failed to search users: ${e.message}');
      } catch (e) {
        throw Exception('Error searching users: $e');
      }
    });
  }

  static Future<void> sendFriendRequest(String currentUserId, String friendUserId) async {
    return withNetworkCheck(() async {
      try {
        await databases.getDocument(
          databaseId: _databaseId,
          collectionId: _userCollectionUser,
          documentId: currentUserId,
        );
        await databases.getDocument(
          databaseId: _databaseId,
          collectionId: _userCollectionUser,
          documentId: friendUserId,
        );

        final existingRequest = await databases.listDocuments(
          databaseId: _databaseId,
          collectionId: _friendsID,
          queries: [
            Query.or([
              Query.and([
                Query.equal('userId', currentUserId),
                Query.equal('friendId', friendUserId),
              ]),
              Query.and([
                Query.equal('userId', friendUserId),
                Query.equal('friendId', currentUserId),
              ]),
            ]),
            Query.limit(1),
          ],
        );

        if (existingRequest.documents.isNotEmpty) {
          final status = existingRequest.documents.first.data['status'] as String;
          if (status == 'pending') {
            throw Exception('A friend request is already pending with this user.');
          } else if (status == 'accepted') {
            throw Exception('You are already friends with this user.');
          }
        }

        final documentId = ID.unique();
        await databases.createDocument(
          databaseId: _databaseId,
          collectionId: _friendsID,
          documentId: documentId,
          data: {
            'userId': currentUserId,
            'friendId': friendUserId,
            'status': 'pending',
          },
        );
      } on AppwriteException catch (e) {
        if (e.message?.contains('Document with the requested ID already exists') ?? false) {
          try {
            await databases.createDocument(
              databaseId: _databaseId,
              collectionId: _friendsID,
              documentId: ID.unique(),
              data: {
                'userId': currentUserId,
                'friendId': friendUserId,
                'status': 'pending',
              },
            );
          } catch (retryError) {
            throw Exception('Failed to send friend request after retry: ${retryError.toString()}');
          }
        } else if (e.message?.contains('unique constraint') ?? false) {
          throw Exception('A friend request or friendship already exists with this user.');
        } else {
          throw Exception('Failed to send friend request: ${e.message}');
        }
      } catch (e) {
        throw Exception('Error sending friend request: $e');
      }
    });
  }

  static Future<int> getPendingFriendRequestsCount(String userId) async {
    return withNetworkCheck(() async {
      try {
        final response = await databases.listDocuments(
          databaseId: _databaseId,
          collectionId: _friendsID,
          queries: [
            Query.equal('friendId', userId),
            Query.equal('status', 'pending'),
          ],
        );
        return response.total;
      } on AppwriteException catch (e) {
        throw Exception('Failed to fetch friend requests count: ${e.message}');
      }
    });
  }

  static Future<Map<String, dynamic>> fetchUserDataById(String userId) async {
    return withNetworkCheck(() async {
      try {
        final userDoc = await databases.getDocument(
          databaseId: _databaseId,
          collectionId: _userCollectionUser,
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

  static Future<List<Map<String, dynamic>>> getUserDevices(String userId) async {
    return withNetworkCheck(() async {
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
          databaseId: _databaseId,
          collectionId: _deviceCollection,
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
    return withNetworkCheck(() async {
      try {
        await databases.deleteDocument(
          databaseId: _databaseId,
          collectionId: _deviceCollection,
          documentId: documentId,
        );
      } on AppwriteException catch (e) {
        throw Exception('Failed to remove device: ${e.message}');
      }
    });
  }

  static Future<List<Map<String, dynamic>>> getPendingFriendRequests(String userId) async {
    return withNetworkCheck(() async {
      try {
        final response = await databases.listDocuments(
          databaseId: _databaseId,
          collectionId: _friendsID,
          queries: [
            Query.equal('friendId', userId),
            Query.equal('status', 'pending'),
          ],
        );
        return response.documents.map((doc) => {
          'requestId': doc.$id,
          'userId': doc.data['userId'] as String,
          'friendId': doc.data['friendId'] as String,
          'status': doc.data['status'] as String,
        }).toList();
      } on AppwriteException catch (e) {
        throw Exception('Failed to fetch friend requests: ${e.message}');
      }
    });
  }

  static Future<void> acceptFriendRequest(String requestId, String userId) async {
    return withNetworkCheck(() async {
      try {
        await databases.updateDocument(
          databaseId: _databaseId,
          collectionId: _friendsID,
          documentId: requestId,
          data: {'status': 'accepted'},
        );
      } on AppwriteException catch (e) {
        throw Exception('Failed to accept friend request: ${e.message}');
      }
    });
  }

  static Future<void> declineFriendRequest(String requestId) async {
    return withNetworkCheck(() async {
      try {
        await databases.deleteDocument(
          databaseId: _databaseId,
          collectionId: _friendsID,
          documentId: requestId,
        );
      } on AppwriteException catch (e) {
        throw Exception('Failed to decline friend request: ${e.message}');
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
        databaseId: _databaseId,
        collectionId: _userCollectionUser,
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

  static Future<String> updatePhotoUrl({
    required File imageFile,
    required String userId,
  }) async {
    try {
      final uploadedFile = await storage.createFile(
        bucketId: _storageId,
        fileId: ID.unique(),
        file: InputFile.fromPath(
          path: imageFile.path,
          filename: 'avatar.png',
        ),
      );

      final newPhotoUrl =
          'https://fra.cloud.appwrite.io/v1/storage/buckets/$_storageId/files/${uploadedFile.$id}/view?project=67e7a7eb001c9cd8d6ad&mode=admin';

      await databases.updateDocument(
        databaseId: _databaseId,
        collectionId: _userCollectionUser,
        documentId: userId,
        data: {'photoUrl': newPhotoUrl},
      );

      return newPhotoUrl;
    } catch (e) {
      throw Exception('Error uploading image: $e');
    }
  }

  static Future<String> uploadAndUpdatePhoto(File imageFile, String userId) async {
    return withNetworkCheck(() async {
      try {
        final directory = await getTemporaryDirectory();
        final imagePath = await imageFile.copy('${directory.path}/temp_avatar.png');

        final uploadedFile = await storage.createFile(
          bucketId: _storageId,
          fileId: ID.unique(),
          file: InputFile.fromPath(
            path: imagePath.path,
            filename: 'avatar.png',
          ),
        );

        final newPhotoUrl = 'https://fra.cloud.appwrite.io/v1/storage/buckets/$_storageId/files/${uploadedFile.$id}/view?project=67e7a7eb001c9cd8d6ad&mode=admin';

        await databases.updateDocument(
          databaseId: _databaseId,
          collectionId: _userCollectionUser,
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

  static Future<Map<String, dynamic>> fetchUserData() async {
    try {
      final user = await account.get();
      final userDoc = await databases.getDocument(
        databaseId: _databaseId,
        collectionId: _userCollectionUser,
        documentId: user.$id,
      );
      return {
        'userName': user.name,
        'userId': user.$id,
        'email': userDoc.data['email'] as String?,
        'aboutMe': userDoc.data['aboutMe'] as String?,
        'photoUrl': userDoc.data['photoUrl'] as String?,
      };
    } catch (e) {
      return {'error': 'Error: $e'};
    }
  }

  static Future<String?> isLoggedIn() async {
    try {
      final user = await account.get();
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
        throw Exception('Failed to register user: ${e.message}');
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
    } catch (e) {
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
        final user = await getCurrentUser();
        final userId = user?.$id;

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
}
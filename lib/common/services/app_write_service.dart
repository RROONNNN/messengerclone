import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;

class AppWriteService {
  const AppWriteService._();

  static Client client = Client()
      .setEndpoint('https://cloud.appwrite.io/v1')
      .setProject('67e7a7eb001c9cd8d6ad')
      .setSelfSigned();

  static Account get account => Account(client);
  static Databases get databases => Databases(client);
  static Storage get storage => Storage(client);
  static Realtime get realtime => Realtime(client);

  static Future<models.User> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    return await account.create(
      userId: ID.unique(),
      email: email,
      password: password,
      name: name,
    );
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
    await account.deleteSession(sessionId: 'current');
  }

  static Future<models.User> getCurrentUser() async {
    return await account.get();
  }

  static Future<models.Document> createDocument({
    required String databaseId,
    required String collectionId,
    required Map<String, dynamic> data,
  }) async {
    return await databases.createDocument(
      databaseId: databaseId,
      collectionId: collectionId,
      documentId: ID.unique(),
      data: data,
    );
  }

  static Future<models.DocumentList> listDocuments({
    required String databaseId,
    required String collectionId,
  }) async {
    return await databases.listDocuments(
      databaseId: databaseId,
      collectionId: collectionId,
    );
  }

  static Future<models.File> uploadFile({
    required String bucketId,
    required String filePath,
    String? fileName,
  }) async {
    return await storage.createFile(
      bucketId: bucketId,
      fileId: ID.unique(),
      file: InputFile.fromPath(
        path: filePath,
        filename: fileName ?? 'file_${DateTime.now().millisecondsSinceEpoch}',
      ),
    );
  }

  static Future<models.FileList> listFiles({
    required String bucketId,
  }) async {
    return await storage.listFiles(bucketId: bucketId);
  }
}
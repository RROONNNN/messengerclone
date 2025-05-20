import 'package:hive_flutter/adapters.dart';
part 'user.g.dart';

@HiveType(typeId: 1)
class User {
  @HiveField(0)
  final String aboutMe;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final String photoUrl;
  @HiveField(3)
  final String email;
  @HiveField(4)
  final String id;
  @HiveField(5)
  final bool isActive;
  @HiveField(6)
  final DateTime lastSeen;
  final String? chattingWithGroupMessId;
  User({
    required this.aboutMe,
    required this.name,
    required this.photoUrl,
    required this.email,
    required this.id,
    this.isActive = false,
    required this.lastSeen,
    this.chattingWithGroupMessId,
  });
  factory User.createMeUser(String id, {String? chattingWithGroupMessId}) {
    return User(
      aboutMe: '',
      name: '',
      photoUrl: '',
      email: '',
      id: id,
      isActive: false,
      lastSeen: DateTime.now().toUtc(),
      chattingWithGroupMessId: chattingWithGroupMessId,
    );
  }
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      aboutMe: map['aboutMe'] ?? '',
      name: map['name'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
      email: map['email'] ?? '',
      id: map['\$id'] ?? '',
      isActive: map['isActive'] ?? false,
      lastSeen:
          DateTime.tryParse(map['lastSeen'] ?? '') ?? DateTime.now().toUtc(),
      chattingWithGroupMessId: map['chattingWithGroupMessId'],
    );
  }
  @override
  bool operator ==(Object other) => other is User && other.id == id;
  @override
  int get hashCode => id.hashCode;
}

class User {
  final String aboutMe;
  final String name;
  final String photoUrl;
  final String chattingWith;
  final String email;
  final String id;
  final bool isActive;
  final DateTime lastSeen;

  User({
    required this.aboutMe,
    required this.name,
    required this.photoUrl,
    required this.chattingWith,
    required this.email,
    required this.id,
    this.isActive = false,
    required this.lastSeen,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      aboutMe: map['aboutMe'] ?? '',
      name: map['name'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
      chattingWith: map['chattingWith'] ?? '',
      email: map['email'] ?? '',
      id: map['\$id'] ?? '',
      isActive: map['isActive'] ?? false,
      lastSeen:
          DateTime.tryParse(map['lastSeen'] ?? '') ?? DateTime.now().toUtc(),
    );
  }
}

class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final int createdAt;

  UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
    required this.createdAt,
  });

  // Factory method to create a UserModel from a Map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['display_name'],
      photoUrl: map['photo_url'],
      createdAt: map['created_at'] ?? 0,
    );
  }

  // Convert UserModel to a Map
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'display_name': displayName,
      'photo_url': photoUrl,
      'created_at': createdAt,
    };
  }
}

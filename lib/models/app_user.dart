class AppUser {
  final String uid;
  final String name;
  final String email;

  /// 'customer' or 'admin'.
  final String role;
  final bool isDelivery;

  /// Profile picture URL (Cloudinary). Empty when no photo is set.
  final String photoUrl;

  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    this.role = 'customer',
    this.isDelivery = false,
    this.photoUrl = '',
  });

  factory AppUser.fromMap(String uid, Map<String, dynamic> m) => AppUser(
        uid: uid,
        name: m['name'] ?? '',
        email: m['email'] ?? '',
        role: m['role'] ?? 'customer',
        isDelivery: m['isDelivery'] ?? false,
        photoUrl: m['photoUrl'] ?? '',
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'role': role,
        'isDelivery': false,
        'photoUrl': '',
        'createdAt': DateTime.now().toIso8601String(),
      };
}
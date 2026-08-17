class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.username,
    required this.token,
    required this.expiresAt,
    required this.circleId,
    required this.isAdmin,
    required this.isGirlTeacher,
    this.isMrkz = false,
  });

  final int id;
  final String name;
  final String username;
  final String token;
  final DateTime expiresAt;
  final int circleId;
  final bool isAdmin;
  final bool isGirlTeacher;
  final bool isMrkz;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      username: json['username'] as String? ?? '',
      token: json['token'] as String? ?? '',
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      circleId: json['circleId'] as int? ?? -1,
      isAdmin: json['isAdmin'] as bool? ?? false,
      isGirlTeacher: json['isGirlTeacher'] as bool? ?? false,
      isMrkz: json['isMrkz'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'username': username,
        'token': token,
        'expiresAt': expiresAt.toIso8601String(),
        'circleId': circleId,
        'isAdmin': isAdmin,
        'isGirlTeacher': isGirlTeacher,
        'isMrkz': isMrkz,
      };

  bool get isSessionValid {
    if (token.isEmpty) return false;
    final expiry = expiresAt.isUtc ? expiresAt : expiresAt.toUtc();
    return expiry.isAfter(DateTime.now().toUtc());
  }
}

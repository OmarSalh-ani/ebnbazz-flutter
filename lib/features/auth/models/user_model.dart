class UserModel {
  final String id;
  final String name;
  final String phone;
  final String dialCode;
  final String? email;
  final String? avatarUrl;

  const UserModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.dialCode,
    this.email,
    this.avatarUrl,
  });

  String get fullPhone => '$dialCode$phone';

  UserModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? dialCode,
    String? email,
    String? avatarUrl,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      dialCode: dialCode ?? this.dialCode,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'dialCode': dialCode,
        'email': email,
        'avatarUrl': avatarUrl,
      };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        phone: json['phone'] ?? '',
        dialCode: json['dialCode'] ?? '+965',
        email: json['email'],
        avatarUrl: json['avatarUrl'],
      );
}

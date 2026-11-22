class UserModel {
  final int id;
  final String username;
  final String email;
  final String fullName;
  final String phoneNumber;
  final String role; // 'ADMIN' | 'MEMBER'
  final String? token;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.fullName,
    required this.phoneNumber,
    required this.role,
    this.token,
  });

  bool get isAdmin => role.toUpperCase() == 'ADMIN';
  bool get isMember => role.toUpperCase() == 'MEMBER';

  factory UserModel.fromJson(Map<String, dynamic> json, {String? token}) {
    String roleStr = 'MEMBER';
    if (json['roles'] is List && (json['roles'] as List).isNotEmpty) {
      final roles = (json['roles'] as List).map(
        (r) => r.toString().toUpperCase(),
      );
      if (roles.contains('ADMIN')) {
        roleStr = 'ADMIN';
      }
    } else if (json['role'] != null) {
      roleStr = json['role'].toString().toUpperCase();
    }

    final email = (json['email'] ?? '') as String;
    final fullName =
        (json['fullName'] ?? json['full_name'] ?? json['username'] ?? '')
            as String;
    final username =
        (json['username'] ?? (email.isNotEmpty ? email.split('@')[0] : 'user'))
            as String;

    return UserModel(
      id: json['id'] as int? ?? 0,
      username: username,
      email: email,
      fullName: fullName.isNotEmpty ? fullName : username,
      phoneNumber:
          (json['phoneNumber'] ?? json['phone_number'] ?? '') as String,
      role: roleStr,
      token: token ?? json['token'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'role': role,
      'token': token,
    };
  }
}

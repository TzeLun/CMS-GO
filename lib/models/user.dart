class User {
  final String id;
  final String email;
  final String name;
  final String? token;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.token,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'token': token,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      token: json['token']?.toString(),
    );
  }

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? token,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      token: token ?? this.token,
    );
  }
}

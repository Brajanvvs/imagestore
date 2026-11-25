class User {
  const User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.email,
    required this.fullName,
  });

  final int id;
  final String firstName;
  final String lastName;
  final String username;
  final String email;
  final String fullName;

  String get initials {
    final first = firstName.trim().isEmpty ? '' : firstName.trim()[0];
    final last = lastName.trim().isEmpty ? '' : lastName.trim()[0];
    final value = (first + last).toUpperCase();
    return value.isEmpty ? 'U' : value;
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      firstName: '${json['first_name'] ?? ''}',
      lastName: '${json['last_name'] ?? ''}',
      username: '${json['username'] ?? ''}',
      email: '${json['email'] ?? ''}',
      fullName: '${json['full_name'] ?? ''}',
    );
  }
}

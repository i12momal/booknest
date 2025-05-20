// Define la entidad Usuario en el modelo de datos.
class User {
  final String id;
  final String name;
  final String userName;
  final String email;
  final int phoneNumber;
  final String address;
  final String password;
  final String confirmPassword;
  final String? image;
  final List<String> genres;
  final String role;
  final List<String> favorites;
  final String? description;

//All required fields from class User
  User(
    {
    required this.id,
    required this.name,
    required this.userName,
    required this.email,
    required this.phoneNumber,
    required this.address,
    required this.password,
    required this.confirmPassword,
    required this.image,
    required this.genres,
    required this.role,
    this.favorites = const [],
    this.description = '',
    }
  );

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      userName: json['userName'],
      email: json['email'],
      phoneNumber: json['phoneNumber'],
      address: json['address'],
      password: json['password'],
      confirmPassword: json['confirmPassword'],
      image: json['image'],
      genres: json['genres'] is String
        ? json['genres'].split(', ')
        : List<String>.from(json['genres'] ?? []),
      role: json['role'],
      favorites: json['favorites'] is String
        ? json['favorites'].split(',').map((e) => e.trim()).toList()
        : List<String>.from(json['favorites'] ?? []),
      description: json['description'],
    );
  }
}
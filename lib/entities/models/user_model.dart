// Define la entidad Usuario en el modelo de datos.
class User {
  final int id;
  final String name;
  final String userName;
  final int age;
  final String email;
  final int phoneNumber;
  final String address;
  final String password;
  final String? image;
  final String role;

//All required fields from class User
  User(
    {
    required this.id,
    required this.name,
    required this.userName,
    required this.age,
    required this.email,
    required this.phoneNumber,
    required this.address,
    required this.password,
    required this.image,
    required this.role,
    }
  );
}
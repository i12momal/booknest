// Modelo de vista del formulario de creación
class CreateUserViewModel {
  final String name;
  final String userName;
  final String email;
  final int phoneNumber;
  final String address;
  final String password;
  final String? image;
  final String role;
  final List<String> favorites;
  final String? description;

  CreateUserViewModel(
    {  
    required this.name,
    required this.userName,
    required this.email,
    required this.phoneNumber,
    required this.address,
    required this.password,
    required this.image,
    required this.role,
    this.favorites = const [],
    this.description = ''
    }
  );
}


// Modelo de vista del formulario de edición
class EditUserViewModel {
  final String id;
  final String name;
  final String userName;
  final String email;
  final int phoneNumber;
  final String address;
  final String password;
  final String confirmPassword;
  final String? image;
  final String genres;
  final String role;
  final List<String> favorites;
  final String? description;

  EditUserViewModel(
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
    this.description = ''
    }
  );
}

// Modelo de vista del Index
class IndexUserViewModel {
  final String id;
  final String name;
  final String userName;
  final String email;
  final int phoneNumber;
  final String address;
  final String password;
  final String? image;

//All required fields from class User
  IndexUserViewModel(
    {
    required this.id,
    required this.name,
    required this.userName,
    required this.email,
    required this.phoneNumber,
    required this.address,
    required this.password,
    required this.image,
    }
  );
}

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

//All required fields from class User
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

//All required fields from class User
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
    }
  );
}

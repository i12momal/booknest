// Modelo de vista del Index
class IndexUserViewModel {
  final String name;
  final String userName;
  final int age;
  final String email;
  final int phoneNumber;
  final String address;
  final String password;
  final String? image;

//All required fields from class User
  IndexUserViewModel(
    {
    required this.name,
    required this.userName,
    required this.age,
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
  CreateUserViewModel(
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

// Modelo de vista del formulario de edición
class EditUserViewModel {
  final int id;
  final String name;
  final String userName;
  final int age;
  final String email;
  final int phoneNumber;
  final String address;
  final String password;
  final String? image;

//All required fields from class User
  EditUserViewModel(
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
    }
  );
}
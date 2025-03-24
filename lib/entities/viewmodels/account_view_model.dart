// Modelo de vista del formulario de Inicio de Sesión de Usuario
class LoginUserViewModel {
  final String userName;
  final String password;

//All required fields from class User
  LoginUserViewModel(
    {
    required this.userName,
    required this.password
    }
  );
}

// Modelo de vista del formulario de Registro de Usuario
class RegisterUserViewModel {
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
  RegisterUserViewModel(
    {  
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
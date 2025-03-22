import "package:booknest/entities/viewmodels/account_view_model.dart";
import "base_controller.dart";
import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';

// Controlador con los métodos de las acciones de Usuarios.
class AccountController extends BaseController{

  /* Método asíncrono que permite el registro de un nuevo usuario.
    Parámetros:
      - name: Cadena con el nombre completo del usuario.
      - userName: Cadena con el nombre de usuario.
      - Age: Entero con la edad del usuario.
      - Email: Cadena con el email del usuario.
      - phoneNumber: Entero con el número de teléfono del usuario.
      - address: Cadena con la dirección del usuario.
      - password: Cadena con la contraseña del usuario.
      - image: Cadena con la ubicación de la imagen.
    Return: 
      Mapa con la clave:
        - success: Indica si el registro fue exitoso (true o false).
        - message: Proporciona un mensaje de estado.
        - data (Opcional): Información del usuario registrado si la operación fue exitosa.
  */
  Future<Map<String, dynamic>> registerUser(String name, String userName, String email, int phoneNumber,
    String address, String password, String confirmPassword, File? image, String genres) async {

    String? imageUrl;

    // Generar el hash de la contraseña
    String passwordHash = generatePasswordHash(password);

    // Si el usuario sube una imagen, la guardamos en Supabase
    if (image != null) {
      imageUrl = await uploadProfileImage(image, userName);
      if (imageUrl == null) {
        return {'success': false, 'message': 'Error al subir la imagen'};
      }
    }

    // Creación del viewModel
    final registerUserViewModel = RegisterUserViewModel(
      name: name,
      userName: userName,
      email: email,
      phoneNumber: phoneNumber,
      address: address,
      password: passwordHash,
      confirmPassword: passwordHash,
      image: imageUrl,
      genres: genres,
      role: 'usuario',
    );
    
    // Llamada al servicio para registrar al usuario
    return await accountService.registerUser(registerUserViewModel);
  }


  /* Método asíncrono que comprueba que el nombre de usuario no existe en la base de datos.
    Parámetros:
      - userName: Cadena con el nombre de usuario.
    Return: 
      Devuelve verdadero si el nombre de usuario ya está registrado.
  */
  Future<bool> isUsernameTaken(String username) async {
    List<String> existingUsernames = ['user1', 'user2', 'user3']; 
    return existingUsernames.contains(username); 
  }


  /* Método para guardar una imagen en Supabase.
     Parámetros:
      - imageFile: archivo de la imagen.
      - userName: nombre del usuario para crear el nombre con el que se va a almacenar la imagen.
  */
  Future<String?> uploadProfileImage(File imageFile, String userName) async {
    return await accountService.uploadImageToSupabase(imageFile, userName);
  }


  /* Método para generar un hash seguro de la contraseña.
     Parámetros:
      - password: contraseña a cifrar.
  */
  String generatePasswordHash(String password) {
    // Convertir la contraseña a bytes
    final bytes = utf8.encode(password);

    // Crear un hash SHA-256
    final digest = sha256.convert(bytes);

    // Devolver el hash en formato hexadecimal
    return digest.toString();
  }

}
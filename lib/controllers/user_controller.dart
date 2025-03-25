import 'package:booknest/entities/models/user_model.dart';
import "package:booknest/entities/viewmodels/user_view_model.dart";
import "base_controller.dart";
import 'dart:io';
import 'package:booknest/controllers/account_controller.dart';

// Controlador con los métodos de las acciones de Usuarios.
class UserController extends BaseController{
  
  /* Método asíncrono que permite editar los datos de un usuario.
    Parámetros:
      - id: Identificador del usuario.
      - name: Cadena con el nombre completo del usuario.
      - userName: Cadena con el nombre de usuario.
      - email: Cadena con el email del usuario.
      - phoneNumber: Entero con el número de teléfono del usuario.
      - address: Cadena con la dirección del usuario.
      - password: Cadena con la contraseña del usuario.
      - image: Cadena con la ubicación de la imagen.
    Return: 
      Mapa con la clave:
        - success: Indica si la edición fue exitosa (true o false).
        - message: Proporciona un mensaje de estado.
        - data (Opcional): Información del usuario actualizado si la operación fue exitosa.
  */
  Future<Map<String, dynamic>> editUser(String id, String name, String userName, String email, int phoneNumber,
    String address, String password, String confirmPassword, File? image, String genres) async {

    String? imageUrl;
    String? passwordHash;

    // Si hay una nueva contraseña, generamos el hash
    if (password.isNotEmpty) {
      passwordHash = AccountController().generatePasswordHash(password);
    }

    // Si el usuario sube una imagen, la guardamos en Supabase
    if (image != null) {
      imageUrl = await AccountController().uploadProfileImage(image, userName);
      if (imageUrl == null) {
        return {'success': false, 'message': 'Error al subir la imagen'};
      }
    }

    // Creación del viewModel
    final editUserViewModel = EditUserViewModel(
      id: id,
      name: name,
      userName: userName,
      email: email,
      phoneNumber: phoneNumber,
      address: address,
      password: passwordHash ?? '',
      confirmPassword: passwordHash ?? '',
      image: imageUrl,
      genres: genres,
      role: 'usuario',
    );
    
    // Llamada al servicio para registrar al usuario
    return await userService.editUser(editUserViewModel);
  }


  /* Método asíncrono que devuelve los datos de un usuario. */
  Future<User?> getUserById(String userId) async {
    var response = await userService.getUserById(userId);
    
    if (response['success'] && response['data'] != null) {
      // Convertir la respuesta en un objeto User
      return User.fromJson(response['data']);
    }

    return null;
  }
}
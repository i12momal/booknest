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
  Future<Map<String, dynamic>> editUser(
    String id,
    String name,
    String userName,
    String email,
    int phoneNumber,
    String address,
    String password,
    String confirmPassword,
    File? image,
    String genres
  ) async {
    String? imageUrl;
    String? passwordHash;

    // Obtener la URL de la imagen actual del usuario
    final currentUser = await userService.getUserById(id);
    String? currentImageUrl;
    if (currentUser['success'] && currentUser['data'] != null) {
      currentImageUrl = currentUser['data']['image'];
      print("URL de la imagen actual: $currentImageUrl");
    }

    // Si se proporciona una contraseña, validarla y encriptarla
    if (password.trim().isNotEmpty) {
      if (password != confirmPassword) {
        return {'success': false, 'message': 'Las contraseñas no coinciden'};
      }
      passwordHash = AccountController().generatePasswordHash(password);
    }

    // Si el usuario sube una imagen, la subimos a Supabase
    if (image != null) {
      try {
        imageUrl = await AccountController().uploadProfileImage(image, userName);
        if (imageUrl == null) {
          return {'success': false, 'message': 'Error al subir la imagen. Por favor, intente nuevamente.'};
        }
        print("Nueva URL de imagen: $imageUrl");
      } catch (e) {
        print("Error al procesar la imagen: $e");
        return {'success': false, 'message': 'Error al procesar la imagen. Por favor, intente nuevamente.'};
      }
    } else {
      // Mantener la imagen actual si no se sube una nueva
      imageUrl = currentImageUrl;
    }

    // Creación del viewModel
    final editUserViewModel = EditUserViewModel(
      id: id,
      name: name,
      userName: userName,
      email: email,
      phoneNumber: phoneNumber,
      address: address,
      password: passwordHash ?? '',  // No enviar '' si no hay cambio
      confirmPassword: passwordHash ?? '',  // No enviar '' si no hay cambio
      image: imageUrl,
      genres: genres,
      role: 'usuario',
    );

    print("Contenido del viewModel:");
    print("ID: ${editUserViewModel.id}");
    print("Nombre: ${editUserViewModel.name}");
    print("Nombre de usuario: ${editUserViewModel.userName}");
    print("Email: ${editUserViewModel.email}");
    print("Teléfono: ${editUserViewModel.phoneNumber}");
    print("Dirección: ${editUserViewModel.address}");
    print("Contraseña: ${editUserViewModel.password.isNotEmpty ? '*****' : '(No modificada)'}");
    print("Confirmar contraseña: ${editUserViewModel.confirmPassword.isNotEmpty ? '*****' : '(No modificada)'}");
    print("Imagen: ${editUserViewModel.image ?? '(No modificada)'}");
    print("Géneros: ${editUserViewModel.genres}");
    print("Rol: ${editUserViewModel.role}");


    // Llamada al servicio para actualizar el usuario
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
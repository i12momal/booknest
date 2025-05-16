import 'package:booknest/entities/models/category_model.dart';
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
  Future<Map<String, dynamic>> editUser(String id, String name, String userName, String email, int phoneNumber, String address, String password, String confirmPassword,
    File? image, String genres, String description) async {
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
      description: description
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

  // Método para obtener las categorías de los libros del usuario
  Future<List<Category>> getCategoriesFromBooks(String userId) async {
    try {
      final books = await bookService.getBooksForUser(userId);
      Set<String> categoriesSet = {};

      for (var book in books) {
        if (book.categories != null && book.categories.isNotEmpty) {
          final categories = book.categories
              .split(',')
              .map((c) => c.trim());
          categoriesSet.addAll(categories);
        }
      }

      if (categoriesSet.isEmpty) return [];

      // En lugar de hacer otra consulta por categoría, usamos tu método actual para traer todas
      final result = await categoryService.getUserCategories(); // ya devuelve name + image

      if (result['success']) {
        final allCategories = (result['data'] as List<dynamic>)
            .map((json) => Category.fromJson(json))
            .toList();

        // Filtrar solo las que están en los libros del usuario
        return allCategories.where((cat) => categoriesSet.contains(cat.name)).toList();
      } else {
        return [];
      }
    } catch (e) {
      print('Error obteniendo categorías: $e');
      return [];
    }
  }

  // Verificar si el libro está en los favoritos
  Future<Map<String, dynamic>> isFavorite(int bookId) async {
    try {
      final response = await userService.getFavorites();
      List<String> favorites = List<String>.from(response['favorites']);
      return {
        'isFavorite': favorites.contains(bookId.toString()),
      };
    } catch (error) {
      print("Error al verificar favoritos: $error");
      return {'isFavorite': false};
    }
  }

  // Método para agregar a favoritos
  Future<Map<String, dynamic>> addToFavorites(int bookId) async {
    try {
      // Llamamos al servicio para agregar el libro a favoritos
      await userService.addToFavorites(bookId);
      return {'success': true, 'message': 'Libro agregado a favoritos'};
    } catch (error) {
      return {'success': false, 'message': 'Error al agregar a favoritos: $error'};
    }
  }

  // Método para eliminar de favoritos
  Future<Map<String, dynamic>> removeFromFavorites(int bookId) async {
    try {
      // Llamamos al servicio para eliminar el libro de favoritos
      await userService.removeFromFavorites(bookId);
      return {'success': true, 'message': 'Libro eliminado de favoritos'};
    } catch (error) {
      return {'success': false, 'message': 'Error al eliminar de favoritos: $error'};
    }
  }


  Future<User?> getCurrentUserById(String? userId) async {
    final result = await userService.getCurrentUserById(userId);
    return result;
  }


  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    return await userService.searchUsers(query);
  }

  // Obtener los libros favoritos del usuario
  Future<Map<String, dynamic>> getFavorites() async {
    return await userService.getFavorites();
  }


  Future<User> getCurrentUser() async {
    return await userService.getCurrentUser();
  }

  Future<Map<String, dynamic>> getUserNameById(String userId) async {
    return await userService.getUserNameById(userId);
  }

}
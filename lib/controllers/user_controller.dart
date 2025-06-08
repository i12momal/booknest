import 'dart:typed_data';

import 'package:booknest/entities/models/category_model.dart';
import 'package:booknest/entities/models/user_model.dart';
import "package:booknest/entities/viewmodels/user_view_model.dart";
import "base_controller.dart";
import 'dart:io';
import 'package:booknest/controllers/account_controller.dart';

// Controlador con los métodos de las acciones de Usuarios.
class UserController extends BaseController{
  
  // Método asíncrono que permite editar los datos de un usuario.
  Future<Map<String, dynamic>> editUser(String id, String name, String userName, String email, int phoneNumber, String address, String password, String confirmPassword,
  dynamic image, String genres, String description) async {
    String? imageUrl;
    String? passwordHash;

    final currentUser = await userService.getUserById(id);
    String? currentImageUrl;
    if (currentUser['success'] && currentUser['data'] != null) {
      currentImageUrl = currentUser['data']['image'];
      print("URL de la imagen actual: $currentImageUrl");
    }

    if (password.trim().isNotEmpty) {
      if (password != confirmPassword) {
        return {'success': false, 'message': 'Las contraseñas no coinciden'};
      }

      try {
        await userService.updatePasswordSupabaseAuth(password);
        passwordHash = AccountController().generatePasswordHash(password);
      } catch (e) {
        return {
          'success': false,
          'message': 'No se pudo actualizar la contraseña. Intenta nuevamente.'
        };
      }
    }

    if (image != null) {
      try {
        if (image is File) {
          // Imagen móvil
          imageUrl = await accountService.uploadProfileImageMobile(image, userName);
        } else if (image is Uint8List) {
          // Imagen web
          imageUrl = await accountService.uploadProfileImageWeb(image, userName);
        } else {
          return {'success': false, 'message': 'Tipo de imagen no soportado'};
        }

        if (imageUrl == null) {
          return {'success': false, 'message': 'Error al subir la imagen. Por favor, intente nuevamente.'};
        }

        print("Nueva URL de imagen: $imageUrl");
      } catch (e) {
        print("Error al procesar la imagen: $e");
        return {'success': false, 'message': 'Error al procesar la imagen. Por favor, intente nuevamente.'};
      }
    } else {
      imageUrl = currentImageUrl;
    }

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
      description: description,
    );

    return await userService.editUser(editUserViewModel);
  }

  // Método asíncrono que devuelve los datos de un usuario. 
  Future<User?> getUserById(String userId) async {
    var response = await userService.getUserById(userId);
    
    if (response['success'] && response['data'] != null) {
      // Convertir la respuesta en un objeto User
      return User.fromJson(response['data']);
    }

    return null;
  }

  // Método asíncrono para obtener las categorías de los libros del usuario.
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

      final result = await categoryService.getUserCategories();

      if (result['success']) {
        final allCategories = (result['data'] as List<dynamic>).map((json) => Category.fromJson(json)).toList();

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

  // Método asíncrono para verificar si el libro está en los favoritos.
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

  // Método asíncrono para agregar un libro a favoritos.
  Future<Map<String, dynamic>> addToFavorites(int bookId) async {
    try {
      // Llamamos al servicio para agregar el libro a favoritos
      await userService.addToFavorites(bookId);
      return {'success': true, 'message': 'Libro agregado a favoritos'};
    } catch (error) {
      return {'success': false, 'message': 'Error al agregar a favoritos: $error'};
    }
  }

  // Método asíncrono para eliminar un libro de favoritos.
  Future<Map<String, dynamic>> removeFromFavorites(int bookId) async {
    try {
      // Llamamos al servicio para eliminar el libro de favoritos
      await userService.removeFromFavorites(bookId);
      return {'success': true, 'message': 'Libro eliminado de favoritos'};
    } catch (error) {
      return {'success': false, 'message': 'Error al eliminar de favoritos: $error'};
    }
  }

  // Método asíncrono para obtener el usuario actual por su id.
  Future<User?> getCurrentUserById(String? userId) async {
    final result = await userService.getCurrentUserById(userId);
    return result;
  }

  // Método asíncrono que permite buscar usuarios según un filtro.
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    return await userService.searchUsers(query);
  }

  // Método asíncrono para obtener los libros favoritos del usuario
  Future<Map<String, dynamic>> getFavorites() async {
    return await userService.getFavorites();
  }

  // Método asíncrono para obtener el usuario actual.
  Future<User> getCurrentUser() async {
    return await userService.getCurrentUser();
  }

  // Método asíncrono para obtener el nombre de un usuario por su id.
  Future<Map<String, dynamic>> getUserNameById(String userId) async {
    return await userService.getUserNameById(userId);
  }

}
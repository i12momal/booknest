import 'package:booknest/entities/models/user_model.dart';
import 'package:booknest/entities/viewmodels/user_view_model.dart';
import 'package:booknest/services/base_service.dart';

// Servicio con los métodos de negocio de la entidad Usuario.
class UserService extends BaseService{

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
  Future<Map<String, dynamic>> editUser(EditUserViewModel editUserViewModel) async {
    try {
      // Comprobamos si la conexión a Supabase está activa.
      if (BaseService.client == null) {
        return {'success': false, 'message': 'Error de conexión a la base de datos.'};
      }

      print("Iniciando edición de usuario...");
      print("ID del usuario a editar: ${editUserViewModel.id}");

      // Obtener el ID del usuario autenticado
      final currentUser = BaseService.client.auth.currentUser;
      if (currentUser == null) {
        print("Error: Usuario no autenticado");
        return {'success': false, 'message': 'Usuario no autenticado'};
      }

      print("ID del usuario autenticado (auth.uid): ${currentUser.id}");
      print("Email del usuario autenticado: ${currentUser.email}");

      // Verificar que el usuario está intentando editar sus propios datos
      if (currentUser.id != editUserViewModel.id) {
        print("Error: Intento de editar datos de otro usuario");
        print("ID del usuario autenticado: ${currentUser.id}");
        print("ID del usuario a editar: ${editUserViewModel.id}");
        return {'success': false, 'message': 'No tienes permiso para editar estos datos'};
      }

      // Verificar que el usuario existe
      print("Verificando existencia del usuario...");
      final existingUser = await BaseService.client.from('User').select().eq('id', editUserViewModel.id).single();
      if (existingUser == null) {
        print("Error: Usuario no encontrado en la base de datos");
        return {'success': false, 'message': 'Usuario no encontrado'};
      }

      print("Usuario encontrado en la base de datos:");
      print("ID: ${existingUser['id']}");
      print("Nombre: ${existingUser['name']}");
      print("Email: ${existingUser['email']}");

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

      // Verificar que el nombre de usuario no está en uso por otro usuario
      if (existingUser['userName'] != editUserViewModel.userName) {
        final usernameCheck = await BaseService.client
            .from('User')
            .select()
            .eq('userName', editUserViewModel.userName)
            .neq('id', editUserViewModel.id)
            .maybeSingle();
        
        if (usernameCheck != null) {
          return {'success': false, 'message': 'El nombre de usuario ya está en uso'};
        }
      }

      print("Preparando los datos de actualización...");

      // Preparar los datos para actualización
      final Map<String, dynamic> updateData = {};

      // Solo agregar campos que han cambiado
      if (existingUser['name'] != editUserViewModel.name) {
        updateData['name'] = editUserViewModel.name;
      }
      if (existingUser['userName'] != editUserViewModel.userName) {
        updateData['userName'] = editUserViewModel.userName;
      }
      if (existingUser['email'] != editUserViewModel.email) {
        updateData['email'] = editUserViewModel.email;
      }
      if (existingUser['phoneNumber'] != editUserViewModel.phoneNumber) {
        updateData['phoneNumber'] = editUserViewModel.phoneNumber;
      }
      if (existingUser['address'] != editUserViewModel.address) {
        updateData['address'] = editUserViewModel.address;
      }
      if (editUserViewModel.password.isNotEmpty) {
        updateData['password'] = editUserViewModel.password;
        updateData['confirmPassword'] = editUserViewModel.confirmPassword;
      }
      if (editUserViewModel.image != null && existingUser['image'] != editUserViewModel.image) {
        updateData['image'] = editUserViewModel.image;
      }
      if (existingUser['genres'] != editUserViewModel.genres) {
        updateData['genres'] = editUserViewModel.genres;
      }
      if (existingUser['description'] != editUserViewModel.description) {
        updateData['description'] = editUserViewModel.description;
      }

      print("Datos a actualizar: $updateData");

      // Si no hay cambios, retornar éxito sin actualizar
      if (updateData.isEmpty) {
        print("No hay cambios para actualizar");
        return {'success': true, 'message': 'No hay cambios para actualizar', 'data': existingUser};
      }

      // Actualizar el usuario y obtener los datos actualizados en una sola operación
      print("Intentando actualizar usuario...");
      final response = await BaseService.client
          .from('User')
          .update(updateData)
          .eq('id', editUserViewModel.id)
          .select()
          .single();

      print("Respuesta de la actualización: $response");

      if (response != null) {
        print("Usuario actualizado exitosamente");
        print("Nuevos datos:");
        print("ID: ${response['id']}");
        print("Nombre: ${response['name']}");
        print("Email: ${response['email']}");
        return {'success': true, 'message': 'Usuario actualizado exitosamente', 'data': response};
      } else {
        print("Error: No se pudo actualizar el usuario");
        return {'success': false, 'message': 'Error al editar la información del usuario'};
      }
    } catch (ex) {
      print("Error en editUser: $ex");
      return {'success': false, 'message': ex.toString()};
    }
  }

  // Método asíncrono que obtiene los datos de un usuario.
  Future<Map<String, dynamic>> getUserById(String userId) async {
    try {
      // Comprobamos si la conexión a Supabase está activa.
      if (BaseService.client == null) {
        return {'success': false, 'message': 'Error de conexión a la base de datos.'};
      }

      // Llamada a la base de datos para obtener los datos del usuario.
      final response = await BaseService.client
          .from('User')
          .select()
          .eq('id', userId)
          .maybeSingle();

      // Verificamos si la respuesta contiene datos.
      if (response != null && response.isNotEmpty) {
        return {'success': true, 'message': 'Usuario obtenido correctamente', 'data': response};
      } else {
        return {'success': false, 'message': 'No se ha encontrado el usuario'};
      }
    } catch (ex) {
      // Si ocurre alguna excepción, devolverla.
      return {'success': false, 'message': ex.toString()};
    }
  }

  /* Método que obtiene los géneros seleccionados por el usuario.
    Parámetros:
      - userId: Cadena con el identificador del usuario.
    Return:
      - Lista con las categorías seleccionadas por el usuario.
  */
  Future<List<String>> getUserGenres(String userId) async {
    try {
      final response = await BaseService.client
          .from('User')
          .select('genres')
          .eq('id', userId)
          .single();

      if (response == null || response['genres'] == null) {
        return [];
      }

      final genres = response['genres'];
      if (genres is String) {
        return genres.split(',').map((e) => e.trim()).toList();
      } else if (genres is List) {
        return List<String>.from(genres);
      } else {
        return [];
      }
    } catch (e) {
      print('Error obteniendo géneros: $e');
      return [];
    }
  }

  // Obtener la lista de libros favoritos del usuario
  Future<Map<String, dynamic>> getFavorites() async {
    try {
      final currentUser = BaseService.client.auth.currentUser;
      if (currentUser == null) {
        print("Usuario no autenticado");
        return {'favorites': []};
      }

      final response = await BaseService.client
          .from('User')
          .select('favorites')
          .eq('id', currentUser.id)
          .single();

      if (response != null && response['favorites'] != null) {
        return {'favorites': response['favorites']};
      } else {
        return {'favorites': []};
      }
    } catch (error) {
      print("Error al obtener favoritos: $error");
      return {'favorites': []};
    }
  }

  // Agregar un libro a los favoritos
  Future<void> addToFavorites(int bookId) async {
    try {
      final currentUser = BaseService.client.auth.currentUser;
      if (currentUser == null) {
        print("Usuario no autenticado");
        return;
      }

      // Obtener la lista actual de favoritos
      final response = await BaseService.client
          .from('User')
          .select('favorites')
          .eq('id', currentUser.id)
          .single();

      if (response != null) {
        List<String> currentFavorites = List<String>.from(response['favorites'] ?? []);

        print("Lista de favoritos actual: $currentFavorites");

        // Agregar el nuevo favorito si no está ya en la lista
        if (!currentFavorites.contains(bookId.toString())) {
          currentFavorites.add(bookId.toString());
          print("Nuevo favorito añadido: $bookId");

          // Actualizar la lista de favoritos como un array de texto
          final updateResponse = await BaseService.client
              .from('User')
              .update({'favorites': currentFavorites})
              .eq('id', currentUser.id)
              .select();

          print("Respuesta de actualización: $updateResponse");
          if (updateResponse != null) {
            print("Libro agregado a favoritos correctamente.");
          } else {
            print("Error al actualizar la lista de favoritos.");
          }
        } else {
          print("El libro ya está en favoritos.");
        }
      }
    } catch (error) {
      print("Error al agregar a favoritos: $error");
    }
  }



  // Eliminar un libro de los favoritos
  Future<void> removeFromFavorites(int bookId) async {
    try {
      final currentUser = BaseService.client.auth.currentUser;
      if (currentUser == null) {
        print("Usuario no autenticado");
        return;
      }

      // Obtener la lista actual de favoritos
      final response = await BaseService.client
          .from('User')
          .select('favorites')
          .eq('id', currentUser.id)
          .single();

      if (response != null && response['favorites'] != null) {
        List<String> currentFavorites = List<String>.from(response['favorites']);

        // Eliminar el libro de la lista de favoritos
        currentFavorites.remove(bookId.toString());

        // Actualizar la lista de favoritos en la base de datos
        await BaseService.client
            .from('User')
            .update({'favorites': currentFavorites})
            .eq('id', currentUser.id);

        print("Libro eliminado de favoritos.");
      }
    } catch (error) {
      print("Error al eliminar de favoritos: $error");
      throw Exception('Error al eliminar de favoritos: $error');
    }
  }


  Future<User?> getCurrentUserById(String? userId) async {
    if (BaseService.client == null || userId == null) {
      return null;
    }

    try {
      final response = await BaseService.client
          .from("User")
          .select()
          .eq("id", userId)
          .single();

      if (response != null) {
        return User.fromJson(response);
      }
    } catch (e) {
      print('Error al obtener el usuario: $e');
    }

    return null;
  }

  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    // Creamos el filtro compuesto para búsqueda por nombre o nombre de usuario
    final filters = [
      "name.ilike.%$query%",
      "userName.ilike.%$query%",
    ].join(',');

    // Realizamos la consulta a la base de datos usando Supabase
    final List<dynamic> response = await BaseService.client
        .from('User')
        .select()
        .or(filters);

    // Devolvemos los resultados como una lista de mapas
    return response.map((e) => Map<String, dynamic>.from(e)).toList();
  }


  Future<User> getCurrentUser() async {
    final userId = await getCurrentUser();

    final response = await BaseService.client
        .from('User') // Usa el nombre exacto de tu tabla en Supabase
        .select()
        .eq('id', userId)
        .single();

    if (response == null) {
      throw Exception('Usuario no encontrado');
    }

    return User.fromJson(response);
  }


  Future<Map<String, dynamic>> getUserNameById(String userId) async {
    try {
      // Comprobamos si la conexión a Supabase está activa.
      if (BaseService.client == null) {
        return {
          'success': false,
          'message': 'Error de conexión a la base de datos.'
        };
      }

      // Llamada a la base de datos para obtener los datos del usuario.
      final response = await BaseService.client
          .from('User')
          .select('userName')
          .eq('id', userId)
          .maybeSingle();

      // Verificamos si la respuesta contiene datos.
      if (response != null && response.isNotEmpty) {
        return {
          'success': true,
          'message': 'Usuario obtenido correctamente',
          'data': response
        };
      } else {
        return {
          'success': false,
          'message': 'No se ha encontrado el usuario'
        };
      }
    } catch (ex) {
      // Si ocurre alguna excepción, devolverla.
      return {
        'success': false,
        'message': ex.toString()
      };
    }
  }

}
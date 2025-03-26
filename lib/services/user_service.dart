import 'package:booknest/entities/viewmodels/user_view_model.dart';
import 'package:booknest/services/base_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

      // Verificar que el usuario existe
      final existingUser = await BaseService.client.from('User').select().eq('id', editUserViewModel.id).single();
      if (existingUser == null) {
        return {'success': false, 'message': 'Usuario no encontrado'};
      }

      print("Usuario extraído de la base de datos: $existingUser");
      
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

      print("Datos a actualizar: $updateData");

      // Si no hay cambios, retornar éxito sin actualizar
      if (updateData.isEmpty) {
        return {'success': true, 'message': 'No hay cambios para actualizar', 'data': existingUser};
      }

      final response = await BaseService.client
        .from('User')
        .update(updateData)
        .eq('id', editUserViewModel.id)
        .select(); // Esto retorna los datos actualizados inmediatamente si todo va bien.

      if (response.error != null) {
      print("Error en la actualización: ${response.error!.message}");
      return {'success': false, 'message': 'Error al actualizar: ${response.error!.message}'};
}

      print("Respuesta de actualización: $response");

      if (response == null || response.isEmpty) {
        return {'success': false, 'message': 'Error al actualizar el usuario en la base de datos.'};
      }


      // Luego obtenemos los datos actualizados
      final updatedUser = await getUserById(editUserViewModel.id);

      print("Nombre del usuario actualizado: ${updatedUser['data']['name']}");
      print("Username del usuario actualizado: ${updatedUser['data']['userName']}");
      print("Address del usuario actualizado: ${updatedUser['data']['Address']}");
      print("Phone del usuario actualizado: ${updatedUser['data']['phoneNumber']}");
      print("Email del usuario actualizado: ${updatedUser['data']['email']}");
      print("Password del usuario actualizado: ${updatedUser['data']['password']}");
      print("Confirmpassword del usuario actualizado: ${updatedUser['data']['confirmPassword']}");
      print("Image del usuario actualizado: ${updatedUser['data']['image']}");
      print("Genres del usuario actualizado: ${updatedUser['data']['genres']}");

      if (updatedUser['success']) {
        return {'success': true, 'message': 'Usuario actualizado exitosamente', 'data': updatedUser};
      } else {
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

}

extension on PostgrestList {
  get error => null;
}
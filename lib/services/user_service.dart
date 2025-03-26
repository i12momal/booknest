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

      // Llamada a la base de datos para editar el usuario y devolver los datos actualizados.
      final response = await BaseService.client.from('User').update({
        'name': editUserViewModel.name,
        'userName': editUserViewModel.userName,
        'email': editUserViewModel.email,
        'phoneNumber': editUserViewModel.phoneNumber,
        'address': editUserViewModel.address,
        if (editUserViewModel.password.isNotEmpty) 'password': editUserViewModel.password,
        if (editUserViewModel.image != null) 'image': editUserViewModel.image,
        'genres': editUserViewModel.genres,
        'role': editUserViewModel.role,
      }).eq('id', editUserViewModel.id).select().single();

      // Verificamos si la respuesta contiene datos.
      if (response != null) {
        return {'success': true, 'message': 'Usuario actualizado exitosamente', 'data': response};
      } else {
        return {'success': false, 'message': 'Error al editar la información del usuario'};
      }
    } catch (ex) {
      // Si ocurre alguna excepción, devolverla.
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
      final response = await BaseService.client.from('User').select().eq('id', userId).single();

      // Verificamos si la respuesta contiene datos.
      if (response != null && response.isNotEmpty) {
        print(response);
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
import 'package:booknest/services/base_service.dart';

// Servicio con los métodos de negocio de la entidad Usuario.
class UserService extends BaseService {

  /* 
    Método asíncrono que permite el registro de un nuevo usuario.
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
  Future<Map<String, dynamic>> registerUser(String name, String userName, int age, String email, int phoneNumber, String address, String password, String image) async {
    try {
      // Comprobamos si la conexión a Supabase está activa.
      if (BaseService.client == null) {
        return {'success': false, 'message': 'Error de conexión a la base de datos.'};
      }

      // Llamada a la base de datos para insertar el usuario y devolver los datos insertados.
      final response = await BaseService.client.from('User').insert({
        'name': name,
        'userName': userName,
        'age': age,
        'email': email,
        'phoneNumber': phoneNumber,
        'address': address,
        'password': password,
        'image': image,
        'role': 'usuario',
      }).select().single();

      // Verificamos si la respuesta contiene datos.
      if (response != null) {
        return {'success': true, 'message': 'Usuario registrado exitosamente', 'data': response};
      } else {
        return {'success': false, 'message': 'Error al registrar el usuario'};
      }
    } catch (ex) {
      // Si ocurre alguna excepción, devolverla.
      return {'success': false, 'message': ex.toString()};
    }
  }
}

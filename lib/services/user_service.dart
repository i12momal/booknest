import 'package:booknest/services/base_service.dart';

class UserService extends BaseService {

  Future<Map<String, dynamic>> registerUser(
    String name,
    String userName,
    int age,
    String email,
    int phoneNumber,
    String address,
    String password,
    String image
  ) async {
    try {
      // Comprobar si la conexión a Supabase está activa
      if (BaseService.client == null) {
        print('Error: La conexión a Supabase no está activa.');
        return {'success': false, 'message': 'Error de conexión a la base de datos.'};
      }

      // Imprimir los datos antes de hacer la llamada para verificar que los parámetros son correctos
      print('Intentando registrar usuario con los siguientes datos:');
      print('Name: $name, UserName: $userName, Age: $age, Email: $email, PhoneNumber: $phoneNumber, Address: $address, Image: $image');

      // Llamada a la base de datos para insertar el usuario y devolver los datos insertados
      final response = await BaseService.client.from('User').insert({
        'name': name,
        'userName': userName,
        'age': age,
        'email': email,
        'phoneNumber': phoneNumber,
        'address': address,
        'password': password,
        'image': image,
        'role': 'usuario', // Rol predeterminado
      }).select().single();

      // Verificar si la respuesta tiene datos
      if (response != null) {
        print('Usuario registrado con éxito');
        print('Datos del usuario: $response');
        return {'success': true, 'message': 'Usuario registrado exitosamente', 'data': response};
      } else {
        return {'success': false, 'message': 'Error al registrar el usuario'};
      }
    } catch (ex) {
      // Si ocurre alguna excepción, mostrarla
      print('Exception: $ex');
      return {'success': false, 'message': ex.toString()};
    }
  }
}

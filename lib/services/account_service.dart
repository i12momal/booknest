import 'dart:convert';
import 'dart:io';
import 'package:booknest/entities/viewmodels/account_view_model.dart';
import 'package:booknest/services/base_service.dart';
import 'package:crypto/crypto.dart';

// Servicio con los métodos de negocio de la entidad Usuario.
class AccountService extends BaseService {

  /* Método asíncrono que permite el inicio de sesión de un usuario.
    Parámetros:
      - userName: Cadena con el nombre de usuario.
      - password: Cadena con la contraseña del usuario.
    Return: 
      Mapa con la clave:
        - success: Indica si el inicio de sesión fue exitoso (true o false).
        - message: Proporciona un mensaje de estado.
        - data (Opcional): Información del usuario registrado si la operación fue exitosa.
  */
  Future<Map<String, dynamic>> loginUser(LoginUserViewModel loginUserViewModel) async {
    try {
      print('Verificando el login para: $loginUserViewModel.userName');
      
      if (BaseService.client == null) {
        return {'success': false, 'message': 'Error de conexión a la base de datos.'};
      }

      final response = await BaseService.client
          .from('User')
          .select()
          .eq('userName', loginUserViewModel.userName)
          .eq('password', generatePasswordHash(loginUserViewModel.password))
          .maybeSingle();

      print('Respuesta de la base de datos: $response');

      if (response != null) {
        return {'success': true, 'message': 'Login exitoso', 'data': response};
      } else {
        return {'success': false, 'message': 'Usuario o contraseña incorrectos'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error en el login: ${e.toString()}'};
    }
  }


  /* Método asíncrono que permite el registro de un nuevo usuario.
    Parámetros:
      - name: Cadena con el nombre completo del usuario.
      - userName: Cadena con el nombre de usuario.
      - email: Cadena con el email del usuario.
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
  Future<Map<String, dynamic>> registerUser(RegisterUserViewModel registerUserViewModel) async {
    try {
      // Comprobamos si la conexión a Supabase está activa.
      if (BaseService.client == null) {
        return {'success': false, 'message': 'Error de conexión a la base de datos.'};
      }

      // Llamada a la base de datos para insertar el usuario y devolver los datos insertados.
      final response = await BaseService.client.from('User').insert({
        'name': registerUserViewModel.name,
        'userName': registerUserViewModel.userName,
        'email': registerUserViewModel.email,
        'phoneNumber': registerUserViewModel.phoneNumber,
        'address': registerUserViewModel.address,
        'password': registerUserViewModel.password,
        'confirmPassword': registerUserViewModel.confirmPassword,
        'image': registerUserViewModel.image,
        'genres': registerUserViewModel.genres,
        'role': registerUserViewModel.role,
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


  /* Método para subir una imagen a Supabase Storage.
     Parámetros:
      - imageFile: archivo de la imagen.
      - userName: nombre del usuario para crear el nombre con el que se va a almacenar la imagen.
  */
  Future<String?> uploadImageToSupabase(File imageFile, String userName) async {
    try {
      if (!await imageFile.exists()) {
        print("El archivo no existe en la ruta: ${imageFile.path}");
        return null;
      }

      // Extraer la extensión del archivo (.jpg, .png, etc.)
      final String fileExt = imageFile.path.split('.').last;
      final String fileName = 'profiles/$userName.$fileExt';
      print("Nombre del archivo: $fileName");

      // Intentar subir la imagen
      final response = await BaseService.client.storage.from('avatars').upload(fileName, imageFile);
      print("Respuesta de la carga: $response");

      // Obtener la URL pública de la imagen
      final String imageUrl = BaseService.client.storage.from('avatars').getPublicUrl(fileName);
      print("URL pública de la imagen: $imageUrl");

      return imageUrl;
    } catch (e, stacktrace) {
      print('Error al subir la imagen: $e');
      print('Detalles: $stacktrace');
      return null;
    }
  }

  /* Método para generar el hash de la contraseña */
  String generatePasswordHash(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}

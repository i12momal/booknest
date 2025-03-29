import 'dart:convert';
import 'dart:io';
import 'package:booknest/entities/viewmodels/account_view_model.dart';
import 'package:booknest/entities/models/user_session.dart';
import 'package:booknest/services/base_service.dart';
import 'package:crypto/crypto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Servicio con los métodos de negocio para el inicio de sesión y registro del Usuario.
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
      print('Verificando el login para: ${loginUserViewModel.userName}');
      
      if (BaseService.client == null) {
        return {'success': false, 'message': 'Error de conexión a la base de datos.'};
      }

      // Crear el email usando el nombre de usuario
      final String email = "${loginUserViewModel.userName}@booknest.com";
      print('Email generado para login: $email');

      // Intentar autenticar con Supabase
      final AuthResponse authResponse = await BaseService.client.auth.signInWithPassword(
        email: email,
        password: loginUserViewModel.password,
      );

      if (authResponse.user == null) {
        print('Error: No se pudo autenticar el usuario');
        return {'success': false, 'message': 'Usuario o contraseña incorrectos'};
      }

      // Obtener el ID del usuario autenticado
      final String userId = authResponse.user!.id;
      print('Usuario autenticado con ID: $userId');

      // Obtener los datos completos del usuario de la tabla User
      final response = await BaseService.client
          .from('User')
          .select()
          .eq('id', userId)
          .single();

      print('Datos del usuario encontrados: $response');

      if (response != null) {
        // Almacenar el userId cuando el login es exitoso
        await UserSession.setUserId(userId);
        print("User ID guardado en SharedPreferences: $userId");
        
        return {'success': true, 'message': 'Login exitoso', 'data': response};
      } else {
        print('No se encontró el usuario en la tabla User');
        return {'success': false, 'message': 'Error al obtener datos del usuario'};
      }
    } catch (e) {
      print('Error en loginUser: $e');
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
      if (BaseService.client == null) {
        return {'success': false, 'message': 'Error de conexión a la base de datos.'};
      }

      print("Iniciando registro de usuario...");
      print("Nombre de usuario: ${registerUserViewModel.userName}");
      print("Contraseña: ${registerUserViewModel.password}");

      // Generar el hash de la contraseña
      final String passwordHash = generatePasswordHash(registerUserViewModel.password);
      print("Hash de la contraseña: $passwordHash");

      // Registrar el usuario en auth.users sin requerir confirmación
      final AuthResponse authResponse = await BaseService.client.auth.signUp(
        email: registerUserViewModel.email,
        password: registerUserViewModel.password,
        data: {
          'userName': registerUserViewModel.userName,
        },// Desactivamos la redirección por correo
      );

      if (authResponse.user == null) {
        print("Error: No se pudo crear el usuario en auth.users");
        return {'success': false, 'message': 'Error al registrar el usuario en la autenticación'};
      }

      // Obtener el ID del usuario autenticado
      final String userId = authResponse.user!.id;
      print("ID del usuario autenticado (auth.uid): $userId");

      // Crear el registro en la tabla User con el mismo ID
      print("Creando registro en la tabla User...");
      final Map<String, dynamic> userData = {
        'id': userId,
        'name': registerUserViewModel.name,
        'userName': registerUserViewModel.userName,
        'email': registerUserViewModel.email,
        'phoneNumber': registerUserViewModel.phoneNumber,
        'address': registerUserViewModel.address,
        'password': passwordHash,
        'confirmPassword': passwordHash,
        'image': registerUserViewModel.image,
        'genres': registerUserViewModel.genres,
        'role': registerUserViewModel.role,
      };
      print("Datos a insertar: $userData");

      final response = await BaseService.client.from('User').insert(userData).select().single();

      print("Respuesta de la inserción en User: $response");

      if (response != null) {
        print("Usuario registrado exitosamente");
        print("ID en la tabla User: ${response['id']}");
        print("Nombre: ${response['name']}");
        print("Nombre de usuario: ${response['userName']}");
        print("Email: ${response['email']}");
        print("Contraseña hash: ${response['password']}");
        
        // Iniciar sesión automáticamente después del registro
        await UserSession.setUserId(userId);
        print("User ID guardado en SharedPreferences: $userId");

        return {
          'success': true,
          'message': 'Usuario registrado exitosamente. Ya puedes iniciar sesión.',
          'data': response
        };
      } else {
        print("Error: No se pudo crear el registro en la tabla User");
        return {'success': false, 'message': 'Error al registrar el usuario'};
      }
    } catch (ex) {
      print("Error en registerUser: $ex");
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
      
      // Crear un nombre único para la imagen
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'profiles/${userName}_$timestamp.$fileExt';
      print("Creando nombre de archivo: $fileName");

      // Subir la imagen
      try {
        final response = await BaseService.client.storage.from('avatars').upload(
          fileName,
          imageFile,
          fileOptions: const FileOptions(
            cacheControl: '3600',
            upsert: true,
          ),
        );
        print("Respuesta de la carga: $response");

        // Obtener la URL pública de la imagen
        final String imageUrl = BaseService.client.storage.from('avatars').getPublicUrl(fileName);
        print("URL pública de la imagen: $imageUrl");

        return imageUrl;
      } catch (uploadError) {
        print('Error al subir la nueva imagen: $uploadError');
        return null;
      }
    } catch (e, stacktrace) {
      print('Error general en uploadImageToSupabase: $e');
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

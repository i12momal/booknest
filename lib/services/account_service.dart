import 'dart:convert';
import 'dart:io';
import 'package:booknest/entities/viewmodels/account_view_model.dart';
import 'package:booknest/entities/models/user_session.dart';
import 'package:booknest/entities/models/user_model.dart' as user;
import 'package:booknest/services/base_service.dart';
import 'package:crypto/crypto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Servicio con los métodos de negocio para el inicio de sesión y registro del Usuario.
class AccountService extends BaseService {

  // Método asíncrono que permite el inicio de sesión de un usuario.
  Future<Map<String, dynamic>> loginUser(LoginUserViewModel loginUserViewModel) async {
    try {
      print('Verificando el login para: ${loginUserViewModel.userName}');

      if (BaseService.client == null) {
        return {'success': false, 'message': 'Error de conexión a la base de datos.'};
      }

      // Buscar el usuario por nombre de usuario en la tabla
      final userResponse = await BaseService.client
          .from('User')
          .select()
          .eq('userName', loginUserViewModel.userName)
          .single();

      if (userResponse == null) {
        return {'success': false, 'message': 'Usuario no encontrado'};
      }

      final String email = userResponse['email'];
      final String userId = userResponse['id'];

      // Iniciar sesión en Supabase Auth usando el email y la contraseña original
      try {
        final AuthResponse authResponse = await BaseService.client.auth.signInWithPassword(
          email: email,
          password: loginUserViewModel.password,
        );
        print("Sesión iniciada en Supabase Auth: ${authResponse.user?.id}");

        // Guardar el ID del usuario en sesión
        await UserSession.setUserId(userId);
        print("User ID guardado en SharedPreferences: $userId");

        return {
          'success': true,
          'message': 'Login exitoso',
          'data': userResponse
        };
      } catch (authError) {
        print("Error de autenticación en Supabase Auth: $authError");
        return {'success': false, 'message': 'Usuario o contraseña incorrectos'};
      }

    } catch (e) {
      print('Error en loginUser: $e');
      return {'success': false, 'message': 'Error de autenticación. Verifica tu conexión a internet y que los datos introducidos son correctos.'};
    }
  }

  // Método asíncrono que permite el registro de un nuevo usuario.
  Future<Map<String, dynamic>> registerUser(RegisterUserViewModel registerUserViewModel) async {
    try {
      if (BaseService.client == null) {
        return {'success': false, 'message': 'Error de conexión a la base de datos.'};
      }

      // Verificar si el usuario ya existe
      final existingUsers = await BaseService.client.from('User').select('id').eq('userName', registerUserViewModel.userName);

      if (existingUsers.isNotEmpty) {
        print("El usuario ya existe en la tabla User");
        return {'success': false, 'message': 'El nombre de usuario ya está en uso'};
      }

      // Generar el hash de la contraseña para almacenar en la tabla User
      final String passwordHash = generatePasswordHash(registerUserViewModel.password);
      print("Hash de la contraseña para tabla User: $passwordHash");

      // Crear usuario en Supabase Auth
      String? authUserId;
      try {
        final AuthResponse authResponse = await BaseService.client.auth.signUp(
          email: registerUserViewModel.email,
          password: registerUserViewModel.password,
        );
        authUserId = authResponse.user?.id;
        print("Usuario creado en Supabase Auth: $authUserId");
      } catch (authError) {
        print("Error al crear usuario en Supabase Auth: $authError");
        return {'success': false, 'message': 'Error al crear el usuario en el sistema de autenticación'};
      }

      if (authUserId == null) {
        return {'success': false, 'message': 'Error al obtener el ID del usuario autenticado'};
      }

      // Crear el registro en la tabla User usando el ID de Supabase Auth
      final Map<String, dynamic> userData = {
        'id': authUserId,
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
        'description': registerUserViewModel.description,
      };

      final response = await BaseService.client.from('User').insert(userData).select().single();

      if (response != null) {
        // Iniciar sesión automáticamente después del registro
        await UserSession.setUserId(response['id']);
        print("User ID guardado en SharedPreferences: ${response['id']}");

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


  // Método para subir una imagen a Supabase Storage.
  Future<String?> uploadProfileImage(File imageFile, String userName) async {
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

      // Buscar imágenes existentes del usuario
      try {
        final List<FileObject> existingFiles = await BaseService.client.storage
            .from('avatars')
            .list(path: 'profiles/');
        
        // Filtrar archivos que contengan el nombre de usuario
        final userFiles = existingFiles.where((file) => 
          file.name.startsWith('${userName}_') && 
          file.name.endsWith('.$fileExt')
        ).toList();

        // Eliminar las imágenes existentes del usuario
        if (userFiles.isNotEmpty) {
          print("Encontradas ${userFiles.length} imágenes existentes del usuario");
          for (var file in userFiles) {
            try {
              await BaseService.client.storage
                  .from('avatars')
                  .remove(['profiles/${file.name}']);
              print("Imagen anterior eliminada: ${file.name}");
            } catch (deleteError) {
              print("Error al eliminar imagen anterior: $deleteError");
            }
          }
        }
      } catch (listError) {
        print("Error al listar archivos existentes: $listError");
      }

      // Subir la nueva imagen
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

  // Método para generar el hash de la contraseña.
  String generatePasswordHash(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    final String hash = digest.toString();
    return hash;
  }

  // Método asíncrono que obtiene el ID del usuario actualmente autenticado.
  Future<String?> getCurrentUserId() async {
    if (BaseService.client == null) {
      return null;
    }

    // Obtener el ID del usuario desde SharedPreferences
    final userId = await UserSession.getUserId();
    if (userId != null) {
      return userId;
    }

    // Si no hay ID en SharedPreferences, intentar obtenerlo de la autenticación
    final currentUser = BaseService.client.auth.currentUser;
    return currentUser?.id;
  }

  // Método asíncrono que obtiene el ID del usuario actualmente autenticado.
  Future<String> getCurrentUserIdNonNull() async {
    if (BaseService.client == null) {
      return 'No se pudo establecer conexión';
    }

    // Obtener el ID del usuario desde SharedPreferences
    final userId = await UserSession.getUserId();
    if (userId != null) {
      return userId;
    }

    // Si no hay ID en SharedPreferences, intentar obtenerlo de la autenticación
    final currentUser = BaseService.client.auth.currentUser;
    return currentUser!.id;
  }

  // Método asíncrono para el cierre de sesión de un usuario.
  Future<Map<String, dynamic>> logoutUser() async {
    try {
      // Cerrar sesión en Supabase Auth
      await BaseService.client.auth.signOut();
      print("Sesión cerrada en Supabase Auth");

      return {'success': true, 'message': 'Sesión cerrada correctamente'};
    } catch (e) {
      print("Error en logoutUser: $e");
      return {
        'success': false,
        'message': 'No se pudo cerrar sesión. Intenta de nuevo.'
      };
    }
  }

  // Método asíncrono para comprobar si un nombre de usuario ya existe.
  Future<bool> checkUsernameExists(String username) async {
    final response = await Supabase.instance.client
      .from('User')
      .select('id')
      .eq('userName', username)
      .maybeSingle();

    return response != null;
  }

  // Método asíncrono para comprobar si un correo electrónico ya existe.
  Future<bool> checkEmailExists(String email) async {
    final response = await Supabase.instance.client
      .from('User')
      .select('id')
      .eq('email', email)
      .maybeSingle();

    return response != null;
  }

  // Método asíncrono que obtiene el usuario actual.
  Future<user.User> getCurrentUser() async {
    final userId = await getCurrentUserIdNonNull();

    final response = await BaseService.client
        .from('User')
        .select()
        .eq('id', userId)
        .single();

    if (response == null) {
      throw Exception('Usuario no encontrado');
    }

    return user.User.fromJson(response);
  }

}

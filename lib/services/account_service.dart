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
      print('Contraseña proporcionada: ${loginUserViewModel.password}');
      
      if (BaseService.client == null) {
        return {'success': false, 'message': 'Error de conexión a la base de datos.'};
      }

      // Obtener el usuario completo de la tabla User
      final userResponse = await BaseService.client
          .from('User')
          .select()
          .eq('userName', loginUserViewModel.userName)
          .single();

      if (userResponse == null) {
        return {'success': false, 'message': 'Usuario no encontrado'};
      }

      print("Datos del usuario encontrados: $userResponse");


      // Generar el hash de la contraseña proporcionada
      final String inputPasswordHash = generatePasswordHash(loginUserViewModel.password);
      print("Hash de la contraseña proporcionada: $inputPasswordHash");
      print("Hash almacenado: ${userResponse['password']}");


      // Verificar si la contraseña coincide
      if (userResponse['password'] != inputPasswordHash) {
        print("Las contraseñas no coinciden");
        return {'success': false, 'message': 'Contraseña incorrecta'};
      }

      // Si la contraseña coincide, obtener el ID del usuario
      final String userId = userResponse['id'];
      print('Usuario autenticado con ID: $userId');

      // Iniciar sesión en Supabase Auth
      try {
        final AuthResponse res = await BaseService.client.auth.signInWithPassword(
          email: userResponse['email'],
          password: userResponse['password'],
        );
        print("Sesión iniciada en Supabase Auth: ${res.user?.id}");
      } catch (authError) {
        print("Error al iniciar sesión en Supabase Auth: $authError");
        // Si falla la autenticación en Supabase, aún permitimos el login
        // ya que la contraseña es correcta en nuestra base de datos
      }

      // Almacenar el userId cuando el login es exitoso
      await UserSession.setUserId(userId);
      print("User ID guardado en SharedPreferences: $userId");
      
      return {'success': true, 'message': 'Login exitoso', 'data': userResponse};
    } catch (e) {
      print('Error en loginUser: $e');
      return {'success': false, 'message': 'Error de conexión: no se pudo establecer conexión con el servidor de autenticación. Verifica tu conexión a internet o intenta nuevamente más tarde.'};
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
      print("Email: ${registerUserViewModel.email}");
      print("Contraseña original: ${registerUserViewModel.password}");
      print("Pin recuperacion: ${registerUserViewModel.pinRecuperacion}");

      // Verificar si el usuario ya existe
      final existingUsers = await BaseService.client
          .from('User')
          .select('id')
          .eq('userName', registerUserViewModel.userName);

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
          password: passwordHash,
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
      print("Creando registro en la tabla User...");
      final Map<String, dynamic> userData = {
        'id': authUserId, // Usar el ID de Supabase Auth
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
        'pinRecuperacion': registerUserViewModel.pinRecuperacion,
        'description': registerUserViewModel.description,
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

  // Método asíncrono para comprobar si el email y el pin proporcionados en la recuepración de contraseña son correctos
  Future<Map<String, dynamic>> verifyEmailAndPin(String email, String pin) async {
    try {
      if (BaseService.client == null) {
        return {'success': false, 'message': 'Error de conexión a la base de datos.'};
      }

      // Obtener el usuario completo de la tabla User
      final userResponse = await BaseService.client
          .from('User')
          .select()
          .eq('email', email)
          .single();

      if (userResponse == null) {
        return {'success': false, 'message': 'Usuario no encontrado'};
      }

      // Verificar si el pin coincide
      if (userResponse['pinRecuperacion'] != pin) {
        print("El pin no coincide");
        return {'success': false, 'message': 'Pin incorrecto'};
      }
      
      return {'success': true, 'message': 'El email y el pin coinciden', 'data': userResponse};
    } catch (e) {
      print('Error en verifyEmailAndPin: $e');
      return {'success': false, 'message': 'Error de verificación. Los campos ingresados son incorrectos.'};
    }
  }

  // Función para actualizar la contraseña en caso de pérdida
  Future<Map<String, dynamic>> updatePassword(String email, String pin, String newPassword) async {
    try {
      if (BaseService.client == null) {
        return {'success': false, 'message': 'Error de conexión a la base de datos.'};
      }

      final userResponse = await BaseService.client
          .from('User')
          .select()
          .eq('email', email)
          .single();

      if (userResponse == null) {
        return {'success': false, 'message': 'Usuario no encontrado'};
      }

      if (userResponse['pinRecuperacion'] != pin) {
        return {'success': false, 'message': 'PIN incorrecto'};
      }

      // Crear el hash de la nueva contraseña
      final bytes = utf8.encode(newPassword);
      final hash = sha256.convert(bytes).toString();

      // Actualizar la contraseña en la base de datos
      final updateResponse = await BaseService.client
          .from('User')
          .update({'password': hash, 'confirmPassword': hash})
          .eq('email', email);

      return {'success': true, 'message': 'Contraseña actualizada con éxito'};
    } catch (e) {
      print('Error en updatePassword: $e');
      return {'success': false, 'message': 'Error al actualizar la contraseña'};
    }
  }


  /* Método para subir una imagen a Supabase Storage.
     Parámetros:
      - imageFile: archivo de la imagen.
      - userName: nombre del usuario para crear el nombre con el que se va a almacenar la imagen.
  */
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

  /* Método para generar el hash de la contraseña */
  String generatePasswordHash(String password) {
    print("Generando hash para contraseña: $password");
    final bytes = utf8.encode(password);
    print("Bytes generados: ${bytes.toString()}");
    final digest = sha256.convert(bytes);
    print("Digest generado: ${digest.toString()}");
    final String hash = digest.toString();
    print("Hash final: $hash");
    return hash;
  }

  /* Método asíncrono que obtiene el ID del usuario actualmente autenticado.
    Return: 
      String con el ID del usuario autenticado o null si no hay usuario autenticado.
  */
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

}

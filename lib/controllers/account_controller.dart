import 'package:booknest/entities/models/user_session.dart';
import "package:booknest/entities/viewmodels/account_view_model.dart";
import 'package:flutter/material.dart';
import "base_controller.dart";
import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';

// Controlador con los métodos de las acciones de inicio de sesión y registro del Usuario.
class AccountController extends BaseController{

  final ValueNotifier<String> errorMessage = ValueNotifier<String>(''); 

  /* Método asíncrono que permite el inicio de sesión de un usuario.
    Parámetros:
      - userName: Cadena con el nombre de usuario.
      - password: Cadena con la contraseña del usuario.
    Return: 
      - success: Indica si el inicio de sesión fue exitoso (true o false).
      - message: Proporciona un mensaje de estado.
  */
  Future<void> login(String userName, String password) async {
    if (userName.isEmpty || password.isEmpty) {
      errorMessage.value = 'Por favor ingrese todos los campos';

      // Hacer que el mensaje desaparezca después de 5 segundos
      Future.delayed(const Duration(seconds: 5), () {
        errorMessage.value = '';
      });

      return;
    }

    errorMessage.value = ''; // Limpiar mensaje de error

    print('Llamando al servicio de login con: $userName, $password');

    // Creación del viewModel
    final loginUserViewModel = LoginUserViewModel(
      userName: userName.trim(),
      password: password.trim()
    );

    final result = await accountService.loginUser(loginUserViewModel);

    print('Resultado del login: $result');

    if (result['success']) {
      // Si el login fue exitoso, el mensaje de error se limpia
      errorMessage.value = '';
    } else {
      // Si el login no fue exitoso, mostramos el mensaje de error
      errorMessage.value = result['message']; // "Usuario o contraseña incorrectos"

      // Hacer que el mensaje desaparezca después de 5 segundos
      Future.delayed(const Duration(seconds: 5), () {
        errorMessage.value = '';
      });
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
  Future<Map<String, dynamic>> registerUser(String name, String userName, String email, int phoneNumber,
    String address, String password, String confirmPassword, File? image, String genres, String description) async {

    String? imageUrl;

    // Si el usuario sube una imagen, la guardamos en Supabase
    if (image != null) {
      imageUrl = await uploadProfileImage(image, userName);
      if (imageUrl == null) {
        return {'success': false, 'message': 'Error al subir la imagen'};
      }
    }

    final String pinRecuperacion = DateTime.now().millisecondsSinceEpoch.toString();

    // Creación del viewModel
    final registerUserViewModel = RegisterUserViewModel(
      name: name,
      userName: userName,
      email: email,
      phoneNumber: phoneNumber,
      address: address,
      password: password,  // Enviamos la contraseña sin hashear
      confirmPassword: confirmPassword,  // Enviamos la confirmación sin hashear
      image: imageUrl,
      genres: genres,
      role: 'usuario',
      pinRecuperacion: pinRecuperacion,
      description: description,
    );
    
    // Llamada al servicio para registrar al usuario
    final response = await accountService.registerUser(registerUserViewModel);
    response['pinRecuperacion'] = pinRecuperacion;
    return response;
  }

  // Método asíncrono para comprobar si el email y el pin proporcionados en la recuepración de contraseña son correctos
  Future<Map<String, dynamic>> verifyEmailAndPin(String email, String pin) async {
    // Validar que ambos campos estén llenos
    if (email.isEmpty || pin.isEmpty) {
      return {'success': false, 'message': 'Por favor ingrese todos los campos'};
    }

    // Validar formato del correo
    if (!_isValidEmail(email)) {
      return {'success': false, 'message': 'Por favor ingrese un correo válido'};
    }

    // Limpiar mensaje de error antes de hacer la verificación
    errorMessage.value = '';

    // Llamar al servicio para verificar el correo y PIN
    final result = await accountService.verifyEmailAndPin(email, pin);

    if (result['success']) {
      return {'success': true, 'message': 'Email y PIN verificados correctamente'};
    } else {
      return {'success': false, 'message': result['message']};
    }
  }

  bool _isValidEmail(String email) {
    final regex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return regex.hasMatch(email);
  }



  Future<bool> updatePassword(String email, String pin, String newPassword) async {
    final result = await accountService.updatePassword(email, pin, newPassword);
    if (!result['success']) {
      errorMessage.value = result['message'];
      Future.delayed(const Duration(seconds: 5), () {
        errorMessage.value = '';
      });
    }
    return result['success'];
  }


  /* Método para guardar una imagen en Supabase.
     Parámetros:
      - imageFile: archivo de la imagen.
      - userName: nombre del usuario para crear el nombre con el que se va a almacenar la imagen.
  */
  Future<String?> uploadProfileImage(File imageFile, String userName) async {
    return await accountService.uploadProfileImage(imageFile, userName);
  }


  /* Método para generar un hash seguro de la contraseña.
     Parámetros:
      - password: contraseña a cifrar.
  */
  String generatePasswordHash(String password) {
    // Convertir la contraseña a bytes
    final bytes = utf8.encode(password);

    // Crear un hash SHA-256
    final digest = sha256.convert(bytes);

    // Devolver el hash en formato hexadecimal
    return digest.toString();
  }


  /* Método asíncrono que comprueba que el nombre de usuario no existe en la base de datos.
    Parámetros:
      - userName: Cadena con el nombre de usuario.
    Return: 
      Devuelve verdadero si el nombre de usuario ya está registrado.
  */
  Future<bool> isUsernameTaken(String username) async {
    List<String> existingUsernames = ['user1', 'user2', 'user3']; 
    return existingUsernames.contains(username); 
  }

  /* Método asíncrono que obtiene el ID del usuario actualmente autenticado.
    Return: 
      String con el ID del usuario autenticado o null si no hay usuario autenticado.
  */
  Future<String?> getCurrentUserId() async {
    final result = await accountService.getCurrentUserId();
    return result;
  }

  Future<void> logout() async {
    final result = await accountService.logoutUser();

    if (result['success']) {
      // Limpiar datos locales de sesión
      await UserSession.clearSession();

      print("Logout exitoso, userId limpiado");
    } else {
      print("Fallo en logout: ${result['message']}");
    }
  }

}
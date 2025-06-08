import 'dart:typed_data';

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

  // Método asíncrono que permite el inicio de sesión de un usuario.
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

  // Método asíncrono que permite el registro de un nuevo usuario.
  Future<Map<String, dynamic>> registerUser(String name, String userName, String email, int phoneNumber,
    String address, String password, String confirmPassword, dynamic image, String genres, String description) async {

      String? imageUrl;

      if (image != null) {
        if (image is File) {
          imageUrl = await uploadProfileImageMobile(image, userName);
        } else if (image is Uint8List) {
          imageUrl = await uploadProfileImageWeb(image, userName);
        }

        if (imageUrl == null) {
          return {'success': false, 'message': 'Error al subir la imagen'};
        }
      }

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
      description: description,
    );
    
    // Llamada al servicio para registrar al usuario
    final response = await accountService.registerUser(registerUserViewModel);
    return response;
  }

  // Función para subir imagen a supabase desde el móvil
  Future<String?> uploadProfileImageMobile(File imageFile, String userName) async {
    return await accountService.uploadProfileImageMobile(imageFile, userName);
  }

  // Función para subir imagen a supabase desde web
  Future<String?> uploadProfileImageWeb(Uint8List imageBytes, String userName) async {
    return await accountService.uploadProfileImageWeb(imageBytes, userName);
  }

  // Método para generar un hash seguro de la contraseña.
  String generatePasswordHash(String password) {
    // Convertir la contraseña a bytes
    final bytes = utf8.encode(password);

    // Crear un hash SHA-256
    final digest = sha256.convert(bytes);

    // Devolver el hash en formato hexadecimal
    return digest.toString();
  }

  // Método asíncrono que comprueba si el nombre de usuario existe en la base de datos.
  Future<bool> isUsernameTaken(String username) async {
    List<String> existingUsernames = ['user1', 'user2', 'user3']; 
    return existingUsernames.contains(username); 
  }

  // Método asíncrono que obtiene el ID del usuario actualmente autenticado.
  Future<String?> getCurrentUserId() async {
    final result = await accountService.getCurrentUserId();
    return result;
  }

  // Método asíncrono que obtiene el ID del usuario actualmente autenticado.
  Future<String> getCurrentUserIdNonNull() async {
    final result = await accountService.getCurrentUserIdNonNull();
    return result;
  }

  // Método que permite el cierre de sesión del usuario.
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

  // Método asíncrono que comprueba si el nombre de usuario existe en la base de datos.
  Future<bool> checkUsernameExists(String username) async {
    return await accountService.checkUsernameExists(username);
  }

  // Método asíncrono que comprueba si el correo electrónico de un usuario existe en la base de datos.
  Future<bool> checkEmailExists(String email) async {
    return await accountService.checkEmailExists(email);
  }

}
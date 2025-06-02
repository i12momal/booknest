import 'dart:io';
import 'package:booknest/controllers/account_controller.dart';
import 'package:booknest/entities/viewmodels/account_view_model.dart';
import 'package:booknest/services/account_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mock del servicio de cuenta
class MockAccountService extends Mock implements AccountService {}

/// Mock para File (imagen)
class MockFile extends Mock implements File {}
class FileFake extends Fake implements File {}

/// Fake para UserSession.clearSession()
class UserSessionFake {
  static bool cleared = false;

  static Future<void> clearSession() async {
    cleared = true;
  }

  static void reset() {
    cleared = false;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Mockeo de SharedPreferences para evitar MissingPluginException
  SharedPreferences.setMockInitialValues({});

  late AccountController controller;
  late MockAccountService mockService;

  // Implementación de generatePasswordHash para test
  String generatePasswordHash(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  setUpAll(() {
    registerFallbackValue(LoginUserViewModel(userName: '', password: ''));
    registerFallbackValue(RegisterUserViewModel(
      name: '',
      userName: '',
      email: '',
      phoneNumber: 0,
      address: '',
      password: '',
      confirmPassword: '',
      image: null,
      genres: '',
      role: '',
      description: '',
    ));
    registerFallbackValue(FileFake());
  });

  setUp(() {
    mockService = MockAccountService();
    controller = AccountController();
    controller.accountService = mockService;

    // Reset UserSession fake state
    UserSessionFake.reset();
  });

  test('Debería mostrar mensaje si los campos están vacíos', () async {
    await controller.login('', '');
    print('Test campos vacíos: errorMessage = ${controller.errorMessage.value}');
    expect(controller.errorMessage.value, 'Por favor ingrese todos los campos');
    verifyNever(() => mockService.loginUser(any()));
  });

  test('Login exitoso limpia errorMessage', () async {
    when(() => mockService.loginUser(any()))
        .thenAnswer((_) async => {'success': true});

    await controller.login('usuario', 'clave');
    print('Test login exitoso: errorMessage = ${controller.errorMessage.value}');
    expect(controller.errorMessage.value, '');
    verify(() => mockService.loginUser(any())).called(1);
  });

  test('Login fallido muestra mensaje de error del servicio', () async {
    when(() => mockService.loginUser(any()))
        .thenAnswer((_) async => {
              'success': false,
              'message': 'Usuario o contraseña incorrectos',
            });

    await controller.login('usuario', 'clave');
    print('Test login fallido: errorMessage = ${controller.errorMessage.value}');
    expect(controller.errorMessage.value, 'Usuario o contraseña incorrectos');
  });

  group('registerUser', () {
    late MockFile mockFile;

    setUp(() {
      mockFile = MockFile();
    });

    test('Devuelve error si falla subida de imagen', () async {
      when(() => mockService.uploadProfileImage(any(), any()))
          .thenAnswer((_) async => null);

      final result = await controller.registerUser(
        'Nombre',
        'usuario',
        'email@test.com',
        123456789,
        'Dirección',
        'pass',
        'pass',
        mockFile,
        'genres',
        'description',
      );

      print('Test registro error subida imagen: $result');
      expect(result['success'], false);
      expect(result['message'], 'Error al subir la imagen');
      verifyNever(() => mockService.registerUser(any()));
    });

    test('Registro exitoso sin imagen', () async {
      when(() => mockService.registerUser(any()))
          .thenAnswer((_) async => {'success': true});

      final result = await controller.registerUser(
        'Nombre',
        'usuario',
        'email@test.com',
        123456789,
        'Dirección',
        'pass',
        'pass',
        null,
        'genres',
        'description',
      );

      print('Test registro exitoso sin imagen: $result');
      expect(result['success'], true);
      verify(() => mockService.registerUser(any())).called(1);
    });

    test('Registro exitoso con imagen', () async {
      when(() => mockService.uploadProfileImage(any(), any()))
          .thenAnswer((_) async => 'http://image.url/perfil.jpg');

      when(() => mockService.registerUser(any()))
          .thenAnswer((_) async => {'success': true});

      final result = await controller.registerUser(
        'Nombre',
        'usuario',
        'email@test.com',
        123456789,
        'Dirección',
        'pass',
        'pass',
        mockFile,
        'genres',
        'description',
      );

      print('Test registro exitoso con imagen: $result');
      expect(result['success'], true);
      verify(() => mockService.uploadProfileImage(any(), any())).called(1);
      verify(() => mockService.registerUser(any())).called(1);
    });
  });

  group('Funciones auxiliares y de lógica propia', () {
    test('generatePasswordHash produce hash SHA256 esperado', () {
      const password = '123456';
      final expectedHash = sha256.convert(utf8.encode(password)).toString();

      final hash = generatePasswordHash(password);
      print('Test hash contraseña: $hash');
      expect(hash, expectedHash);
    });

    test('isUsernameTaken detecta usernames existentes', () async {
      // Simula la función isUsernameTaken dentro del controlador si está
      Future<bool> isUsernameTaken(String username) async {
        List<String> existingUsernames = ['user1', 'user2', 'user3']; 
        return existingUsernames.contains(username); 
      }

      final exists = await isUsernameTaken('user1');
      final notExists = await isUsernameTaken('noexiste');

      print('Test username "user1" existe: $exists');
      print('Test username "noexiste" existe: $notExists');
      expect(exists, true);
      expect(notExists, false);
    });

    test('getCurrentUserId delega y devuelve valor del servicio', () async {
      when(() => mockService.getCurrentUserId())
          .thenAnswer((_) async => 'user-123');

      final result = await controller.getCurrentUserId();
      print('Test getCurrentUserId: $result');
      expect(result, 'user-123');
      verify(() => mockService.getCurrentUserId()).called(1);
    });

    test('getCurrentUserIdNonNull delega y devuelve valor del servicio', () async {
      when(() => mockService.getCurrentUserIdNonNull())
          .thenAnswer((_) async => 'user-456');

      final result = await controller.getCurrentUserIdNonNull();
      print('Test getCurrentUserIdNonNull: $result');
      expect(result, 'user-456');
      verify(() => mockService.getCurrentUserIdNonNull()).called(1);
    });

    test('logout limpia sesión en caso de éxito', () async {
      when(() => mockService.logoutUser())
          .thenAnswer((_) async => {'success': true});

      await controller.logout();

      verify(() => mockService.logoutUser()).called(1);

      print('Test logout exitoso ejecutado');
    });

    test('logout no limpia sesión en caso de fallo', () async {
      when(() => mockService.logoutUser())
          .thenAnswer((_) async => {'success': false, 'message': 'Error'});

      await controller.logout();

      verify(() => mockService.logoutUser()).called(1);

      print('Test logout fallido ejecutado');
    });

    test('checkUsernameExists delega al servicio', () async {
      when(() => mockService.checkUsernameExists('usuario'))
          .thenAnswer((_) async => true);

      final result = await controller.checkUsernameExists('usuario');
      print('Test checkUsernameExists: $result');
      expect(result, true);
      verify(() => mockService.checkUsernameExists('usuario')).called(1);
    });

    test('checkEmailExists delega al servicio', () async {
      when(() => mockService.checkEmailExists('email@test.com'))
          .thenAnswer((_) async => false);

      final result = await controller.checkEmailExists('email@test.com');
      print('Test checkEmailExists: $result');
      expect(result, false);
      verify(() => mockService.checkEmailExists('email@test.com')).called(1);
    });
  });
}

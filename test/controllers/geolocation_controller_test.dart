import 'package:booknest/controllers/geolocation_controller.dart';
import 'package:booknest/entities/models/book_model.dart';
import 'package:booknest/entities/models/geolocation_model.dart';
import 'package:booknest/entities/models/user_model.dart' as user;
import 'package:booknest/services/geolocation_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mocktail/mocktail.dart';

class MockGeolocationService extends Mock implements GeolocationService {}

class GeolocationFake extends Fake implements Geolocation {}

class PositionFake extends Fake implements Position {}

class BookFake extends Fake implements Book {}

class UserFake extends Fake implements user.User {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GeolocationController controller;
  late MockGeolocationService mockService;

  setUpAll(() {
    registerFallbackValue(GeolocationFake());
    registerFallbackValue(PositionFake());
    registerFallbackValue(BookFake());
    registerFallbackValue(UserFake());
  });

  setUp(() {
    mockService = MockGeolocationService();
    controller = GeolocationController();
    controller.geolocationService = mockService;
  });

  group('GeolocationController', () {
    test('getNearbyUsers retorna usuarios cercanos', () async {
      final position = Position(
        latitude: 10.0,
        longitude: 20.0,
        timestamp: DateTime.now(),
        accuracy: 1.0,
        altitude: 0.0,
        heading: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        altitudeAccuracy: 0.0,
        headingAccuracy: 0.0,
      );

      final fakeUsers = <Geolocation>[];

      when(() => mockService.getNearbyUsers(position))
          .thenAnswer((_) async => fakeUsers);

      final result = await controller.getNearbyUsers(position);

      expect(result, isA<List<Geolocation>>());
      expect(result, isEmpty);
      verify(() => mockService.getNearbyUsers(position)).called(1);
      print('getNearbyUsers llamado con posición: $position');
    });

    test('isAvailable llama al servicio con bookId y retorna booleano', () async {
      const bookId = 123;

      when(() => mockService.isAvailable(bookId))
          .thenAnswer((_) async => true);

      final result = await controller.isAvailable(bookId);

      expect(result, true);
      verify(() => mockService.isAvailable(bookId)).called(1);
      print('isAvailable llamado con bookId=$bookId');
    });

    test('isUserGeolocationEnabled llama servicio y retorna valor', () async {
      const userId = 'user1';

      when(() => mockService.isUserGeolocationEnabled(userId))
          .thenAnswer((_) async => true);

      final result = await controller.isUserGeolocationEnabled(userId);

      expect(result, true);
      verify(() => mockService.isUserGeolocationEnabled(userId)).called(1);
      print('isUserGeolocationEnabled llamado con userId=$userId');
    });

    test('updateUserGeolocation llama servicio', () async {
      const userId = 'user1';
      const enabled = true;

      when(() => mockService.updateUserGeolocation(userId, enabled))
          .thenAnswer((_) async => Future.value());

      await controller.updateUserGeolocation(userId, enabled);

      verify(() => mockService.updateUserGeolocation(userId, enabled)).called(1);
      print('updateUserGeolocation llamado con userId=$userId, enabled=$enabled');
    });

    test('getUserGeolocation llama servicio y retorna ubicación', () async {
      const userId = 'user1';
      final fakeGeolocation = GeolocationFake();

      when(() => mockService.getUserGeolocation(userId))
          .thenAnswer((_) async => fakeGeolocation);

      final result = await controller.getUserGeolocation(userId);

      expect(result, isA<Geolocation>());
      verify(() => mockService.getUserGeolocation(userId)).called(1);
      print('getUserGeolocation llamado con userId=$userId');
    });
  });
}

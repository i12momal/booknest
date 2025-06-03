import 'package:booknest/controllers/reminder_controller.dart';
import 'package:booknest/entities/models/reminder_model.dart';
import 'package:booknest/entities/viewmodels/reminder_view_model.dart';
import 'package:booknest/services/reminder_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockReminderService extends Mock implements ReminderService {}

class CreateReminderViewModelFake extends Fake implements CreateReminderViewModel {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ReminderController controller;
  late MockReminderService mockService;

  setUpAll(() {
    registerFallbackValue(CreateReminderViewModelFake());
  });

  setUp(() {
    mockService = MockReminderService();
    controller = ReminderController();
    controller.reminderService = mockService;
  });

  group('ReminderController', () {
    test('getRemindersByBookAndUser devuelve lista de recordatorios', () async {
      const bookId = 1;
      const userId = 'user1';
      final mockReminders = <Reminder>[];

      when(() => mockService.getRemindersByBookAndUser(bookId, userId)).thenAnswer((_) async => mockReminders);

      final result = await controller.getRemindersByBookAndUser(bookId, userId);

      expect(result, isA<List<Reminder>>());
      expect(result, isEmpty);
      verify(() => mockService.getRemindersByBookAndUser(bookId, userId)).called(1);
      print('Recordatorios del libro $bookId para $userId: $result');
    });

    test('getRemindersByBook devuelve lista de recordatorios', () async {
      const bookId = 1;
      final mockReminders = <Reminder>[];

      when(() => mockService.getRemindersByBook(bookId)).thenAnswer((_) async => mockReminders);

      final result = await controller.getRemindersByBook(bookId);

      expect(result, isA<List<Reminder>>());
      verify(() => mockService.getRemindersByBook(bookId)).called(1);
      print('Recordatorios para libro $bookId: $result');
    });

    test('getUsersIdForReminder devuelve lista de IDs de usuarios', () async {
      const bookId = 1;
      final mockUserIds = ['user1', 'user2'];

      when(() => mockService.getUsersIdForReminder(bookId)).thenAnswer((_) async => mockUserIds);

      final result = await controller.getUsersIdForReminder(bookId);

      expect(result, equals(mockUserIds));
      verify(() => mockService.getUsersIdForReminder(bookId)).called(1);
      print('Usuarios con recordatorio para libro $bookId: $result');
    });

    test('addReminder retorna success true si no hay error', () async {
      const bookId = 1;
      const userId = 'user1';
      const format = 'Digital';

      when(() => mockService.addReminder(any())).thenAnswer((_) async => Future.value());

      final result = await controller.addReminder(bookId, userId, format);

      expect(result['success'], true);
      verify(() => mockService.addReminder(any())).called(1);
      print('Recordatorio agregado: $result');
    });

    test('addReminder retorna success false si hay error', () async {
      const bookId = 1;
      const userId = 'user1';
      const format = 'Digital';

      when(() => mockService.addReminder(any())).thenThrow(Exception('Error'));

      final result = await controller.addReminder(bookId, userId, format);

      expect(result['success'], false);
      expect(result['message'], contains('Error'));
      print('Fallo al agregar recordatorio: $result');
    });

    test('removeFromReminder elimina un recordatorio correctamente', () async {
      const bookId = 1;
      const userId = 'user1';
      const format = 'Digital';

      when(() => mockService.removeFromReminder(bookId, userId, format)).thenAnswer((_) async => Future.value());

      final result = await controller.removeFromReminder(bookId, userId, format);

      expect(result['success'], true);
      print('Recordatorio eliminado: $result');
    });

    test('removeFromReminder retorna error si falla la eliminación', () async {
      const bookId = 1;
      const userId = 'user1';
      const format = 'Digital';

      when(() => mockService.removeFromReminder(bookId, userId, format)).thenThrow(Exception('No se pudo eliminar'));

      final result = await controller.removeFromReminder(bookId, userId, format);

      expect(result['success'], false);
      print('Error al eliminar recordatorio: $result');
    });

    test('markAsNotified llama al servicio correctamente', () async {
      const bookId = 1;
      const userId = 'user1';
      const format = 'Digital';

      when(() => mockService.markAsNotified(bookId, userId, format)).thenAnswer((_) async => Future.value());

      await controller.markAsNotified(bookId, userId, format);

      verify(() => mockService.markAsNotified(bookId, userId, format)).called(1);
      print('Recordatorio marcado como notificado');
    });

    test('updateReminderStateForAllUsers actualiza correctamente el estado', () async {
      const bookId = 1;
      const notified = true;

      final reminderList = [
        Reminder(id: 1, bookId: bookId, userId: 'user1', format: 'Digital', notified: false),
        Reminder(id: 2, bookId: bookId, userId: 'user2', format: 'Digital', notified: true),
      ];

      when(() => mockService.getRemindersByBook(bookId)).thenAnswer((_) async => reminderList);

      when(() => mockService.updateReminderNotificationStatus(1, notified)).thenAnswer((_) async => Future.value());

      await controller.updateReminderStateForAllUsers(bookId, notified);

      verify(() => mockService.getRemindersByBook(bookId)).called(1);
      verify(() => mockService.updateReminderNotificationStatus(1, notified)).called(1);
      verifyNever(() => mockService.updateReminderNotificationStatus(2, notified));
      print('Estado de recordatorios actualizado');
    });
  });
  
}
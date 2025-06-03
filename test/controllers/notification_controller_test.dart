import 'package:booknest/controllers/notification_controller.dart';
import 'package:booknest/entities/viewmodels/notification_view_model.dart';
import 'package:booknest/services/notification_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockNotificationService extends Mock implements NotificationService {}

class CreateNotificationViewModelFake extends Fake implements CreateNotificationViewModel {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late NotificationController controller;
  late MockNotificationService mockService;

  setUpAll(() {
    registerFallbackValue(CreateNotificationViewModelFake());
  });

  setUp(() {
    mockService = MockNotificationService();
    controller = NotificationController();
    controller.notificationService = mockService;
  });

  group('NotificationController', () {
    test('markNotificationAsRead llama al servicio correctamente', () async {
      const notificationId = 1;

      when(() => mockService.markNotificationAsRead(notificationId)).thenAnswer((_) async => Future.value());

      await controller.markNotificationAsRead(notificationId);

      verify(() => mockService.markNotificationAsRead(notificationId)).called(1);
      print('Notificación marcada como leída: $notificationId');
    });

    test('createNotification llama al servicio con datos correctos', () async {
      const userId = 'user1';
      const type = 'loan_request';
      const relatedId = 123;
      const message = 'Tienes una nueva solicitud de préstamo';

      when(() => mockService.createNotification(any())).thenAnswer((_) async => {'success': true});

      final result = await controller.createNotification(userId, type, relatedId, message);

      expect(result['success'], true);

      final captured = verify(() => mockService.createNotification(captureAny())).captured.first
          as CreateNotificationViewModel;

      expect(captured.userId, userId);
      expect(captured.type, type);
      expect(captured.relatedId, relatedId);
      expect(captured.message, message);
      expect(captured.read, false);

      print('Notificación creada: $result');
    });

    test('getUserNotifications retorna una lista de notificaciones', () async {
      const userId = 'user1';
      final mockNotifications = <Map<String, dynamic>>[];

      when(() => mockService.getNotifications(userId)).thenAnswer((_) async => mockNotifications);

      final result = await controller.getUserNotifications(userId);

      expect(result, isA<List<Map<String, dynamic>>>());
      expect(result, isEmpty);

      verify(() => mockService.getNotifications(userId)).called(1);
      print('Notificaciones de usuario: $result');
    });

    test('getUnreadUserNotifications retorna una lista de no leídas', () async {
      const userId = 'user1';
      final mockUnread = <Map<String, dynamic>>[];

      when(() => mockService.getUnreadNotifications(userId)).thenAnswer((_) async => mockUnread);

      final result = await controller.getUnreadUserNotifications(userId);

      expect(result, isA<List<Map<String, dynamic>>>());
      expect(result, isEmpty);

      verify(() => mockService.getUnreadNotifications(userId)).called(1);
      print('Notificaciones no leídas: $result');
    });

    test('deleteNotification llama al servicio y retorna resultado', () async {
      const notificationId = 1;

      when(() => mockService.deleteNotification(notificationId)).thenAnswer((_) async => {'deleted': true});

      final result = await controller.deleteNotification(notificationId);

      expect(result['deleted'], true);

      verify(() => mockService.deleteNotification(notificationId)).called(1);
      print('Notificación eliminada: $notificationId');
    });

    test('getNotificationsByLoanId retorna lista de notificaciones', () async {
      const loanId = 101;
      final mockNotifications = <Map<String, dynamic>>[];

      when(() => mockService.getNotificationsByLoanId(loanId)).thenAnswer((_) async => mockNotifications);

      final result = await controller.getNotificationsByLoanId(loanId);

      expect(result, isA<List<Map<String, dynamic>>>());
      expect(result, isEmpty);

      verify(() => mockService.getNotificationsByLoanId(loanId)).called(1);
      print('Notificaciones para préstamo $loanId: $result');
    });
  });
  
}
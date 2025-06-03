import 'package:booknest/services/chat_message_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:booknest/controllers/chat_message_controller.dart';
import 'package:booknest/entities/viewmodels/chat_message_view_model.dart';
import 'package:booknest/entities/models/chat_message_model.dart';

/// Mock del servicio de chatMessage
class MockChatMessageService extends Mock implements ChatMessageService {}

/// Fake para CreateChatMessageViewModel
class CreateChatMessageViewModelFake extends Fake implements CreateChatMessageViewModel {}

/// Fake para ChatMessage
class ChatMessageFake extends Fake implements ChatMessage {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ChatMessageController controller;
  late MockChatMessageService mockService;

  setUpAll(() {
    registerFallbackValue(CreateChatMessageViewModelFake());
    registerFallbackValue(ChatMessageFake());
  });

  setUp(() {
    mockService = MockChatMessageService();
    controller = ChatMessageController();
    controller.chatMessageService = mockService;
  });

  group('ChatMessageController', () {
    test('createChatMessage llama al servicio y retorna resultado', () async {
      const userId = 'user1';
      const chatId = 123;
      const message = 'Hola desde test';

      print('Ejecutando createChatMessage con userId=$userId, chatId=$chatId, message=$message');

      when(() => mockService.createChatMessage(any())).thenAnswer((_) async => {'success': true});

      final result = await controller.createChatMessage(userId, chatId, message);

      print('Resultado de createChatMessage: $result');

      expect(result['success'], true);

      final captured = verify(() => mockService.createChatMessage(captureAny())).captured.first as CreateChatMessageViewModel;
      expect(captured.userId, userId);
      expect(captured.chatId, chatId);
      expect(captured.content, message);
      expect(captured.read, false);
    });

    test('getMessagesForChat retorna lista vacía', () async {
      const chatId = 1;
      const userId = 'user1';

      when(() => mockService.getMessagesForChat(chatId, userId)).thenAnswer((_) async => []);

      final messages = await controller.getMessagesForChat(chatId, userId);

      print('Mensajes recibidos: $messages');

      expect(messages, isA<List<ChatMessage>>());
      expect(messages, isEmpty);
    });

    test('markMessageAsRead llama servicio', () async {
      const chatId = 1;
      const userId = 'user1';

      when(() => mockService.markMessageAsRead(chatId, userId)).thenAnswer((_) async => Future.value());

      await controller.markMessageAsRead(chatId, userId);

      verify(() => mockService.markMessageAsRead(chatId, userId)).called(1);
      print('markMessageAsRead llamado con chatId=$chatId y userId=$userId');
    });

    test('deleteMessagesByUser llama servicio', () async {
      const chatId = 1;
      const userId = 'user1';

      when(() => mockService.deleteMessagesByUser(chatId, userId)).thenAnswer((_) async => <String, dynamic>{}); 

      await controller.deleteMessagesByUser(chatId, userId);

      verify(() => mockService.deleteMessagesByUser(chatId, userId)).called(1);
      print('deleteMessagesByUser llamado con chatId=$chatId y userId=$userId');
    });

    test('updateDeleteLoanChat llama servicio', () async {
      const chatId = 1;
      const userId = 'user1';

      when(() => mockService.updateDeleteLoanChat(any(), any())).thenAnswer((_) async => <String, dynamic>{});

      await controller.updateDeleteLoanChat(chatId, userId);

      verify(() => mockService.updateDeleteLoanChat(chatId, userId)).called(1);
      print('updateDeleteLoanChat llamado con chatId=$chatId y userId=$userId');
    });

  });
  
}
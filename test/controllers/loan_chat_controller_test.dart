import 'package:booknest/controllers/loan_chat_controller.dart';
import 'package:booknest/entities/models/loan_chat_model.dart';
import 'package:booknest/services/loan_chat_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockLoanChatService extends Mock implements LoanChatService {}

class LoanChatFake extends Fake implements LoanChat {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LoanChatController controller;
  late MockLoanChatService mockService;

  setUpAll(() {
    registerFallbackValue(LoanChatFake());
  });

  setUp(() {
    mockService = MockLoanChatService();
    controller = LoanChatController();
    controller.loanChatService = mockService;
  });

  group('LoanChatController', () {
    test('createChatIfNotExists llama al servicio y retorna el ID del chat', () async {
      const loanId = 10;
      const ownerId = 'user1';
      const requesterId = 'user2';
      const compensationLoanId = 5;
      const expectedChatId = 42;

      when(() => mockService.createChatIfNotExists(
              loanId, ownerId, requesterId, compensationLoanId))
          .thenAnswer((_) async => expectedChatId);

      final chatId = await controller.createChatIfNotExists(
          loanId, ownerId, requesterId, compensationLoanId);

      expect(chatId, expectedChatId);

      verify(() => mockService.createChatIfNotExists(
          loanId, ownerId, requesterId, compensationLoanId)).called(1);

      print('Chat creado con ID: $chatId');
    });

    test('getUserLoanChats retorna una lista de chats', () async {
      const userId = 'user1';
      const archived = false;

      final mockChats = <LoanChat>[];

      when(() => mockService.getUserLoanChats(userId, archived))
          .thenAnswer((_) async => mockChats);

      final result = await controller.getUserLoanChats(userId, archived);

      expect(result, isA<List<LoanChat>>());
      expect(result, isEmpty);

      verify(() => mockService.getUserLoanChats(userId, archived)).called(1);
      print('Chats recibidos para $userId (archivados=$archived): $result');
    });

    test('toggleArchiveStatus llama al servicio correctamente', () async {
      const chatId = 101;
      const userId = 'user1';
      const archive = true;

      when(() => mockService.toggleArchiveStatus(chatId, userId, archive))
          .thenAnswer((_) async => Future.value());

      await controller.toggleArchiveStatus(chatId, userId, archive);

      verify(() => mockService.toggleArchiveStatus(chatId, userId, archive)).called(1);
      print('Estado de archivado cambiado para chat $chatId por usuario $userId: archive=$archive');
    });
  });
}

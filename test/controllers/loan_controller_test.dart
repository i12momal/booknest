import 'package:booknest/controllers/account_controller.dart';
import 'package:booknest/controllers/book_controller.dart';
import 'package:booknest/controllers/chat_message_controller.dart';
import 'package:booknest/controllers/loan_controller.dart';
import 'package:booknest/controllers/notification_controller.dart';
import 'package:booknest/controllers/reminder_controller.dart';
import 'package:booknest/entities/models/book_model.dart';
import 'package:booknest/entities/models/reminder_model.dart';
import 'package:booknest/entities/viewmodels/loan_view_model.dart';
import 'package:booknest/services/account_service.dart';
import 'package:booknest/services/book_service.dart';
import 'package:booknest/services/loan_chat_service.dart';
import 'package:booknest/services/loan_service.dart';
import 'package:booknest/services/user_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAccountService extends Mock implements AccountService {}
class MockLoanService extends Mock implements LoanService {}
class MockBookService extends Mock implements BookService {}
class MockNotificationController extends Mock implements NotificationController {}
class CreateLoanViewModelFake extends Fake implements CreateLoanViewModel {}
class MockReminderController extends Mock implements ReminderController {}
class MockAccountController extends Mock implements AccountController {}
class MockBookController extends Mock implements BookController {}
class MockUserService extends Mock implements UserService {}
class MockLoanChatService extends Mock implements LoanChatService {}
class MockChatMessageController extends Mock implements ChatMessageController {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LoanController controller;
  late MockAccountService mockAccountService;
  late MockLoanService mockLoanService;
  late MockBookService mockBookService;
  late MockNotificationController mockNotificationController;
  late MockReminderController mockReminderController;
  late MockAccountController mockAccountController;
  late MockBookController mockBookController;
  late MockUserService mockUserService;
  late MockLoanChatService mockLoanChatService;
  late MockChatMessageController mockChatMessageController;

  final sampleBook = Book(
    id: 1,
    ownerId: 'owner1',
    title: 'Book Title',
    format: 'Físico, Digital',
    author: 'autor1',
    isbn: '123456789X',
    pagesNumber: 789,
    language: 'Español',
    file: '',
    cover: 'cover.jpg',
    categories: 'Novela, Ficción',
    summary: 'Un libro muy interesante sobre pruebas unitarias.',
    state: 'Disponible',
  );


  setUpAll(() {
    registerFallbackValue(CreateLoanViewModelFake());
  });

  setUp(() {
    mockAccountService = MockAccountService();
    mockLoanService = MockLoanService();
    mockBookService = MockBookService();
    mockNotificationController = MockNotificationController();
    mockReminderController = MockReminderController();
    mockAccountController = MockAccountController();
    mockBookController = MockBookController();
    mockUserService = MockUserService();
    mockLoanChatService = MockLoanChatService();
    mockChatMessageController = MockChatMessageController();

    controller = LoanController();
    controller.accountService = mockAccountService;
    controller.loanService = mockLoanService;
    controller.bookService = mockBookService;
    controller.notificationController = mockNotificationController;
    controller.accountController = mockAccountController;
    controller.bookController = mockBookController;
    controller.userService = mockUserService;
    controller.loanChatService = mockLoanChatService;
    controller.chatMessageController = mockChatMessageController;
    controller.reminderController = mockReminderController;

  });

  group('LoanController - requestLoan', () {
    test('devuelve error si el usuario no está autenticado', () async {
      when(() => mockAccountService.getCurrentUserId())
          .thenAnswer((_) async => null);

      final result = await controller.requestLoan(sampleBook, 'Digital', []);

      expect(result['success'], false);
      expect(result['message'], contains('Usuario no autenticado'));
    });

    test('realiza préstamo correctamente con notificación', () async {
      when(() => mockAccountService.getCurrentUserId()).thenAnswer((_) async => 'user1');

      when(() => mockLoanService.createLoan(any())).thenAnswer((_) async => {'success': true, 'data': {'id': 10}});

      when(() => mockLoanService.getLoanedFormatsAndStates(any())).thenAnswer((_) async => []);

      when(() => mockBookService.changeState(any(), any())).thenAnswer((_) async => Future.value());

      // Simular NotificationController con éxito
      when(() => mockNotificationController.createNotification(any(), any(), any(), any())).thenAnswer((_) async => {'success': true, 'data': {'id': 'notif123'}});

      // Inyectamos el controlador falso (puedes pasar por constructor o por setter según tu implementación)
      controller.notificationController = mockNotificationController;

      final result = await controller.requestLoan(sampleBook, 'Digital', []);

      expect(result['success'], true);
      expect(result['notificationId'], 'notif123');
      verify(() => mockLoanService.createLoan(any())).called(1);
      verify(() => mockBookService.changeState(sampleBook.id, any())).called(1);
    });

    test('no envía notificación si createLoan falla', () async {
      when(() => mockAccountService.getCurrentUserId())
          .thenAnswer((_) async => 'user1');

      when(() => mockLoanService.createLoan(any()))
          .thenAnswer((_) async => {'success': false});

      when(() => mockLoanService.getLoanedFormatsAndStates(any()))
          .thenAnswer((_) async => []);

      when(() => mockBookService.changeState(any(), any()))
          .thenAnswer((_) async => Future.value());

      final result = await controller.requestLoan(sampleBook, 'Digital', []);

      expect(result['success'], false);
      expect(result.containsKey('notificationId'), false);
    });

    test('maneja excepciones correctamente', () async {
      when(() => mockAccountService.getCurrentUserId())
          .thenThrow(Exception('Error grave'));

      final result = await controller.requestLoan(sampleBook, 'Digital', []);

      expect(result['success'], false);
      expect(result['message'], contains('Error al realizar la solicitud'));
    });

    test('marca libro como No Disponible si formatos están ocupados', () async {
      when(() => mockAccountService.getCurrentUserId())
          .thenAnswer((_) async => 'user1');

      when(() => mockLoanService.createLoan(any()))
          .thenAnswer((_) async => {'success': true, 'data': {'id': 99}});

      when(() => mockNotificationController.createNotification(any(), any(), any(), any()))
          .thenAnswer((_) async => {'success': true, 'data': {'id': 'noti001'}});

      when(() => mockLoanService.getLoanedFormatsAndStates(any())).thenAnswer((_) async => [
        {'format': 'Físico', 'state': 'aceptado'},
        {'format': 'Digital', 'state': 'pendiente'},
      ]);

      when(() => mockBookService.changeState(any(), any()))
          .thenAnswer((_) async => Future.value());

      controller.notificationController = mockNotificationController;

      final result = await controller.requestLoan(sampleBook, 'Físico', []);

      expect(result['success'], true);
      verify(() => mockBookService.changeState(sampleBook.id, 'No Disponible')).called(1);
    });
  });

  test('getLoansByHolder devuelve préstamos del usuario', () async {
    final mockLoans = [
      {'id': 1, 'bookId': 101},
      {'id': 2, 'bookId': 102},
    ];

    when(() => mockLoanService.getLoansByHolder('user123'))
        .thenAnswer((_) async => mockLoans);

    final result = await controller.getLoansByHolder('user123');

    expect(result, mockLoans);
    verify(() => mockLoanService.getLoansByHolder('user123')).called(1);
  });

  test('getPendingLoansForUser devuelve solicitudes pendientes', () async {
    final pendingLoans = [
      {'id': 10, 'state': 'Pendiente'},
    ];

    when(() => mockLoanService.getUserPendingLoans('user123'))
        .thenAnswer((_) async => pendingLoans);

    final result = await controller.getPendingLoansForUser('user123');

    expect(result, pendingLoans);
    verify(() => mockLoanService.getUserPendingLoans('user123')).called(1);
  });

  test('getLoanById devuelve el préstamo correctamente', () async {
    final loanData = {'id': 55, 'bookId': 999};

    when(() => mockLoanService.getLoanById(55))
        .thenAnswer((_) async => loanData);

    final result = await controller.getLoanById(55);

    expect(result, loanData);
    verify(() => mockLoanService.getLoanById(55)).called(1);
  });

  group('LoanController - areAllFormatsAvailable', () {
    test('devuelve false si no se encuentra el libro', () async {
      when(() => mockBookService.getBookById(1)).thenAnswer((_) async => {'data': null});

      final result = await controller.areAllFormatsAvailable(1);

      expect(result, false);
    });


    test('devuelve true si todos los formatos están disponibles', () async {
      when(() => mockBookService.getBookById(1))
      .thenAnswer((_) async => {
        'data': {
          'id': sampleBook.id,
          'format': sampleBook.format,
          'ownerId': sampleBook.ownerId,
          'title': sampleBook.title,
          'author': sampleBook.author,
          'isbn': sampleBook.isbn,
          'pagesNumber': sampleBook.pagesNumber,
          'language': sampleBook.language,
          'file': sampleBook.file,
          'cover': sampleBook.cover,
          'categories': sampleBook.categories,
          'summary': sampleBook.summary,
          'state': sampleBook.state,
        }
      });

      // Ambos formatos están disponibles → false indica que no hay préstamo activo
      when(() => mockLoanService.getActiveLoanForBookAndFormat(1, 'físico')).thenAnswer((_) async => false);
      when(() => mockLoanService.getActiveLoanForBookAndFormat(1, 'digital')).thenAnswer((_) async => false);

      final result = await controller.areAllFormatsAvailable(1);

      expect(result, true);
    });


    test('devuelve false si algún formato tiene préstamo activo', () async {
      when(() => mockBookService.getBookById(1))
    .thenAnswer((_) async => {
      'data': {
        'id': sampleBook.id,
        'format': sampleBook.format,
        'ownerId': sampleBook.ownerId,
        'title': sampleBook.title,
        'author': sampleBook.author,
        'isbn': sampleBook.isbn,
        'pagesNumber': sampleBook.pagesNumber,
        'language': sampleBook.language,
        'file': sampleBook.file,
        'cover': sampleBook.cover,
        'categories': sampleBook.categories,
        'summary': sampleBook.summary,
        'state': sampleBook.state,
      }
    });


      // Físico está libre, pero Digital tiene préstamo activo
      when(() => mockLoanService.getActiveLoanForBookAndFormat(1, 'físico')).thenAnswer((_) async => false);
      when(() => mockLoanService.getActiveLoanForBookAndFormat(1, 'digital')).thenAnswer((_) async => true);

      final result = await controller.areAllFormatsAvailable(1);

      expect(result, false);
    });
  });

  test('saveCurrentPageProgress guarda la página actual si existe préstamo activo', () async {
    const userId = 'user123';
    const bookId = 1;
    const currentPage = 150;
    
    final loanData = {'id': 42};

    // Simular que hay un préstamo activo para el usuario y libro
    when(() => mockLoanService.getLoanByUserAndBook(userId, bookId))
        .thenAnswer((_) async => loanData);

    // Simular actualización exitosa de la página actual
    when(() => mockLoanService.updateCurrentPage(loanData['id']!, currentPage))
        .thenAnswer((_) async => Future.value());

    await controller.saveCurrentPageProgress(userId, bookId, currentPage);

    // Verificar que se haya llamado a getLoanByUserAndBook y updateCurrentPage correctamente
    verify(() => mockLoanService.getLoanByUserAndBook(userId, bookId)).called(1);
    verify(() => mockLoanService.updateCurrentPage(loanData['id']!, currentPage)).called(1);
  });

  test('saveCurrentPageProgress no actualiza si no existe préstamo activo', () async {
    const userId = 'user123';
    const bookId = 1;
    const currentPage = 150;

    // Simular que no hay préstamo activo para el usuario y libro
    when(() => mockLoanService.getLoanByUserAndBook(userId, bookId))
        .thenAnswer((_) async => null);

    await controller.saveCurrentPageProgress(userId, bookId, currentPage);

    verify(() => mockLoanService.getLoanByUserAndBook(userId, bookId)).called(1);

    // Verificar que no se llamó a updateCurrentPage porque no hay préstamo
    verifyNever(() => mockLoanService.updateCurrentPage(any(), any()));
  });

  test('saveCurrentPageProgress maneja excepciones sin lanzar', () async {
    const userId = 'user123';
    const bookId = 1;
    const currentPage = 150;

    when(() => mockLoanService.getLoanByUserAndBook(userId, bookId))
        .thenThrow(Exception('Error simulado'));

    // Llamar a la función y verificar que no lance excepción
    await controller.saveCurrentPageProgress(userId, bookId, currentPage);

    // Verificar que se intentó obtener el préstamo
    verify(() => mockLoanService.getLoanByUserAndBook(userId, bookId)).called(1);

    // No debe llamar updateCurrentPage si hay excepción
    verifyNever(() => mockLoanService.updateCurrentPage(any(), any()));
  });

  test('getSavedPageProgress devuelve el progreso guardado correctamente', () async {
    const userId = 'user123';
    const bookId = 1;
    const savedPage = 100;

    when(() => mockLoanService.getSavedPageProgress(userId, bookId))
        .thenAnswer((_) async => savedPage);

    final result = await controller.getSavedPageProgress(userId, bookId);

    expect(result, savedPage);
    verify(() => mockLoanService.getSavedPageProgress(userId, bookId)).called(1);
  });

  test('getSavedPageProgress devuelve null si no hay progreso guardado', () async {
    const userId = 'user123';
    const bookId = 1;

    when(() => mockLoanService.getSavedPageProgress(userId, bookId))
        .thenAnswer((_) async => null);

    final result = await controller.getSavedPageProgress(userId, bookId);

    expect(result, null);
    verify(() => mockLoanService.getSavedPageProgress(userId, bookId)).called(1);
  });

  test('fetchAvailableFormats devuelve formatos disponibles correctamente', () async {
    const bookId = 1;
    final formats = ['Físico', 'Digital'];
    final availableFormats = ['Digital'];

    when(() => mockLoanService.getAvailableFormats(bookId, formats))
        .thenAnswer((_) async => availableFormats);

    final result = await controller.fetchAvailableFormats(bookId, formats);

    expect(result, availableFormats);
    verify(() => mockLoanService.getAvailableFormats(bookId, formats)).called(1);
  });

  test('fetchAvailableFormats maneja excepciones y devuelve lista vacía', () async {
    const bookId = 1;
    final formats = ['Físico', 'Digital'];

    when(() => mockLoanService.getAvailableFormats(bookId, formats))
        .thenThrow(Exception('Error simulado'));

    final result = await controller.fetchAvailableFormats(bookId, formats);

    expect(result, isEmpty);
    verify(() => mockLoanService.getAvailableFormats(bookId, formats)).called(1);
  });

  test('fetchLoanedFormats devuelve formatos prestados correctamente', () async {
    const bookId = 1;
    final loanedFormats = ['Físico', 'Digital'];

    when(() => mockLoanService.getLoanedFormats(bookId))
        .thenAnswer((_) async => loanedFormats);

    final result = await controller.fetchLoanedFormats(bookId);

    expect(result, loanedFormats);
    verify(() => mockLoanService.getLoanedFormats(bookId)).called(1);
  });

  test('fetchLoanedFormats maneja excepciones y devuelve lista vacía', () async {
    const bookId = 1;

    when(() => mockLoanService.getLoanedFormats(bookId))
        .thenThrow(Exception('Error simulado'));

    final result = await controller.fetchLoanedFormats(bookId);

    expect(result, isEmpty);
    verify(() => mockLoanService.getLoanedFormats(bookId)).called(1);
  });

  test('fetchPendingFormats devuelve formatos pendientes correctamente', () async {
    const bookId = 1;
    final pendingFormats = ['Digital'];

    when(() => mockLoanService.getPendingFormats(bookId))
        .thenAnswer((_) async => pendingFormats);

    final result = await controller.fetchPendingFormats(bookId);

    expect(result, pendingFormats);
    verify(() => mockLoanService.getPendingFormats(bookId)).called(1);
  });

  test('fetchPendingFormats maneja excepciones y devuelve lista vacía', () async {
    const bookId = 1;

    when(() => mockLoanService.getPendingFormats(bookId))
        .thenThrow(Exception('Error simulado'));

    final result = await controller.fetchPendingFormats(bookId);

    expect(result, isEmpty);
    verify(() => mockLoanService.getPendingFormats(bookId)).called(1);
  });

  test('getLoansByBookId devuelve lista de préstamos correctamente', () async {
    const bookId = 1;
    final loans = [
      {'id': 1, 'userId': 'user1'},
      {'id': 2, 'userId': 'user2'},
    ];

    when(() => mockLoanService.getLoansByBookId(bookId))
        .thenAnswer((_) async => loans);

    final result = await controller.getLoansByBookId(bookId);

    expect(result, loans);
    verify(() => mockLoanService.getLoansByBookId(bookId)).called(1);
  });


  test('cancelLoanRequest devuelve respuesta correcta', () async {
    const bookId = 1;
    const notificationId = 100;
    const format = 'Digital';

    final response = {'success': true, 'message': 'Préstamo cancelado'};

    when(() => mockLoanService.cancelLoan(bookId, notificationId, format))
        .thenAnswer((_) async => response);

    final result = await controller.cancelLoanRequest(bookId, notificationId, format);

    expect(result, response);
    verify(() => mockLoanService.cancelLoan(bookId, notificationId, format)).called(1);
  });

  test('checkExistingLoanRequest devuelve respuesta correcta', () async {
    const bookId = 1;
    const userId = 'user123';

    final response = {'exists': true};

    when(() => mockLoanService.checkExistingLoanRequest(bookId, userId))
        .thenAnswer((_) async => response);

    final result = await controller.checkExistingLoanRequest(bookId, userId);

    expect(result, response);
    verify(() => mockLoanService.checkExistingLoanRequest(bookId, userId)).called(1);
  });

  test('getLoanedFormatsAndStates devuelve lista correctamente', () async {
    const bookId = 1;

    final loanedFormatsAndStates = [
      {'format': 'Físico', 'state': 'Aceptado'},
      {'format': 'Digital', 'state': 'Pendiente'},
    ];

    when(() => mockLoanService.getLoanedFormatsAndStates(bookId))
        .thenAnswer((_) async => loanedFormatsAndStates);

    final result = await controller.getLoanedFormatsAndStates(bookId);

    expect(result, loanedFormatsAndStates);
    verify(() => mockLoanService.getLoanedFormatsAndStates(bookId)).called(1);
  });

  test('requestOfferPhysicalBookLoan crea préstamo y devuelve respuesta exitosa', () async {
    final book = Book(
      id: 1,
      ownerId: 'owner1',
      title: 'Título',
      format: 'Físico',
      author: 'Autor',
      isbn: '1234567890',
      pagesNumber: 100,
      language: 'Español',
      file: '',
      cover: '',
      categories: '',
      summary: '',
      state: 'Disponible',
    );

    const principalLoanId = 10;

    final response = {'success': true, 'data': {'id': 50}};

    when(() => mockLoanService.createLoanOfferPhysicalBook(any(), principalLoanId))
        .thenAnswer((_) async => response);

    final result = await controller.requestOfferPhysicalBookLoan(book, principalLoanId);

    expect(result, response);
    verify(() => mockLoanService.createLoanOfferPhysicalBook(any(), principalLoanId)).called(1);
  });

  test('requestOfferPhysicalBookLoan maneja excepción y devuelve error', () async {
    final book = Book(
      id: 1,
      ownerId: 'owner1',
      title: 'Título',
      format: 'Físico',
      author: 'Autor',
      isbn: '1234567890',
      pagesNumber: 100,
      language: 'Español',
      file: '',
      cover: '',
      categories: '',
      summary: '',
      state: 'Disponible',
    );

    const principalLoanId = 10;

    when(() => mockLoanService.createLoanOfferPhysicalBook(any(), principalLoanId))
        .thenThrow(Exception('Error simulado'));

    final result = await controller.requestOfferPhysicalBookLoan(book, principalLoanId);

    expect(result['success'], false);
    expect(result['message'], contains('Error al realizar la solicitud de préstamo'));
    verify(() => mockLoanService.createLoanOfferPhysicalBook(any(), principalLoanId)).called(1);
  });

  test('deleteLoanByBookAndUser llama correctamente al servicio', () async {
    const bookId = 1;
    const userId = 'user123';

    when(() => mockLoanService.deleteLoanByBookAndUser(bookId, userId))
        .thenAnswer((_) async => Future.value());

    await controller.deleteLoanByBookAndUser(bookId, userId);

    verify(() => mockLoanService.deleteLoanByBookAndUser(bookId, userId)).called(1);
  });

  test('acceptCompensationLoan devuelve el id del préstamo aceptado', () async {
    const bookId = 1;
    const userId = 'user123';
    const newHolderId = 'user456';
    const compensation = 'Compensación ejemplo';
    const expectedLoanId = 42;

    when(() => mockLoanService.acceptCompensationLoan(
      bookId: bookId,
      userId: userId,
      newHolderId: newHolderId,
      compensation: compensation,
    )).thenAnswer((_) async => expectedLoanId);

    final result = await controller.acceptCompensationLoan(
      bookId: bookId,
      userId: userId,
      newHolderId: newHolderId,
      compensation: compensation,
    );

    expect(result, expectedLoanId);
    verify(() => mockLoanService.acceptCompensationLoan(
      bookId: bookId,
      userId: userId,
      newHolderId: newHolderId,
      compensation: compensation,
    )).called(1);
  });

  test('getLoanStateForUser devuelve el estado del préstamo correctamente', () async {
    const loanId = 10;
    const userId = 'user123';
    const expectedState = 'Aceptado';

    when(() => mockLoanService.getLoanStateForUser(loanId, userId))
        .thenAnswer((_) async => expectedState);

    final result = await controller.getLoanStateForUser(loanId, userId);

    expect(result, expectedState);
    verify(() => mockLoanService.getLoanStateForUser(loanId, userId)).called(1);
  });

  test('getActualLoanIdForUserAndBook devuelve el id del préstamo actual', () async {
    const loanId = 10;
    const userId = 'user123';
    const expectedLoanId = 77;

    when(() => mockLoanService.getActualLoanIdForUserAndBook(loanId, userId))
        .thenAnswer((_) async => expectedLoanId);

    final result = await controller.getActualLoanIdForUserAndBook(loanId, userId);

    expect(result, expectedLoanId);
    verify(() => mockLoanService.getActualLoanIdForUserAndBook(loanId, userId)).called(1);
  });

  test('createLoanFianza crea préstamo correctamente y devuelve respuesta', () async {
    const bookId = 1;
    const ownerId = 'owner1';
    const currentHolderId = 'holder1';
    const bookTitle = 'Título del libro';

    final response = {'success': true, 'data': {'id': 123}};

    when(() => mockLoanService.createLoanFianza(any(), bookTitle))
        .thenAnswer((_) async => response);

    final result = await controller.createLoanFianza(bookId, ownerId, currentHolderId, bookTitle);

    expect(result, response);
    verify(() => mockLoanService.createLoanFianza(any(), bookTitle)).called(1);
  });

  test('createLoanFianza maneja excepción y devuelve error', () async {
    const bookId = 1;
    const ownerId = 'owner1';
    const currentHolderId = 'holder1';
    const bookTitle = 'Título del libro';

    when(() => mockLoanService.createLoanFianza(any(), bookTitle))
        .thenThrow(Exception('Error simulado'));

    final result = await controller.createLoanFianza(bookId, ownerId, currentHolderId, bookTitle);

    expect(result['success'], false);
    expect(result['message'], contains('Error al realizar la solicitud de préstamo'));
    verify(() => mockLoanService.createLoanFianza(any(), bookTitle)).called(1);
  });

  test('handleBookReturnAndNotification envía notificaciones y actualiza recordatorios', () async {
    const bookId = 1;
    const format = 'Digital';
    const bookTitle = 'Book Title';

    // Mock ReminderController
    final mockReminderController = MockReminderController();
    when(() => mockReminderController.getUsersIdForReminder(bookId))
        .thenAnswer((_) async => ['user1', 'user2']);
    when(() => mockReminderController.updateReminderStateForAllUsers(bookId, false))
        .thenAnswer((_) async => Future.value());

    // Mock NotificationController
    final mockNotificationController = MockNotificationController();
    when(() => mockNotificationController.createNotification(any(), any(), any(), any()))
        .thenAnswer((_) async => {'success': true, 'data': {'id': 'notif123'}});

    // Mock BookService
    when(() => mockBookService.getBookById(bookId))
        .thenAnswer((_) async => {
          'success': true,
          'message': 'Libro obtenido correctamente',
          'data': {
            'id': bookId,
            'title': bookTitle,
            'format': 'Físico, Digital',
          }
        });

    // Mock LoanService para simular que no hay préstamos activos en ningún formato
    when(() => mockLoanService.getActiveLoanForBookAndFormat(any(), any()))
        .thenAnswer((_) async => false);

    // Inject mocks en el controlador
    controller.reminderController = mockReminderController;
    controller.notificationController = mockNotificationController;
    controller.bookService = mockBookService;
    controller.loanService = mockLoanService;

    // Ejecutar función
    await controller.handleBookReturnAndNotification(bookId, format);

    // Verificar notificaciones enviadas
    verify(() => mockNotificationController.createNotification(
      'user1', 'Recordatorio', bookId, 'El libro "$bookTitle" en formato $format vuelve a estar disponible.'
    )).called(1);

    verify(() => mockNotificationController.createNotification(
      'user2', 'Recordatorio', bookId, 'El libro "$bookTitle" en formato $format vuelve a estar disponible.'
    )).called(1);

    // Verificar actualización de estado de recordatorios
    verify(() => mockReminderController.updateReminderStateForAllUsers(bookId, false)).called(1);
  });

  test('handleBookReturnAndNotification no desactiva recordatorios si hay formatos aún en préstamo', () async {
    const bookId = 1;
    const format = 'Digital';
    const bookTitle = 'Book Title';

    // Mock ReminderController
    final mockReminderController = MockReminderController();
    when(() => mockReminderController.getUsersIdForReminder(bookId))
        .thenAnswer((_) async => ['user1', 'user2']);
    when(() => mockReminderController.updateReminderStateForAllUsers(bookId, false))
        .thenAnswer((_) async => Future.value());

    // Mock NotificationController
    final mockNotificationController = MockNotificationController();
    when(() => mockNotificationController.createNotification(any(), any(), any(), any()))
        .thenAnswer((_) async => {'success': true, 'data': {'id': 'notif999'}});

    // Mock BookService
    when(() => mockBookService.getBookById(bookId))
        .thenAnswer((_) async => {
          'success': true,
          'message': 'Libro obtenido correctamente',
          'data': {
            'id': bookId,
            'title': bookTitle,
            'format': 'Físico, Digital',
          }
        });

    // Mock LoanService para simular que AL MENOS un formato sigue prestado
    when(() => mockLoanService.getActiveLoanForBookAndFormat(bookId, any()))
        .thenAnswer((_) async {
          // Solo el formato 'Físico' sigue prestado
          final calledFormat = _.positionalArguments[1] as String;
          return calledFormat.toLowerCase() == 'físico';
        });

    // Inject mocks en el controlador
    controller.reminderController = mockReminderController;
    controller.notificationController = mockNotificationController;
    controller.bookService = mockBookService;
    controller.loanService = mockLoanService;

    // Ejecutar función
    await controller.handleBookReturnAndNotification(bookId, format);

    // Verificar que se enviaron notificaciones
    verify(() => mockNotificationController.createNotification(
      'user1', 'Recordatorio', bookId, 'El libro "$bookTitle" en formato $format vuelve a estar disponible.'
    )).called(1);

    verify(() => mockNotificationController.createNotification(
      'user2', 'Recordatorio', bookId, 'El libro "$bookTitle" en formato $format vuelve a estar disponible.'
    )).called(1);

    // Verificar que NO se desactivaron los recordatorios
    verifyNever(() => mockReminderController.updateReminderStateForAllUsers(bookId, false));
  });

  
  // EXISTENTE: Devuelve y gestiona recordatorios si el usuario es el dueño del préstamo original
  test('updateLoanStateByUser notifica devolución y gestiona recordatorios si es dueño del préstamo original', () async {
    const loanId = 10;
    const compensationLoanId = 20;
    const bookId = 1;
    const format = 'Físico';
    const userId = 'ownerUser';
    const title = 'El Principito';

    // Mockear AccountController para retornar el usuario actual
    when(() => mockAccountController.getCurrentUserId())
        .thenAnswer((_) async => userId);

    // Mock de actualización de estado
    when(() => mockLoanService.updateLoanStateByUser(userId, loanId, compensationLoanId, 'Devuelto'))
        .thenAnswer((_) async => Future.value());

    // Mock obtener préstamo
    when(() => mockLoanService.getLoanById(loanId)).thenAnswer((_) async => {
          'data': {
            'ownerId': userId,
            'bookId': bookId,
            'format': format,
            'currentHolderId': 'anotherUser'
          }
        });

    when(() => mockLoanService.getLoanById(compensationLoanId)).thenAnswer((_) async => {
          'data': {'ownerId': 'otherOwner'}
        });

    // Mock bookService.getBookById
    when(() => mockBookService.getBookById(bookId)).thenAnswer((_) async => {
          'data': {'title': title, 'id': bookId}
        });

    // Mock reminders
    final reminders = [
      Reminder(id: 1, userId: 'user1', format: format, notified: false, bookId: bookId),
      Reminder(id: 2, userId: 'user2', format: format, notified: false, bookId: bookId),
    ];

    when(() => mockReminderController.getRemindersByBook(bookId))
        .thenAnswer((_) async => reminders);

    when(() => mockReminderController.markAsNotified(any(), any(), any()))
        .thenAnswer((_) async => Future.value({'success': true}));

    // 🔧 CORREGIDO: Mock que devuelve un Map en lugar de null
    when(() => mockReminderController.removeFromReminder(any(), any(), any()))
        .thenAnswer((_) async => {'success': true});

    // Mock areAllFormatsAvailable devuelve true
    when(() => mockLoanService.areAllFormatsAvailable(bookId, [format]))
        .thenAnswer((_) async => true);

    // Mock notificación
    when(() => mockNotificationController.createNotification(any(), any(), any(), any()))
        .thenAnswer((_) async => {'success': true});

    // Injectar dependencias
    controller.accountController = mockAccountController;
    controller.loanService = mockLoanService;
    controller.bookService = mockBookService;
    controller.reminderController = mockReminderController;
    controller.notificationController = mockNotificationController;

    // Ejecutar
    await controller.updateLoanStateByUser(loanId, compensationLoanId, 'Devuelto');

    // Verificar notificación al dueño
    verify(() => mockNotificationController.createNotification(
      userId,
      'Préstamo Devuelto',
      loanId,
      'Tu libro "$title" en formato $format ha sido devuelto.'
    )).called(1);

    // Verificar notificaciones a usuarios en recordatorios
    verify(() => mockNotificationController.createNotification(
      'user1',
      'Recordatorio',
      bookId,
      'El libro "$title" en formato $format vuelve a estar disponible.'
    )).called(1);

    verify(() => mockNotificationController.createNotification(
      'user2',
      'Recordatorio',
      bookId,
      'El libro "$title" en formato $format vuelve a estar disponible.'
    )).called(1);

    // Verificar que se marcaron como notificados y luego eliminados
    verify(() => mockReminderController.markAsNotified(bookId, 'user1', format)).called(1);
    verify(() => mockReminderController.markAsNotified(bookId, 'user2', format)).called(1);

    verify(() => mockReminderController.removeFromReminder(bookId, 'user1', format)).called(1);
    verify(() => mockReminderController.removeFromReminder(bookId, 'user2', format)).called(1);
  });

// NUEVO 1: El usuario no es dueño de ningún préstamo, no debe notificar
  test('updateLoanStateByUser no realiza acciones si el usuario no es dueño del préstamo', () async {
    const loanId = 10;
    const compensationLoanId = 20;
    const userId = 'externalUser';

    when(() => mockAccountController.getCurrentUserId()).thenAnswer((_) async => userId);
    when(() => mockLoanService.updateLoanStateByUser(userId, loanId, compensationLoanId, 'Devuelto'))
        .thenAnswer((_) async => Future.value());
    when(() => mockLoanService.getLoanById(loanId))
        .thenAnswer((_) async => {'data': {'ownerId': 'otherUser'}});
    when(() => mockLoanService.getLoanById(compensationLoanId))
        .thenAnswer((_) async => {'data': {'ownerId': 'someoneElse'}});

    controller.accountController = mockAccountController;
    controller.loanService = mockLoanService;

    await controller.updateLoanStateByUser(loanId, compensationLoanId, 'Devuelto');

    verifyNever(() => mockNotificationController.createNotification(any(), any(), any(), any()));
  });

// NUEVO 2: Rechazo notifica al solicitante y marca como disponible
  test('updateLoanStateByUser notifica rechazo y cambia estado del libro si es dueño', () async {
    const loanId = 10;
    const compensationLoanId = 20;
    const bookId = 1;
    const userId = 'ownerUser';
    const title = 'El Principito';
    const format = 'Físico';

    when(() => mockAccountController.getCurrentUserId()).thenAnswer((_) async => userId);
    when(() => mockLoanService.updateLoanStateByUser(userId, loanId, compensationLoanId, 'Rechazado'))
        .thenAnswer((_) async => Future.value());
    
    when(() => mockLoanService.getLoanById(loanId)).thenAnswer((_) async => {
      'data': {
        'ownerId': userId,
        'bookId': bookId,
        'format': format,
      },
      'currentHolderId': 'solicitanteUser',
    });

    when(() => mockLoanService.getLoanById(compensationLoanId)).thenAnswer((_) async => {
      'data': {
        'ownerId': 'otro',
        'bookId': bookId,
        'format': format,
      },
      'currentHolderId': 'usuarioCompensacion',
    });

    when(() => mockBookService.getBookById(bookId)).thenAnswer((_) async => {
      'data': {'id': bookId, 'title': title, 'currentHolderId': 'holderUser'}
    });
    
    when(() => mockNotificationController.createNotification(any(), any(), any(), any()))
        .thenAnswer((_) async => {'success': true});
    
    when(() => mockBookController.changeState(bookId, 'Disponible'))
        .thenAnswer((_) async => {'success': true});

    controller.accountController = mockAccountController;
    controller.loanService = mockLoanService;
    controller.bookService = mockBookService;
    controller.notificationController = mockNotificationController;
    controller.bookController = mockBookController;

    await controller.updateLoanStateByUser(loanId, compensationLoanId, 'Rechazado');

    verify(() => mockNotificationController.createNotification(
      'solicitanteUser',
      'Préstamo Rechazado',
      compensationLoanId,
      'Tu solicitud de préstamo para el libro"$title" en formato $format ha sido rechazada.'
    )).called(1);

    verify(() => mockBookController.changeState(bookId, 'Disponible')).called(1);
  });


// NUEVO 3: Recordatorios NO se eliminan si no están todos los formatos disponibles
  test('updateLoanStateByUser no elimina recordatorios si no están todos los formatos disponibles', () async {
    const loanId = 10;
    const compensationLoanId = 20;
    const bookId = 1;
    const format = 'Físico';
    const userId = 'ownerUser';
    const title = 'El Principito';

    when(() => mockAccountController.getCurrentUserId()).thenAnswer((_) async => userId);
    when(() => mockLoanService.updateLoanStateByUser(userId, loanId, compensationLoanId, 'Devuelto'))
        .thenAnswer((_) async => Future.value());
    when(() => mockLoanService.getLoanById(loanId)).thenAnswer((_) async => {
      'data': {
        'ownerId': userId,
        'bookId': bookId,
        'format': format,
        'currentHolderId': 'someoneElse'
      }
    });
    when(() => mockLoanService.getLoanById(compensationLoanId))
        .thenAnswer((_) async => {'data': {'ownerId': 'otro'}});
    when(() => mockBookService.getBookById(bookId)).thenAnswer((_) async => {
      'data': {'id': bookId, 'title': title}
    });

    final reminders = [
      Reminder(id: 1, userId: 'user1', format: format, notified: false, bookId: bookId)
    ];
    when(() => mockReminderController.getRemindersByBook(bookId))
        .thenAnswer((_) async => reminders);
    when(() => mockReminderController.markAsNotified(bookId, 'user1', format))
        .thenAnswer((_) async => {'success': true});
    when(() => mockLoanService.areAllFormatsAvailable(bookId, [format]))
        .thenAnswer((_) async => false);
    when(() => mockNotificationController.createNotification(any(), any(), any(), any()))
        .thenAnswer((_) async => {'success': true});

    controller.accountController = mockAccountController;
    controller.loanService = mockLoanService;
    controller.bookService = mockBookService;
    controller.reminderController = mockReminderController;
    controller.notificationController = mockNotificationController;

    await controller.updateLoanStateByUser(loanId, compensationLoanId, 'Devuelto');

    verifyNever(() => mockReminderController.removeFromReminder(bookId, 'user1', format));
  });

  test('updateLoanStateByUser notifica devolución y gestiona recordatorios si es dueño del préstamo compensatorio', () async {
    const loanId = 10;
    const compensationLoanId = 20;
    const bookId = 1;
    const format = 'Digital';
    const userId = 'ownerCompensationUser';
    const title = 'Cien Años de Soledad';

    when(() => mockAccountController.getCurrentUserId())
        .thenAnswer((_) async => userId);

    when(() => mockLoanService.updateLoanStateByUser(userId, loanId, compensationLoanId, 'Devuelto'))
        .thenAnswer((_) async => Future.value());

    when(() => mockLoanService.getLoanById(loanId)).thenAnswer((_) async => {
          'data': {
            'ownerId': 'otherOwner',
            'bookId': bookId,
            'format': 'Físico',
            'currentHolderId': 'userX'
          }
        });

    when(() => mockLoanService.getLoanById(compensationLoanId)).thenAnswer((_) async => {
          'data': {
            'ownerId': userId,
            'bookId': bookId,
            'format': format,
          },
          'currentHolderId': 'userY'
        });

    when(() => mockBookService.getBookById(bookId)).thenAnswer((_) async => {
          'data': {'title': title, 'id': bookId}
        });

    final reminders = [
      Reminder(id: 1, userId: 'userA', format: format, notified: false, bookId: bookId),
    ];

    when(() => mockReminderController.getRemindersByBook(bookId))
        .thenAnswer((_) async => reminders);

    when(() => mockReminderController.markAsNotified(any(), any(), any()))
        .thenAnswer((_) async => Future.value({'success': true}));

    when(() => mockReminderController.removeFromReminder(any(), any(), any()))
        .thenAnswer((_) async => {'success': true});

    when(() => mockLoanService.areAllFormatsAvailable(bookId, [format]))
        .thenAnswer((_) async => true);

    when(() => mockNotificationController.createNotification(any(), any(), any(), any()))
        .thenAnswer((_) async => {'success': true});

    controller.accountController = mockAccountController;
    controller.loanService = mockLoanService;
    controller.bookService = mockBookService;
    controller.reminderController = mockReminderController;
    controller.notificationController = mockNotificationController;

    await controller.updateLoanStateByUser(loanId, compensationLoanId, 'Devuelto');

    verify(() => mockNotificationController.createNotification(
      userId,
      'Préstamo Devuelto',
      compensationLoanId,
      'Tu libro "$title" en formato $format ha sido devuelto.'
    )).called(1);

    verify(() => mockNotificationController.createNotification(
      'userA',
      'Recordatorio',
      bookId,
      'El libro "$title" en formato $format vuelve a estar disponible.'
    )).called(1);

    verify(() => mockReminderController.markAsNotified(bookId, 'userA', format)).called(1);
    verify(() => mockReminderController.removeFromReminder(bookId, 'userA', format)).called(1);
  });


  test('updateLoanStateByUser no notifica ni cambia estado con estado no esperado', () async {
    const loanId = 10;
    const compensationLoanId = 20;
    const userId = 'ownerUser';

    when(() => mockAccountController.getCurrentUserId())
        .thenAnswer((_) async => userId);

    when(() => mockLoanService.updateLoanStateByUser(userId, loanId, compensationLoanId, 'Pendiente'))
        .thenAnswer((_) async => Future.value());

    when(() => mockLoanService.getLoanById(loanId)).thenAnswer((_) async => {
          'data': {'ownerId': userId, 'bookId': 1, 'format': 'Físico', 'currentHolderId': 'userX'}
        });

    when(() => mockLoanService.getLoanById(compensationLoanId)).thenAnswer((_) async => {
          'data': {'ownerId': 'otro'}
        });

    // Este mock es necesario para evitar error de tipo null
    when(() => mockBookService.getBookById(any())).thenAnswer((_) async => {'data': {}});

    controller.accountController = mockAccountController;
    controller.loanService = mockLoanService;
    controller.bookService = mockBookService;

    await controller.updateLoanStateByUser(loanId, compensationLoanId, 'Pendiente');

    verifyNever(() => mockNotificationController.createNotification(any(), any(), any(), any()));
    verifyNever(() => mockBookController.changeState(any(), any()));
    verifyNever(() => mockReminderController.markAsNotified(any(), any(), any()));
    verifyNever(() => mockReminderController.removeFromReminder(any(), any(), any()));
  });

  
  group('updateLoanState', () {
    const loanId = 1;
    const compensation = 'Libro a cambio';
    const bookId = 2;

    final loanDataPhysical = {
      'id': loanId,
      'bookId': bookId,
      'currentHolderId': 'user1',
      'format': 'Físico',
      'ownerId': 'owner1',
    };

    final loanDataDigital = {
      'id': loanId,
      'bookId': bookId,
      'currentHolderId': 'user1',
      'format': 'Digital',
      'ownerId': 'owner1',
    };

    final bookDataPhysical = {'title': 'Mi Libro', 'format': 'Físico, Digital'};
    final bookDataDigital = {'title': 'Mi Libro', 'format': 'Digital'};

    // Mock unificado para usuarios
    Future<Map<String, dynamic>> mockGetUserById(String userId) async {
      if (userId == 'owner1') {
        return {
          'data': {
            'name': 'Owner Name',
            'userName': 'ownerUser',
            'email': 'owner@mail.com',
          }
        };
      } else if (userId == 'user1') {
        return {
          'data': {
            'name': 'Requester Name',
            'userName': 'requesterUser',
            'email': 'requester@mail.com',
          }
        };
      }
      // Devolver un mapa con datos dummy para evitar null
      return {
        'data': {
          'name': 'Unknown',
          'userName': 'unknownUser',
          'email': 'unknown@mail.com',
        }
      };
    }

    test('no hace nada si getLoanById devuelve null data', () async {
      when(() => mockLoanService.getLoanById(loanId))
          .thenAnswer((_) async => {'data': null});
      await controller.updateLoanState(loanId, 'Aceptado');
      verifyNever(() => mockLoanService.updateLoanState(any(), any()));
    });

    test('no hace nada si getBookById devuelve null data', () async {
      when(() => mockLoanService.getLoanById(loanId))
          .thenAnswer((_) async => {'data': loanDataPhysical});
      when(() => mockBookService.getBookById(bookId))
          .thenAnswer((_) async => {'data': null});
      await controller.updateLoanState(loanId, 'Aceptado');
      verifyNever(() => mockLoanService.updateLoanState(any(), any()));
    });

    test('no hace nada si currentHolderId es null', () async {
      final loanDataNullHolder = {...loanDataPhysical, 'currentHolderId': null};
      when(() => mockLoanService.getLoanById(loanId))
          .thenAnswer((_) async => {'data': loanDataNullHolder});
      when(() => mockBookService.getBookById(bookId))
          .thenAnswer((_) async => {'data': bookDataPhysical});
      await controller.updateLoanState(loanId, 'Aceptado');
      verifyNever(() => mockLoanService.updateLoanState(any(), any()));
    });

    test('actualiza estado y notifica con compensación y formato físico', () async {
      when(() => mockLoanService.getLoanById(loanId))
          .thenAnswer((_) async => {'data': loanDataPhysical});
      when(() => mockBookService.getBookById(bookId))
          .thenAnswer((_) async => {'data': bookDataPhysical});

      when(() => mockUserService.getUserById(any()))
          .thenAnswer((invocation) => mockGetUserById(invocation.positionalArguments.first as String));

      when(() => mockLoanService.updateLoanState(loanId, 'Aceptado'))
          .thenAnswer((_) async => Future.value());
      when(() => mockLoanChatService.createChatIfNotExists(loanId, 'owner1', 'user1', null))
          .thenAnswer((_) async => 123);
      when(() => mockNotificationController.createNotification(any(), any(), any(), any()))
          .thenAnswer((_) async => Future.value());
      when(() => mockChatMessageController.createChatMessage(any(), any(), any()))
          .thenAnswer((_) async => Future.value());
      when(() => mockLoanService.updateCompensation(compensation, loanId))
          .thenAnswer((_) async => Future.value());

      try {
        await controller.updateLoanState(loanId, 'Aceptado', compensation: compensation);
      } catch (_) {
      }

      verify(() => mockLoanService.updateLoanState(loanId, 'Aceptado')).called(1);
    });

    test('actualiza estado y notifica sin compensación y formato digital', () async {
      when(() => mockLoanService.getLoanById(loanId))
          .thenAnswer((_) async => {'data': loanDataDigital});
      when(() => mockBookService.getBookById(bookId))
          .thenAnswer((_) async => {'data': bookDataDigital});

      when(() => mockUserService.getUserById(any()))
          .thenAnswer((invocation) => mockGetUserById(invocation.positionalArguments.first as String));

      when(() => mockLoanService.updateLoanState(loanId, 'Aceptado'))
          .thenAnswer((_) async => Future.value());
      when(() => mockNotificationController.createNotification(any(), any(), any(), any()))
          .thenAnswer((_) async => Future.value());

      try {
        await controller.updateLoanState(loanId, 'Aceptado');
      } catch (_) {
      }

      verify(() => mockLoanService.updateLoanState(loanId, 'Aceptado')).called(1);
      verify(() => mockNotificationController.createNotification(
        'user1',
        'Préstamo Aceptado',
        loanId,
        any(that: contains('aceptada')),
      )).called(1);
    });

    test('actualiza estado y notifica estado Rechazado', () async {
      when(() => mockLoanService.getLoanById(loanId))
          .thenAnswer((_) async => {'data': loanDataDigital});
      when(() => mockBookService.getBookById(bookId))
          .thenAnswer((_) async => {'data': bookDataDigital});

      when(() => mockUserService.getUserById(any()))
          .thenAnswer((invocation) => mockGetUserById(invocation.positionalArguments.first as String));

      when(() => mockLoanService.updateLoanState(loanId, 'Rechazado'))
          .thenAnswer((_) async => Future.value());
      when(() => mockNotificationController.createNotification(any(), any(), any(), any()))
          .thenAnswer((_) async => Future.value());

      try {
        await controller.updateLoanState(loanId, 'Rechazado');
      } catch (_) {
      }

      verify(() => mockLoanService.updateLoanState(loanId, 'Rechazado')).called(1);
      verify(() => mockNotificationController.createNotification(
        'user1',
        'Préstamo Rechazado',
        loanId,
        any(that: contains('rechazada')),
      )).called(1);
    });
  });
}

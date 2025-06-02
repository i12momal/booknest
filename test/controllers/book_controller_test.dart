import 'dart:io';
import 'package:booknest/entities/models/book_model.dart';
import 'package:booknest/entities/viewmodels/book_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:booknest/controllers/book_controller.dart';
import 'package:booknest/services/book_service.dart';
import 'package:booknest/services/account_service.dart';

// Mocks para los servicios
class MockBookService extends Mock implements BookService {}
class MockAccountService extends Mock implements AccountService {}
class MockFile extends Mock implements File {}
// Define un Fake para File
class FakeFile extends Fake implements File {}

void main() {
  late BookController controller;
  late MockBookService mockBookService;
  late MockAccountService mockAccountService;

  setUpAll(() {
    registerFallbackValue(FakeFile());
  });

  setUp(() {
    mockBookService = MockBookService();
    mockAccountService = MockAccountService();

    controller = BookController();
    controller.bookService = mockBookService;
    controller.accountService = mockAccountService;

    // Registro de fallback values para mocks con argumentos complejos
    registerFallbackValue(CreateBookViewModel(
      title: '',
      author: '',
      isbn: '',
      pagesNumber: 0,
      language: '',
      format: '',
      file: '',
      cover: '',
      summary: '',
      categories: '',
      state: '',
      ownerId: '',
    ));

    registerFallbackValue(EditBookViewModel(
      id: 0,
      title: '',
      author: '',
      isbn: '',
      pagesNumber: 0,
      language: '',
      format: '',
      categories: '',
      file: '',
      cover: '',
      summary: '',
      state: '',
      ownerId: '',
    ));
  });

  group('addBook', () {
    const dummyUserId = 'user123';
    const dummyFileUrl = 'http://files.com/file.pdf';
    const dummyCoverUrl = 'http://files.com/cover.jpg';

    test('Retorna error si usuario no autenticado', () async {
      when(() => mockAccountService.getCurrentUserId()).thenAnswer((_) async => null);

      final result = await controller.addBook(
        'title', 'author', 'isbn', 100, 'es', 'digital', null, 'summary', 'categories', null);

      expect(result['success'], false);
      expect(result['message'], 'Usuario no autenticado');
      verifyNever(() => mockBookService.uploadFile(any(), any(), any()));
      verifyNever(() => mockBookService.addBook(any()));
    });

    test('Sube archivo y portada y llama a addBook con URLs', () async {
      when(() => mockAccountService.getCurrentUserId()).thenAnswer((_) async => dummyUserId);

      final mockFile = MockFile();
      final mockCover = MockFile();

      when(() => mockBookService.uploadFile(mockFile, any(), dummyUserId))
          .thenAnswer((_) async => dummyFileUrl);
      when(() => mockBookService.uploadCover(mockCover, any(), dummyUserId))
          .thenAnswer((_) async => dummyCoverUrl);

      when(() => mockBookService.addBook(any()))
          .thenAnswer((_) async => {'success': true});

      final result = await controller.addBook(
        'title', 'author', 'isbn', 100, 'es', 'digital', mockFile, 'summary', 'categories', mockCover);

      expect(result['success'], true);

      // Verifica que las URLs se enviaron en el ViewModel
      final captured = verify(() => mockBookService.addBook(captureAny())).captured.first as CreateBookViewModel;
      expect(captured.file, dummyFileUrl);
      expect(captured.cover, dummyCoverUrl);
    });

    test('Error al subir archivo retorna mensaje', () async {
      when(() => mockAccountService.getCurrentUserId()).thenAnswer((_) async => dummyUserId);
      final mockFile = MockFile();

      when(() => mockBookService.uploadFile(mockFile, any(), dummyUserId))
          .thenAnswer((_) async => null);

      final result = await controller.addBook(
        'title', 'author', 'isbn', 100, 'es', 'digital', mockFile, 'summary', 'categories', null);

      expect(result['success'], false);
      expect(result['message'], 'Error al subir el archivo');
    });

    test('Error al subir portada retorna mensaje', () async {
      when(() => mockAccountService.getCurrentUserId()).thenAnswer((_) async => dummyUserId);
      final mockFile = MockFile();
      final mockCover = MockFile();

      when(() => mockBookService.uploadFile(mockFile, any(), dummyUserId))
          .thenAnswer((_) async => dummyFileUrl);
      when(() => mockBookService.uploadCover(mockCover, any(), dummyUserId))
          .thenAnswer((_) async => null);

      final result = await controller.addBook(
        'title', 'author', 'isbn', 100, 'es', 'digital', mockFile, 'summary', 'categories', mockCover);

      expect(result['success'], false);
      expect(result['message'], 'Error al subir la portada');
    });
  });

  group('editBook', () {
    const dummyOwnerId = 'owner123';
    const dummyTitle = 'title';
    const dummyCurrentBookResponse = {
      'success': true,
      'data': {
        'file': 'http://files.com/oldfile.pdf',
        'cover': 'http://files.com/oldcover.jpg',
      }
    };

    test('Reemplaza archivo y portada y actualiza libro exitosamente', () async {
      final mockFile = MockFile();
      final mockCover = MockFile();

      // Definir path para evitar error Null is not a subtype of String
      when(() => mockFile.path).thenReturn('/mock/path/to/newfile.pdf');
      when(() => mockCover.path).thenReturn('/mock/path/to/newcover.jpg');

      when(() => mockBookService.getBookById(1)).thenAnswer((_) async => dummyCurrentBookResponse);

      when(() => mockBookService.deleteFile(any())).thenAnswer((_) async => true);

      when(() => mockBookService.uploadFile(mockFile, dummyTitle, dummyOwnerId)).thenAnswer((_) async => 'http://files.com/newfile.pdf');

      when(() => mockBookService.uploadCover(mockCover, dummyTitle, dummyOwnerId)).thenAnswer((_) async => 'http://files.com/newcover.jpg');

      when(() => mockBookService.editBook(any())).thenAnswer((_) async => {'success': true});

      final result = await controller.editBook(
        1,
        dummyTitle,
        'author',
        'isbn',
        100,
        'digital',
        'digital',
        mockFile,
        'summary',
        'genres',
        'Disponible',
        dummyOwnerId,
        mockCover,
      );

      expect(result['success'], true);

      final captured = verify(() => mockBookService.editBook(captureAny())).captured.first as EditBookViewModel;
      expect(captured.file, 'http://files.com/newfile.pdf');
      expect(captured.cover, 'http://files.com/newcover.jpg');
    });

    test('Elimina archivo si formato es físico', () async {
      when(() => mockBookService.getBookById(1))
          .thenAnswer((_) async => dummyCurrentBookResponse);

      when(() => mockBookService.deleteFile(any())).thenAnswer((_) async => true);

      when(() => mockBookService.editBook(any()))
          .thenAnswer((_) async => {'success': true});

      final result = await controller.editBook(
        1, dummyTitle, 'author', 'isbn', 100, 'físico', 'físico', null, 'summary',
        'genres', 'Disponible', dummyOwnerId, null);

      expect(result['success'], true);

      // Verifica que deleteFile fue llamado para archivo anterior
      verify(() => mockBookService.deleteFile('http://files.com/oldfile.pdf')).called(1);
    });
  });

  group('getBookById', () {
    test('Retorna Book cuando respuesta es exitosa', () async {
      final dummyBookData = {
        'id': 1,
        'title': 'titulo',
        'author': 'autor',
        'isbn': 'isbn',
        'pagesNumber': 100,
        'language': 'es',
        'format': 'digital',
        'file': 'fileurl',
        'cover': 'coverurl',
        'summary': 'resumen',
        'categories': 'cat',
        'state': 'Disponible',
        'ownerId': 'owner123',
      };

      when(() => mockBookService.getBookById(1))
          .thenAnswer((_) async => {'success': true, 'data': dummyBookData});

      final book = await controller.getBookById(1);

      expect(book, isNotNull);
      expect(book!.title, 'titulo');
      expect(book.ownerId, 'owner123');
    });

    test('Retorna null si respuesta es error', () async {
      when(() => mockBookService.getBookById(1))
          .thenAnswer((_) async => {'success': false, 'message': 'Error'});

      final book = await controller.getBookById(1);

      expect(book, isNull);
    });
  });

  // Tests para métodos que delegan al servicio
  test('deleteBook delega al servicio', () async {
    when(() => mockBookService.deleteBook(1))
        .thenAnswer((_) async => {'success': true});

    final result = await controller.deleteBook(1);
    expect(result['success'], true);
    verify(() => mockBookService.deleteBook(1)).called(1);
  });

  test('fetchAllBooks delega al servicio', () async {
    final dummyList = <Map<String, dynamic>>[
      {'id': 1, 'title': 'Book 1'},
      {'id': 2, 'title': 'Book 2'},
    ];

    when(() => mockBookService.fetchAllBooks())
        .thenAnswer((_) async => dummyList);

    final result = await controller.fetchAllBooks();
    expect(result, dummyList);
    verify(() => mockBookService.fetchAllBooks()).called(1);
  });

  test('getUserBooks delega al servicio', () async {
    final dummyBooks = <Book>[];

    when(() => mockBookService.getBooksForUser('userId'))
        .thenAnswer((_) async => dummyBooks);

    final result = await controller.getUserBooks('userId');
    expect(result, dummyBooks);
    verify(() => mockBookService.getBooksForUser('userId')).called(1);
  });

  test('getUserPhysicalBooks delega al servicio', () async {
    final dummyBooks = <Book>[];

    when(() => mockBookService.getUserPhysicalBooks('userId'))
        .thenAnswer((_) async => dummyBooks);

    final result = await controller.getUserPhysicalBooks('userId');
    expect(result, dummyBooks);
    verify(() => mockBookService.getUserPhysicalBooks('userId')).called(1);
  });

  test('getUserAvailablePhysicalBooks delega al servicio', () async {
    final dummyBooks = <Book>[];

    when(() => mockBookService.getUserAvailablePhysicalBooks('userId'))
        .thenAnswer((_) async => dummyBooks);

    final result = await controller.getUserAvailablePhysicalBooks('userId');
    expect(result, dummyBooks);
    verify(() => mockBookService.getUserAvailablePhysicalBooks('userId')).called(1);
  });

  test('changeState delega al servicio', () async {
    when(() => mockBookService.changeState(1, 'Disponible'))
        .thenAnswer((_) async => null);

    await controller.changeState(1, 'Disponible');
    verify(() => mockBookService.changeState(1, 'Disponible')).called(1);
  });

  test('getBookIdByTitleAndOwner delega al servicio', () async {
    when(() => mockBookService.getBookIdByTitleAndOwner('title', 'ownerId'))
        .thenAnswer((_) async => 5);

    final result = await controller.getBookIdByTitleAndOwner('title', 'ownerId');
    expect(result, 5);
  });

  test('checkTitleExists delega al servicio', () async {
    when(() => mockBookService.checkTitleExists('title', 'ownerId'))
        .thenAnswer((_) async => true);

    final result = await controller.checkTitleExists('title', 'ownerId');
    expect(result, true);
  });
}

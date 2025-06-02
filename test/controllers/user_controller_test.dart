import 'package:booknest/controllers/user_controller.dart';
import 'package:booknest/entities/models/book_model.dart';
import 'package:booknest/entities/viewmodels/user_view_model.dart';
import 'package:booknest/services/book_service.dart';
import 'package:booknest/services/category_service.dart';
import 'package:booknest/services/user_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// Mocks y fakes para los servicios y modelos usados
class MockUserService extends Mock implements UserService {}

class MockBookService extends Mock implements BookService {}

class MockCategoryService extends Mock implements CategoryService {}

class EditUserViewModelFake extends Fake implements EditUserViewModel {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late UserController controller;
  late MockUserService mockUserService;
  late MockBookService mockBookService;
  late MockCategoryService mockCategoryService;

  setUpAll(() {
    registerFallbackValue(EditUserViewModelFake());
  });

  setUp(() {
    mockUserService = MockUserService();
    mockBookService = MockBookService();
    mockCategoryService = MockCategoryService();

    controller = UserController();
    controller.userService = mockUserService;
    controller.bookService = mockBookService;
    controller.categoryService = mockCategoryService;
  });

  group('UserController tests', () {
    test('editUser con éxito y sin nueva contraseña ni imagen', () async {
      const userId = '123';
      const name = 'John Doe';
      const userName = 'johndoe';
      const email = 'john@example.com';
      const phoneNumber = 1234567890;
      const address = 'Calle 123';
      const password = '';
      const confirmPassword = '';
      const genres = 'Fiction, Mystery';
      const description = 'Some description';

      final currentUserResponse = {
        'success': true,
        'data': {'image': 'http://oldimage.jpg'}
      };

      final editResponse = {
        'success': true,
        'message': 'Usuario editado',
        'data': {
          'id': userId,
          'name': name,
          'userName': userName,
          'email': email,
          'phoneNumber': phoneNumber,
          'address': address,
          'image': 'http://oldimage.jpg',
          'genres': genres,
          'description': description,
        }
      };

      when(() => mockUserService.getUserById(userId))
          .thenAnswer((_) async => currentUserResponse);

      when(() => mockUserService.editUser(any()))
          .thenAnswer((_) async => editResponse);

      final result = await controller.editUser(
          userId,
          name,
          userName,
          email,
          phoneNumber,
          address,
          password,
          confirmPassword,
          null, // imagen nula
          genres,
          description);

      expect(result['success'], true);
      expect(result['data']['image'], 'http://oldimage.jpg');

      verify(() => mockUserService.getUserById(userId)).called(1);
      verify(() => mockUserService.editUser(any())).called(1);
    });

    test('editUser falla si las contraseñas no coinciden', () async {
      const userId = '123';
      const password = 'pass123';
      const confirmPassword = 'pass456';

      // Stub para evitar error de Null
      when(() => mockUserService.getUserById(userId))
          .thenAnswer((_) async => {'success': true, 'data': {'image': 'http://oldimage.jpg'}});

      final result = await controller.editUser(
          userId,
          'Name',
          'username',
          'email@example.com',
          123456789,
          'address',
          password,
          confirmPassword,
          null,
          'genres',
          'desc');

      expect(result['success'], false);
      expect(result['message'], 'Las contraseñas no coinciden');
      verifyNever(() => mockUserService.editUser(any()));
    });


    test('getUserById devuelve usuario cuando éxito', () async {
      const userId = '123';
      final userData = {
        'id': userId,
        'name': 'John',
        'userName': 'jdoe',
        'email': 'john@example.com',
        'phoneNumber': 654789032,
        'address': 'Cordoba',
        'password': 'Admin@1234',
        'confirmPassword': 'Admin@1234',
        'image': 'assets/images/default.png',
        'genres': ['Fiction', 'Mystery'], // Lista de strings
        'role': 'usuario',
        'favorites': [],                  // Lista vacía
        'description': 'Usuario de prueba',
      };


      when(() => mockUserService.getUserById(userId))
          .thenAnswer((_) async => {'success': true, 'data': userData});

      final user = await controller.getUserById(userId);

      expect(user, isNotNull);
      expect(user!.id, userId);
      expect(user.name, 'John');
      verify(() => mockUserService.getUserById(userId)).called(1);
    });

    test('getUserById devuelve null cuando falla', () async {
      const userId = '123';

      when(() => mockUserService.getUserById(userId))
          .thenAnswer((_) async => {'success': false});

      final user = await controller.getUserById(userId);

      expect(user, isNull);
      verify(() => mockUserService.getUserById(userId)).called(1);
    });

    test('getCategoriesFromBooks devuelve categorías filtradas', () async {
      const userId = '123';

      final categoryResponse = {
        'success': true,
        'data': [
          {'id': 1, 'name': 'Fiction', 'image': 'img1'},
          {'id': 2, 'name': 'Mystery', 'image': 'img2'},
          {'id': 3, 'name': 'Science Fiction', 'image': 'img3'},
          {'id': 4, 'name': 'Romance', 'image': 'img4'},
        ]
      };

      when(() => mockBookService.getBooksForUser(userId)).thenAnswer((_) async {
        final booksList = [
          Book(
            id: 1,
            title: 'Libro Misterioso',
            author: 'Autor Famoso',
            isbn: '9781234567890',
            pagesNumber: 250,
            language: 'es',
            format: 'digital',
            file: 'path/to/file',
            cover: 'path/to/cover',
            summary: 'Un resumen interesante',
            categories: 'Fiction, Mystery',
            state: 'nuevo',
            ownerId: 'user1',
          ),
          Book(
            id: 2,
            title: 'Ciencia Ficción 101',
            author: 'Científico Loco',
            isbn: '9780987654321',
            pagesNumber: 400,
            language: 'es',
            format: 'digital',
            file: 'path/to/file2',
            cover: 'path/to/cover2',
            summary: 'Un resumen interesante 2',
            categories: 'Science Fiction',
            state: 'nuevo',
            ownerId: 'user2',
          ),
        ];

        for (var book in booksList) {
          print('Book type: ${book.runtimeType}, categories: ${book.categories}');
        }

        return booksList;
      });


      when(() => mockCategoryService.getUserCategories())
          .thenAnswer((_) async => categoryResponse);

      final categories = await controller.getCategoriesFromBooks(userId);

      expect(categories.length, 3);
      expect(categories.map((c) => c.name),
          containsAll(['Fiction', 'Mystery', 'Science Fiction']));
      verify(() => mockBookService.getBooksForUser(userId)).called(1);
      verify(() => mockCategoryService.getUserCategories()).called(1);
    });

    test('isFavorite devuelve true cuando el libro está en favoritos', () async {
      const bookId = 42;

      final response = {
        'favorites': ['42', '55', '78']
      };

      when(() => mockUserService.getFavorites()).thenAnswer((_) async => response);

      final result = await controller.isFavorite(bookId);

      expect(result['isFavorite'], true);
      verify(() => mockUserService.getFavorites()).called(1);
    });

    test('addToFavorites retorna éxito', () async {
      const bookId = 42;

      when(() => mockUserService.addToFavorites(bookId)).thenAnswer((_) async {});

      final result = await controller.addToFavorites(bookId);

      expect(result['success'], true);
      expect(result['message'], contains('agregado'));
      verify(() => mockUserService.addToFavorites(bookId)).called(1);
    });

    test('removeFromFavorites retorna éxito', () async {
      const bookId = 42;

      when(() => mockUserService.removeFromFavorites(bookId)).thenAnswer((_) async {});

      final result = await controller.removeFromFavorites(bookId);

      expect(result['success'], true);
      expect(result['message'], contains('eliminado'));
      verify(() => mockUserService.removeFromFavorites(bookId)).called(1);
    });

    test('searchUsers devuelve lista vacía si servicio falla', () async {
      const query = 'John';

      when(() => mockUserService.searchUsers(query))
          .thenAnswer((_) async => []);

      final result = await controller.searchUsers(query);

      expect(result, isEmpty);
      verify(() => mockUserService.searchUsers(query)).called(1);
    });
  });
}

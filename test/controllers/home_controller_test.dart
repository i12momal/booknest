import 'package:booknest/controllers/home_controller.dart';
import 'package:booknest/services/book_service.dart';
import 'package:booknest/services/category_service.dart';
import 'package:booknest/services/user_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockUserService extends Mock implements UserService {}

class MockBookService extends Mock implements BookService {}

class MockCategoryService extends Mock implements CategoryService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late HomeController controller;
  late MockUserService mockUserService;
  late MockBookService mockBookService;
  late MockCategoryService mockCategoryService;

  setUp(() {
    mockUserService = MockUserService();
    mockBookService = MockBookService();
    mockCategoryService = MockCategoryService();

    controller = HomeController();
    controller.userService = mockUserService;
    controller.bookService = mockBookService;
    controller.categoryService = mockCategoryService;
  });

  group('HomeController', () {
    test('loadUserGenres devuelve categorías del usuario con imagen', () async {
      const userId = 'user123';

      final userGenres = ['Ficción', 'Historia'];
      final categoryData = {
        'success': true,
        'data': [
          {'name': 'Ficción', 'image': 'ficcion.jpg'},
          {'name': 'Historia', 'image': 'historia.jpg'},
          {'name': 'Ciencia', 'image': 'ciencia.jpg'},
        ],
      };

      when(() => mockUserService.getUserGenres(userId))
          .thenAnswer((_) async => userGenres);

      when(() => mockCategoryService.getUserCategories())
          .thenAnswer((_) async => categoryData);

      final result = await controller.loadUserGenres(userId);

      expect(result.length, 2);
      expect(result[0]['name'], 'Ficción');
      expect(result[0]['image'], 'ficcion.jpg');
      expect(result[1]['name'], 'Historia');
      expect(result[1]['image'], 'historia.jpg');

      verify(() => mockUserService.getUserGenres(userId)).called(1);
      verify(() => mockCategoryService.getUserCategories()).called(1);
    });

    test('loadBooksByUserCategories devuelve libros filtrados por categoría', () async {
      final categories = ['Terror', 'Romance'];
      final fakeBooks = [
        {'title': 'El Resplandor', 'category': 'Terror'},
        {'title': 'Orgullo y Prejuicio', 'category': 'Romance'},
      ];

      when(() => mockBookService.getBooksByCategories(categories))
          .thenAnswer((_) async => fakeBooks);

      final result = await controller.loadBooksByUserCategories(categories);

      expect(result, isA<List<Map<String, dynamic>>>());
      expect(result.length, 2);
      verify(() => mockBookService.getBooksByCategories(categories)).called(1);
    });

    test('loadAllBooks devuelve todos los libros disponibles', () async {
      final books = [
        {'title': '1984'},
        {'title': 'Cien Años de Soledad'},
      ];

      when(() => mockBookService.getAllBooks(includeUnavailable: false))
          .thenAnswer((_) async => books);

      final result = await controller.loadAllBooks();

      expect(result.length, 2);
      expect(result[0]['title'], '1984');
      verify(() => mockBookService.getAllBooks(includeUnavailable: false)).called(1);
    });

    test('searchBooksByTitleOrAuthor devuelve libros que coinciden con la búsqueda', () async {
      const query = 'Gabriel García Márquez';
      final books = [
        {'title': 'Cien Años de Soledad', 'author': 'Gabriel García Márquez'}
      ];

      when(() => mockBookService.searchBooksByTitleOrAuthor(query))
          .thenAnswer((_) async => books);

      final result = await controller.searchBooksByTitleOrAuthor(query);

      expect(result.length, 1);
      expect(result[0]['author'], contains('Gabriel'));
      verify(() => mockBookService.searchBooksByTitleOrAuthor(query)).called(1);
    });

    test('normalize elimina acentos y convierte a minúsculas', () {
      const input = 'Árbol Ñandú Éxito';
      final result = controller.normalize(input);
      expect(result, 'arbol nandu exito');
    });
  });
}

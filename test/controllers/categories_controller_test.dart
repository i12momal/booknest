import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:booknest/controllers/categories_controller.dart';
import 'package:booknest/services/category_service.dart';

class MockCategoryService extends Mock implements CategoryService {}

void main() {
  late CategoriesController controller;
  late MockCategoryService mockCategoryService;

  setUp(() {
    mockCategoryService = MockCategoryService();

    controller = CategoriesController();
    controller.categoryService = mockCategoryService;
  });

  group('CategoriesController', () {
    test('getCategories devuelve lista de nombres cuando éxito', () async {
      final mockResponse = {
        'success': true,
        'data': [
          {'name': 'Ficción'},
          {'name': 'No Ficción'},
          {'name': 'Ciencia'},
        ],
      };

      when(() => mockCategoryService.getCategories())
          .thenAnswer((_) async => mockResponse);

      final categories = await controller.getCategories();

      expect(categories, ['Ficción', 'No Ficción', 'Ciencia']);
      verify(() => mockCategoryService.getCategories()).called(1);
    });

    test('getCategories devuelve lista vacía cuando falla', () async {
      final mockResponse = {'success': false};

      when(() => mockCategoryService.getCategories())
          .thenAnswer((_) async => mockResponse);

      final categories = await controller.getCategories();

      expect(categories, []);
      verify(() => mockCategoryService.getCategories()).called(1);
    });
  });
}

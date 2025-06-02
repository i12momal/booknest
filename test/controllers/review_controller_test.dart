import 'package:booknest/controllers/review_controller.dart';
import 'package:booknest/entities/models/review_model.dart';
import 'package:booknest/entities/viewmodels/review_view_model.dart';
import 'package:booknest/services/review_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockReviewService extends Mock implements ReviewService {}

class CreateReviewViewModelFake extends Fake implements CreateReviewViewModel {}

class EditReviewViewModelFake extends Fake implements EditReviewViewModel {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ReviewController controller;
  late MockReviewService mockService;

  setUpAll(() {
    registerFallbackValue(CreateReviewViewModelFake());
    registerFallbackValue(EditReviewViewModelFake());
  });

  setUp(() {
    mockService = MockReviewService();
    controller = ReviewController();
    controller.reviewService = mockService;
  });

  group('ReviewController', () {
    test('getReviews devuelve una lista de reseñas si hay éxito', () async {
      const bookId = 1;
      final mockResponse = {
        'success': true,
        'data': [
          {
            'id': 1,
            'comment': 'Buen libro',
            'rating': 4,
            'userId': 'user1',
            'bookId': bookId
          }
        ]
      };

      when(() => mockService.fetchReviews(bookId))
          .thenAnswer((_) async => mockResponse);

      final result = await controller.getReviews(bookId);

      expect(result, isA<List<Review>>());
      expect(result.length, 1);
      expect(result.first.comment, 'Buen libro');
      verify(() => mockService.fetchReviews(bookId)).called(1);
      print('Reseñas obtenidas: $result');
    });

    test('getReviews devuelve lista vacía si falla la respuesta', () async {
      const bookId = 1;
      final mockResponse = {'success': false};

      when(() => mockService.fetchReviews(bookId))
          .thenAnswer((_) async => mockResponse);

      final result = await controller.getReviews(bookId);

      expect(result, isEmpty);
      verify(() => mockService.fetchReviews(bookId)).called(1);
      print('Reseñas vacías por error en servicio');
    });

    test('addReview retorna respuesta del servicio', () async {
      const comment = 'Excelente';
      const rating = 5;
      const userId = 'user1';
      const bookId = 1;

      final mockResponse = {'success': true, 'message': 'Reseña agregada'};

      when(() => mockService.addReview(any()))
          .thenAnswer((_) async => mockResponse);

      final result = await controller.addReview(comment, rating, userId, bookId);

      expect(result['success'], true);
      verify(() => mockService.addReview(any())).called(1);
      print('Reseña añadida: $result');
    });

    test('deleteReview elimina correctamente una reseña', () async {
      const reviewId = 1;
      final mockResponse = {'success': true, 'message': 'Eliminado correctamente'};

      when(() => mockService.deleteReview(reviewId))
          .thenAnswer((_) async => mockResponse);

      final result = await controller.deleteReview(reviewId);

      expect(result['success'], true);
      verify(() => mockService.deleteReview(reviewId)).called(1);
      print('Reseña eliminada: $result');
    });

    test('updateReview actualiza correctamente una reseña', () async {
      const id = 1;
      const comment = 'Comentario editado';
      const rating = 3;
      final mockResponse = {'success': true, 'message': 'Actualizado correctamente'};

      when(() => mockService.updateReview(any()))
          .thenAnswer((_) async => mockResponse);

      final result = await controller.updateReview(id, comment, rating);

      expect(result['success'], true);
      verify(() => mockService.updateReview(any())).called(1);
      print('Reseña actualizada: $result');
    });

    test('updateReview captura error y devuelve mensaje de fallo', () async {
      const id = 1;
      const comment = 'Comentario fallido';
      const rating = 2;

      when(() => mockService.updateReview(any()))
          .thenThrow(Exception('Error inesperado'));

      final result = await controller.updateReview(id, comment, rating);

      expect(result['success'], false);
      expect(result['message'], contains('Error al actualizar'));
      print('Error al actualizar reseña capturado correctamente');
    });
  });
}

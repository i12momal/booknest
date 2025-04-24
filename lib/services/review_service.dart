import 'package:booknest/entities/viewmodels/review_view_model.dart';
import 'package:booknest/services/base_service.dart';

class ReviewService extends BaseService {

  // Método para obtener reseñas por ID de libro
  Future<Map<String, dynamic>> fetchReviews(int bookId) async {
    try {
      if (BaseService.client == null) {
        return {'success': false, 'message': 'Error de conexión a la base de datos.'};
      }

      // Llamada para obtener las reseñas
      final response = await BaseService.client
          .from('Review')
          .select('id, comment, rating, userId, bookId')
          .eq('bookId', bookId);

      if (response != null && response.isNotEmpty) {
        return {
          'success': true,
          'message': 'Reseñas obtenidas correctamente',
          'data': response
        };
      } else {
        return {'success': false, 'message': 'No se encontraron reseñas'};
      }
    } catch (ex) {
      return {'success': false, 'message': ex.toString()};
    }
  }

  // Método asíncrono para añadir una reseña a un libro
  Future<Map<String, dynamic>> addReview(CreateReviewViewModel createReviewViewModel) async {
    try {
      if (BaseService.client == null) {
        return {'success': false, 'message': 'Error de conexión a la base de datos.'};
      }

      // Crear el registro en la tabla Book 
      print("Creando registro en la tabla Review...");
      final Map<String, dynamic> reviewData = {
        'comment': createReviewViewModel.comment,
        'rating': createReviewViewModel.rating,
        'userId': createReviewViewModel.userId,
        'bookId': createReviewViewModel.bookId
      };
      print("Datos a insertar: $reviewData");

      final response = await BaseService.client.from('Review').insert(reviewData).select().single();

      print("Respuesta de la inserción en Review: $response");

      if (response != null) {
        print("Reseña registrada exitosamente");

        return {
          'success': true,
          'message': 'Reseña registrada exitosamente',
          'data': response
        };
      } else {
        print("Error: No se pudo crear el registro en la tabla Review");
        return {'success': false, 'message': 'Error al registrar la reseña'};
      }
    } catch (ex) {
      print("Error en addReview: $ex");
      return {'success': false, 'message': ex.toString()};
    }
  }

}
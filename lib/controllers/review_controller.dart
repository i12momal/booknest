import 'package:booknest/controllers/base_controller.dart';
import 'package:booknest/entities/models/review_model.dart';
import 'package:booknest/entities/viewmodels/review_view_model.dart';


// Controlador con los métodos de las acciones de Reseñas y Valoraciones.
class ReviewController extends BaseController {

  // Método asíncrono para obtener las reseñas de un libro.
  Future<List<Review>> getReviews(int bookId) async {
    var response = await reviewService.fetchReviews(bookId);

    if (response['success']) {
      // Convertir las reseñas en una lista de ReviewModel
      List<Review> reviews = [];
      for (var review in response['data']) {
        var reviewItem = Review(
          id: review['id'],
          comment: review['comment'],
          rating: review['rating'],
          userId: review['userId'],
          bookId: review['bookId'],
        );
        reviews.add(reviewItem);
      }

      return reviews;
    } else {
      // Si no se obtuvieron reseñas, devolver una lista vacía
      return [];
    }
  }

  // Método asíncrono para añadir una nueva reseña a un libro
  Future<Map<String, dynamic>> addReview(String comment, int rating, String userId, int bookId) async {
    // Creación del viewModel
    final addReviewViewModel = CreateReviewViewModel(
      comment: comment,
      rating: rating,
      userId: userId,
      bookId: bookId
    );
    
    // Llamada al servicio para registrar al usuario
    return await reviewService.addReview(addReviewViewModel);
  }

  // Método asíncrono para eliminar una reseña.
  Future<Map<String, dynamic>> deleteReview(int reviewId) async {
    return await reviewService.deleteReview(reviewId);
  }

  // Método asíncrono para editar una reseña.
  Future<Map<String, dynamic>> updateReview(int id, String comment, int rating) async {
    // Crear viewModel con los datos editados
    final editReviewViewModel = EditReviewViewModel(
      id: id,
      comment: comment,
      rating: rating
    );

    // Llamar al servicio para actualizar la reseña
    try {
      print("Llamando al servicio para editar la reseña...");
      return await reviewService.updateReview(editReviewViewModel);
    } catch (e) {
      print("Error al editar la reseña: $e");
      return {
        'success': false,
        'message': 'Error al actualizar los datos de la reseña. Por favor, intente nuevamente.'
      };
    }
  }

}

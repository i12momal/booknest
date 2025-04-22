import 'package:booknest/controllers/base_controller.dart';
import 'package:booknest/entities/models/review_model.dart';


// Controlador con los métodos de las acciones de Reseñas y Valoraciones.
class ReviewController extends BaseController {

  // Método para obtener las reseñas de un libro
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

}

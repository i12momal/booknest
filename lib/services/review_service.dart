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

}

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
          .select('id, comment, rating, userId, bookId, created_at')
          .eq('bookId', bookId).order('created_at', ascending: false);

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

  Future<Map<String, dynamic>> deleteReview(int reviewId) async {
    try {
      final reviewResponse = await BaseService.client
          .from('Review')
          .delete()
          .eq('id', reviewId)
          .select();

      if (reviewResponse.isNotEmpty) {
        return {'success': true};
      } else {
        return {
          'success': false,
          'message': 'Reseña no encontrada o no se pudo eliminar'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error al eliminar la reseña'};
    }
  }


   Future<Map<String, dynamic>> updateReview(EditReviewViewModel editReviewViewModel) async {
    try {
      // Comprobamos si la conexión a Supabase está activa.
      if (BaseService.client == null) {
        return {'success': false, 'message': 'Error de conexión a la base de datos.'};
      }

      // Verificar que el libro existe
      print("Verificando existencia de la reseña...");
      final existingReview = await BaseService.client.from('Review').select().eq('id', editReviewViewModel.id).single();
      if (existingReview == null) {
        print("Error: Reseña no encontrada en la base de datos");
        return {'success': false, 'message': 'Reseña no encontrada'};
      }

      // Preparar los datos para actualización
      final Map<String, dynamic> updateData = {};

      // Solo agregar campos que han cambiado
      if (existingReview['comment'] != editReviewViewModel.comment) {
        updateData['comment'] = editReviewViewModel.comment;
      }
      if (existingReview['rating'] != editReviewViewModel.rating) {
        updateData['rating'] = editReviewViewModel.rating;
      }

      print("Datos a actualizar: $updateData");

      // Si no hay cambios, retornar éxito sin actualizar
      if (updateData.isEmpty) {
        print("No hay cambios para actualizar");
        return {'success': true, 'message': 'No hay cambios para actualizar', 'data': existingReview};
      }

      // Actualizar la reseña y obtener los datos actualizados en una sola operación
      final response = await BaseService.client
          .from('Review')
          .update(updateData)
          .eq('id', editReviewViewModel.id)
          .select()
          .single();

      if (response != null) {
        return {'success': true, 'message': 'Reseña actualizada exitosamente', 'data': response};
      } else {
        print("Error: No se pudo actualizar la reseña");
        return {'success': false, 'message': 'Error al editar la información de la reseña'};
      }
    } catch (ex) {
      print("Error en updateReview: $ex");
      return {'success': false, 'message': ex.toString()};
    }
  }


}
import 'package:booknest/services/base_service.dart';

// Servicio con los métodos de negocio de la entidad Categoría.
class CategoryService extends BaseService {

  // Método asíncrono que obtiene las categorías de libros existentes.
  Future<Map<String, dynamic>> getCategories() async {
    try {
      // Comprobamos si la conexión a Supabase está activa.
      if (BaseService.client == null) {
        return {'success': false, 'message': 'Error de conexión a la base de datos.'};
      }

      // Llamada a la base de datos para obtener las categorías.
      final response = await BaseService.client.from('Categories').select().order('name', ascending: true);

      // Verificamos si la respuesta contiene datos.
      if (response != null && response.isNotEmpty) {
        return {'success': true, 'message': 'Categorías obtenidas correctamente', 'data': response};
      } else {
        return {'success': false, 'message': 'No se encontraron categorías'};
      }
    } catch (ex) {
      // Si ocurre alguna excepción, devolverla.
      return {'success': false, 'message': ex.toString()};
    }
  }
}

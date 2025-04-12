import 'package:booknest/controllers/base_controller.dart';

// Controlador con los métodos de las acciones de la página Home.
class HomeController extends BaseController {

  /* Método asíncrono que obtiene los géneros seleccionados por el usuario.
    Parámetros:
      - userId: Cadena con el identificador del usuario.
    Return:
      - Lista con las categorías seleccionadas por el usuario.
  */
  Future<List<Map<String, dynamic>>> loadUserGenres(String userId) async {
    try {
      // Obtenemos los géneros de usuario
      List<String> userGenres = await userService.getUserGenres(userId);

      // Obtenemos las categorías del servicio
      final categoriesResponse = await categoryService.getUserCategories();

      if (categoriesResponse['success']) {
        List categoriesData = categoriesResponse['data'];

        // Filtramos las categorías de usuario, buscando las categorías disponibles en el servicio
        List<Map<String, dynamic>> userCategories = categoriesData
            .where((category) => userGenres.contains(category['name']))
            .map((category) => {
                  'name': category['name'],
                  'image': category['image'],  // Aseguramos que la imagen esté incluida
                })
            .toList();

        return userCategories;  // Esto ahora devuelve una lista de Map<String, dynamic>
      } else {
        throw Exception('Error al obtener las categorías');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Método que obtiene una lista con los libros ordenados por categorías
  Future<List<Map<String, dynamic>>> loadBooksByUserCategories(List<String> categoryNames) {
    return bookService.getBooksByCategories(categoryNames);
  }
}

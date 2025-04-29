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

  // Método que obtiene una lista con todos los libros existentes
  Future<List<Map<String, dynamic>>> loadAllBooks({bool includeUnavailable = false}) {
    return bookService.getAllBooks(includeUnavailable: includeUnavailable);
  }

  // Método para buscar libros por título o autor
  Future<List<Map<String, dynamic>>> searchBooksByTitleOrAuthor(String query) async {
    return await bookService.searchBooksByTitleOrAuthor(query);
  }

  String normalize(String input) {
    const Map<String, String> accentMap = {
      'á': 'a', 'à': 'a', 'ä': 'a', 'â': 'a', 'ã': 'a',
      'é': 'e', 'è': 'e', 'ë': 'e', 'ê': 'e',
      'í': 'i', 'ì': 'i', 'ï': 'i', 'î': 'i',
      'ó': 'o', 'ò': 'o', 'ö': 'o', 'ô': 'o', 'õ': 'o',
      'ú': 'u', 'ù': 'u', 'ü': 'u', 'û': 'u',
      'ñ': 'n',
      'Á': 'a', 'À': 'a', 'Ä': 'a', 'Â': 'a', 'Ã': 'a',
      'É': 'e', 'È': 'e', 'Ë': 'e', 'Ê': 'e',
      'Í': 'i', 'Ì': 'i', 'Ï': 'i', 'Î': 'i',
      'Ó': 'o', 'Ò': 'o', 'Ö': 'o', 'Ô': 'o', 'Õ': 'o',
      'Ú': 'u', 'Ù': 'u', 'Ü': 'u', 'Û': 'u',
      'Ñ': 'n',
    };

    return input
        .split('')
        .map((char) => accentMap[char] ?? char)
        .join()
        .toLowerCase();
  }

}
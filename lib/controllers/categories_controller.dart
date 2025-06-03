import 'package:booknest/controllers/base_controller.dart';

// Controlador con los métodos de las acciones de Categoría.
class CategoriesController extends BaseController {

  // Método asíncrono que devuelve una lista con las categorías existentes.
  Future<List<String>> getCategories() async {
    var response = await categoryService.getCategories();
    if (response['success']) {
      return List<String>.from(response['data'].map((category) => category['name']));
    }
    return [];
  }

}

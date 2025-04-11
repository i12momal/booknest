import 'package:booknest/controllers/base_controller.dart';

// Controlador con los métodos de las acciones de la página Home.
class HomeController extends BaseController {

  /* Método que obtiene los géneros seleccionados por el usuario.
    Parámetros:
      - userId: Cadena con el identificador del usuario.
    Return:
      - Lista con las categorías seleccionadas por el usuario.
  */
  Future<List<String>> loadUserGenres(String userId) async {
    return await userService.getUserGenres(userId);
  }
}

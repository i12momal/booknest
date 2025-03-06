import "base_controller.dart";

// Controlador con los métodos de las acciones de Usuarios.
class UserController extends BaseController{

  Future<Map<String, dynamic>> registerUser(String name, String userName, int age, String email, int phoneNumber, String address, String password, String image) async {
    return await userService.registerUser(name, userName, age, email, phoneNumber, address, password, image);
  }
}
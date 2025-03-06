import 'package:booknest/services/user_service.dart';

abstract class BaseController {
  final UserService userService = UserService();

  BaseController();
}

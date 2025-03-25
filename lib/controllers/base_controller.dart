import 'package:booknest/services/account_service.dart';
import 'package:booknest/services/category_service.dart';
import 'package:booknest/services/user_service.dart';

abstract class BaseController {
  final AccountService accountService = AccountService();
  final CategoryService categoryService = CategoryService();
  final UserService userService = UserService();

  BaseController();
}
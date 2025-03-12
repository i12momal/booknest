import 'package:booknest/services/account_service.dart';

abstract class BaseController {
  final AccountService accountService = AccountService();

  BaseController();
}

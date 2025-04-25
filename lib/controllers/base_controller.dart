import 'package:booknest/services/account_service.dart';
import 'package:booknest/services/category_service.dart';
import 'package:booknest/services/loan_service.dart';
import 'package:booknest/services/review_service.dart';
import 'package:booknest/services/user_service.dart';
import 'package:booknest/services/book_service.dart';

abstract class BaseController {
  final AccountService accountService = AccountService();
  final CategoryService categoryService = CategoryService();
  final UserService userService = UserService();
  final BookService bookService = BookService();
  final ReviewService reviewService = ReviewService();
  final LoanService loanService = LoanService();

  BaseController();
}
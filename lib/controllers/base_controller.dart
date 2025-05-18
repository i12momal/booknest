import 'package:booknest/services/account_service.dart';
import 'package:booknest/services/category_service.dart';
import 'package:booknest/services/chat_message_service.dart';
import 'package:booknest/services/geolocation_service.dart';
import 'package:booknest/services/loan_chat_service.dart';
import 'package:booknest/services/loan_service.dart';
import 'package:booknest/services/reminder_service.dart';
import 'package:booknest/services/review_service.dart';
import 'package:booknest/services/user_service.dart';
import 'package:booknest/services/book_service.dart';
import 'package:booknest/services/notification_service.dart';

abstract class BaseController {
  final AccountService accountService = AccountService();
  final CategoryService categoryService = CategoryService();
  final UserService userService = UserService();
  final BookService bookService = BookService();
  final ReviewService reviewService = ReviewService();
  final LoanService loanService = LoanService();
  final NotificationService notificationService = NotificationService();
  final ReminderService reminderService = ReminderService();
  final GeolocationService geolocationService = GeolocationService();
  final LoanChatService loanChatService = LoanChatService();
  final ChatMessageService chatMessageService = ChatMessageService();

  BaseController();
}
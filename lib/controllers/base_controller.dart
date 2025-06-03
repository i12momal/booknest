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

// Controlador Base con la definición de los servicios.
abstract class BaseController {
  late AccountService accountService = AccountService();
  late CategoryService categoryService = CategoryService();
  late UserService userService = UserService();
  late BookService bookService = BookService();
  late ReviewService reviewService = ReviewService();
  late LoanService loanService = LoanService();
  late NotificationService notificationService = NotificationService();
  late ReminderService reminderService = ReminderService();
  late GeolocationService geolocationService = GeolocationService();
  late LoanChatService loanChatService = LoanChatService();
  late ChatMessageService chatMessageService = ChatMessageService();

  BaseController();
}
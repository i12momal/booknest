import 'package:booknest/controllers/base_controller.dart';
import 'package:booknest/controllers/notification_controller.dart';
import 'package:booknest/controllers/reminder_controller.dart';
import 'package:booknest/entities/models/book_model.dart';
import 'package:booknest/entities/viewmodels/loan_view_model.dart';

// Controlador con los métodos de las acciones de Préstamos.
class LoanController extends BaseController{

  // Método asíncrono para solicitar el préstamo de un libro
  Future<Map<String, dynamic>> requestLoan(Book book, String format) async {
    final userId = await accountService.getCurrentUserId();
    if (userId == null) {
      return {'success': false, 'message': 'Usuario no autenticado'};
    }

    final DateTime startDate = DateTime.now();
    final DateTime endDate = startDate.add(const Duration(days: 30));

    final createLoanViewModel = CreateLoanViewModel(
      ownerId: book.ownerId,
      currentHolderId: userId,
      bookId: book.id,
      startDate: startDate.toIso8601String(),
      endDate: endDate.toIso8601String(),
      format: format,
      state: "Pendiente",
      currentPage: 0,
    );

    final response = await loanService.createLoan(createLoanViewModel);

    String? notificationId;

    if (response['success'] && response['data'] != null) {
      final loan = response['data'];
      final bookTitle = book.title;
      final ownerId = book.ownerId;

      final notificationResponse = await NotificationController().createNotification(
        ownerId,
        'Préstamo',
        loan['id'],
        'Has recibido una nueva solicitud de préstamo para tu libro "$bookTitle".',
      );

      if (notificationResponse['success'] && notificationResponse['data'] != null) {
        notificationId = notificationResponse['data']['id']?.toString();
      }
    }

    // Devuelve el response original y, si existe, el ID de la notificación
    return {
      ...response,
      if (notificationId != null) 'notificationId': notificationId,
    };
  }


  // Método que obtiene los libros que han sido prestados a un usuario
  Future<List<Map<String, dynamic>>> getLoansByHolder(String userId) async {
    return await loanService.getLoansByHolder(userId);
  }


  // Método que obtiene las solicitudes de préstamos de un usuario
  Future<List<Map<String, dynamic>>> getPendingLoansForUser(String userId) async {
    return await loanService.getUserPendingLoans(userId);
  }

  Future<Map<String, dynamic>> getLoanById(int loanId) async {
    return await loanService.getLoanById(loanId);
  }

  // Cambiar el estado del préstamo
  Future<void> updateLoanState(int loanId, String newState) async {
    try {
      final loanResponse = await loanService.getLoanById(loanId);
      if (loanResponse == null || loanResponse['data'] == null) {
        print('Error: El préstamo con id $loanId no fue encontrado o está mal formado.');
        return;
      }

      final loan = loanResponse['data'];
      print('loan: $loan');

     
      final bookResponse = await bookService.getBookById(loan['bookId']);
      if (bookResponse == null || bookResponse['data'] == null) {
        print('Error: No se encontró el libro con id ${loan['bookId']}');
        return;
      }

      // Acceder al título del libro
      final bookName = bookResponse['data']['title'];

      final userId = loan['currentHolderId'];
      if (userId == null) {
        print('Error: El id del usuario actual (currentHolderId) es nulo.');
        return;
      }

      // Actualizar el estado del préstamo
      await loanService.updateLoanState(loanId, newState);

      // Si el préstamo ha sido aceptado, se notifica al usuario que lo ha solicitado
      if (newState == 'Aceptado') {
        String message = 'Tu solicitud de préstamo para el libro "$bookName" en formato ${loan['format']} ha sido aceptada.';
        await NotificationController().createNotification(userId, 'Préstamo Aceptado', loanId, message);
      }

      final ownerId = loan['ownerId'];
      // Si el préstamo ha sido devuelto, se notifica al propietario del libro
      if (newState.trim().toLowerCase() == 'devuelto') {
        String message = 'Tu libro "$bookName" en formato ${loan['format']} ha sido devuelto.';
        await NotificationController().createNotification(ownerId, 'Préstamo Devuelto', loanId, message);

        final format = loan['format'] as String;
        final bookId = loan['bookId'] as int;

        // Obtener todos los recordatorios del libro
        final allReminders = await ReminderController().getRemindersByBook(bookId);

        // Filtrar solo los que coinciden con el formato y no han sido notificados
        final usersToNotify = allReminders
            .where((r) => r.format.trim().toLowerCase() == format.trim().toLowerCase() && !r.notified)
            .map((r) => r.userId)
            .toSet()
            .toList();

        if (usersToNotify.isNotEmpty) {
          final String messageReminder = 'El libro "$bookName" en formato $format vuelve a estar disponible.';
          for (String userId in usersToNotify) {
            await NotificationController().createNotification(userId, 'Recordatorio', bookId, messageReminder);

            // Marcar como notificado
            await ReminderController().markAsNotified(bookId, userId, format);

            // Verificar si TODOS los formatos ya están disponibles
            final bookFormats = (bookResponse['data']['format'] as String)
                .split(',')
                .map((f) => f.trim())
                .toList();

            final allAvailable = await loanService.areAllFormatsAvailable(bookId, bookFormats);

            if (allAvailable) {
              // Eliminar todos los recordatorios del usuario para ese libro
              for (final f in bookFormats) {
                await ReminderController().removeFromReminder(bookId, userId, f);
              }
            }
          }
        }
      }

      // Si el préstamo ha sido rechazado, se notifica al usuario que ha solicitado el libro
      if (newState == 'Rechazado') {
        String message = 'Tu solicitud de préstamo para el libro "$bookName" en formato ${loan['format']} ha sido rechazada.';
        await NotificationController().createNotification(userId, 'Préstamo Rechazado', loanId, message);
      }
    } catch (e) {
      print('Error al actualizar el estado del préstamo: $e');
    }
  }


  Future<bool> areAllFormatsAvailable(int bookId) async {
    final bookResponse = await bookService.getBookById(bookId);
    if (bookResponse == null || bookResponse['data'] == null) {
      print('Error: No se encontró el libro');
      return false;
    }

    final formats = (bookResponse['data']['format'] as String).split(',').map((f) => f.trim()).toList();
    bool allFormatsAvailable = true;

    for (var format in formats) {
      final activeLoan = await loanService.getActiveLoanForBookAndFormat(bookId, format);
      if (activeLoan != null) {
        allFormatsAvailable = false;
        break;
      }
    }

    return allFormatsAvailable;
  }

  Future<void> handleBookReturnAndNotification(int bookId, String format) async {
    final usersIdForReminder = await ReminderController().getUsersIdForReminder(bookId);
    final bookResponse = await bookService.getBookById(bookId);

    if (bookResponse == null || bookResponse['data'] == null) {
      print('Error: No se encontró el libro');
      return;
    }

    final bookName = bookResponse['data']['title'];

    // Enviar notificación a los usuarios con recordatorio
    for (String userId in usersIdForReminder) {
      String messageReminder = 'El libro "$bookName" en formato $format vuelve a estar disponible.';
      await NotificationController().createNotification(userId, 'Recordatorio', bookId, messageReminder);
    }

    // Verificar si todos los formatos están disponibles
    bool allFormatsAvailable = await areAllFormatsAvailable(bookId);

    if (allFormatsAvailable) {
      // Si todos los formatos están disponibles, desactivar la campana
      await ReminderController().updateReminderStateForAllUsers(bookId, false);
    }
  }

  Future<void> saveCurrentPageProgress(String userId, int bookId, int currentPage) async {
    try {
      final loan = await loanService.getLoanByUserAndBook(userId, bookId);
      if (loan != null) {
        final loanId = loan['id'];
        await loanService.updateCurrentPage(loanId, currentPage);
        print("Página guardada correctamente.");
      } else {
        print("No se encontró un préstamo activo para este usuario y libro.");
      }
    } catch (e) {
      print("Error en LoanController.saveCurrentPageProgress: $e");
    }
  }


  // Método para obtener el progreso de la página guardada
  Future<int?> getSavedPageProgress(String userId, int bookId) async {
    return await loanService.getSavedPageProgress(userId, bookId);
  }

  Future<List<String>> fetchAvailableFormats(int bookId, List<String> formats) async {
    try {
      // Llamamos al servicio para obtener los formatos disponibles
      final availableFormats = await loanService.getAvailableFormats(bookId, formats);
      return availableFormats;
    } catch (e) {
      print('Error en BookController.fetchAvailableFormats: $e');
      return [];
    }
  }

  Future<List<String>> fetchLoanedFormats(int bookId) async {
    try {
      return await loanService.getLoanedFormats(bookId);
    } catch (e) {
      print('Error en BookController.fetchLoanedFormats: $e');
      return [];
    }
  }
  

  Future<List<Map<String, dynamic>>> getLoansByBookId(int bookId) async {
    return await loanService.getLoansByBookId(bookId);
  }


  Future<Map<String, dynamic>> cancelLoanRequest(int bookId, int? notificationId) async {
    return await loanService.cancelLoan(bookId, notificationId);
  }

  // Método que comprueba si el usuario ya ha realizado una solicitud de préstamo para un libro
  Future<Map<String, dynamic>> checkExistingLoanRequest(int bookId, String userId) async {
    return await loanService.checkExistingLoanRequest(bookId, userId);
  }

  
}
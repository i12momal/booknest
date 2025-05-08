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
      if (newState == 'Devuelto') {
        String message = 'Tu libro "$bookName" en formato ${loan['format']} ha sido devuelto.';
        await NotificationController().createNotification(ownerId, 'Préstamo Devuelto', loanId, message);

         print('ids del libro cpn recordatorio ${bookResponse['data']['id']}');
        // Se envía un mensaje a todos aquellos que hayan activado la campana de recordatorio para ese libro
        //1. Obtenemos el id de los usuarios
        List<String> usersIdreminder = await ReminderController().getUsersIdForReminder(bookResponse['data']['id']);
        print('ids de los usuarios que solicitaron recordatorio para este libro $usersIdreminder');
        //2. Creamos mensaje para cada uno de ellos
        String messageReminder = 'El libro "$bookName" en formato ${loan['format']} vuelve a estar disponible.';
        for(String user in usersIdreminder){
          await NotificationController().createNotification(user, 'Recordatorio', loan['bookId'], messageReminder);
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

  // Método para devolver el libro
  Future<void> updateLoanStateToReturned(int loanId) async {
    try {
      // Lógica para actualizar el estado del préstamo a "Devuelto"
      await loanService.updateLoanState(loanId, 'Devuelto');
    } catch (e) {
      print('Error al actualizar el estado del préstamo: $e');
      rethrow;
    }
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
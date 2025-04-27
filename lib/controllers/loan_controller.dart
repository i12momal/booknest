import 'package:booknest/controllers/base_controller.dart';
import 'package:booknest/controllers/notification_controller.dart';
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
    );

    final response = await loanService.createLoan(createLoanViewModel);

    // 🚨 NUEVO: Si el préstamo se creó correctamente, crear notificación para el dueño
    if (response['success'] && response['data'] != null) {
      final loan = response['data'];
      final bookTitle = book.title;
      final ownerId = book.ownerId;

      // Verificar el loan['id']
      print("ID del préstamo: ${loan['id']}");

      // Crear notificación para el dueño del libro
      await NotificationController().createNotification(
        ownerId,
        'Préstamo',
        loan['id'],
        'Has recibido una nueva solicitud de préstamo para tu libro "$bookTitle".', 
      );
    }

    return response;
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
    final loan = await loanService.getLoanById(loanId);
    //final bookName = await bookService.getBookById(loan['bookId']);
    //final userId = loan['ownerId'];

    // Actualizar el estado del préstamo
    await loanService.updateLoanState(loanId, newState);

    // Crear la notificación
    /*String message;
    switch (newState) {
      case 'Pendiente':
        message = 'Tu solicitud de préstamo para el libro "$bookName" está pendiente.';
        break;
      case 'Aceptado':
        message = 'Tu solicitud de préstamo para el libro "$bookName" ha sido aceptada.';
        break;
      case 'Rechazado':
        message = 'Tu solicitud de préstamo para el libro "$bookName" ha sido rechazada.';
        break;
      case 'Devuelto':
        message = 'El libro "$bookName" ha sido devuelto.';
        break;
      default:
        message = 'Estado del préstamo actualizado.';
    }

    // Crear la notificación de estado
    await NotificationController().createNotification(userId, 'loan', loanId, message);*/
  }

}
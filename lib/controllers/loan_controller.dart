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
      currentPage: 0,
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
      // Obtener los datos del préstamo correctamente desde 'loan['data']'
      final loanResponse = await loanService.getLoanById(loanId);
      
      // Verificar si loanResponse es null o si no contiene los datos esperados
      if (loanResponse == null || loanResponse['data'] == null) {
        print('Error: El préstamo con id $loanId no fue encontrado o está mal formado.');
        return;  // Salir si no se encuentra el préstamo
      }

      final loan = loanResponse['data'];  // Acceder a los datos del préstamo
      print('loan: $loan');

      // Obtener el bookName correctamente
      final bookResponse = await bookService.getBookById(loan['bookId']);
      
      // Verificar si bookResponse es null o no contiene los datos esperados
      if (bookResponse == null || bookResponse['data'] == null) {
        print('Error: No se encontró el libro con id ${loan['bookId']}');
        return;
      }

      // Acceder al título del libro
      final bookName = bookResponse['data']['title'];
      print('bookName: $bookName');

      final userId = loan['currentHolderId'];

      // Verificar si userId es null
      if (userId == null) {
        print('Error: El id del usuario actual (currentHolderId) es nulo.');
        return;
      }
      print('userId: $userId');

      // Actualizar el estado del préstamo
      await loanService.updateLoanState(loanId, newState);

      if (newState == 'Aceptado') {
        String message = 'Tu solicitud de préstamo para el libro "$bookName" ha sido aceptada.';
        await NotificationController().createNotification(userId, 'Préstamo Aceptado', loanId, message);
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


  Future<Map<String, dynamic>> cancelLoanRequest(int bookId) async {
    return await loanService.cancelLoan(bookId);
  }
  
}
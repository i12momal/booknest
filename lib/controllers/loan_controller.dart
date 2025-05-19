import 'package:booknest/controllers/account_controller.dart';
import 'package:booknest/controllers/base_controller.dart';
import 'package:booknest/controllers/chat_message_controller.dart';
import 'package:booknest/controllers/notification_controller.dart';
import 'package:booknest/controllers/reminder_controller.dart';
import 'package:booknest/entities/models/book_model.dart';
import 'package:booknest/entities/viewmodels/loan_view_model.dart';

// Controlador con los métodos de las acciones de Préstamos.
class LoanController extends BaseController{

  // Método asíncrono para solicitar el préstamo de un libro
    Future<Map<String, dynamic>> requestLoan(Book book, String format, List<Book>? selectedBooks) async {
      try {
        // Verificamos si el usuario está autenticado
        final userId = await accountService.getCurrentUserId();
        print('userId: $userId'); // Imprimir para verificar si el usuario está autenticado
        if (userId == null) {
          print('Usuario no autenticado'); // Si no está autenticado, regresamos un mensaje
          return {'success': false, 'message': 'Usuario no autenticado'};
        }

        final DateTime startDate = DateTime.now();
        final DateTime endDate = startDate.add(const Duration(days: 30));
        print('startDate: $startDate, endDate: $endDate'); // Imprimir las fechas

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

        // Intentamos crear el préstamo
        final response = await loanService.createLoan(createLoanViewModel);
        print('createLoan response: $response'); // Imprimir la respuesta de la creación del préstamo

        String? notificationId;

        if (response['success'] && response['data'] != null) {
          final loan = response['data'];
          final bookTitle = book.title;
          final ownerId = book.ownerId;

          String? selectedBookTitles;

          if (format.toLowerCase() == 'físico' && selectedBooks != null && selectedBooks.isNotEmpty) {
            selectedBookTitles = selectedBooks.map((b) => '"${b.title}"').join(', ');
          }

          final notificationMessage = selectedBookTitles != null
            ? 'Has recibido una nueva solicitud de préstamo para tu libro "$bookTitle". El usuario ha incluido los siguientes libros físicos como contraprestación: $selectedBookTitles'
            : 'Has recibido una nueva solicitud de préstamo para tu libro "$bookTitle".';


          final notificationResponse = await NotificationController().createNotification(
            ownerId,
            'Préstamo',
            loan['id'],
            notificationMessage
          );
          print('notificationResponse: $notificationResponse'); // Imprimir la respuesta de la notificación

          if (notificationResponse['success'] && notificationResponse['data'] != null) {
            notificationId = notificationResponse['data']['id']?.toString();
            print('notificationId: $notificationId'); // Imprimir el ID de la notificación
          }
        }

        final formats = book.format.split(',').map((f) => f.trim().toLowerCase()).toList();

        final loanedFormats = await loanService.getLoanedFormatsAndStates(book.id);
        final loanedFormatsNormalized = loanedFormats.map((format) => {
          'format': format['format'].toString().trim().toLowerCase(),
          'state': format['state'].toString().trim().toLowerCase(),
        }).toList();

        print('formats: $formats');
        print('loanedFormatsNormalized: $loanedFormatsNormalized');

        String estadoLibro = 'Disponible';

        if (formats.length == 2) {
          final acceptedCount = loanedFormatsNormalized.where((f) => f['state'] == 'aceptado').length;
          final pendingCount = loanedFormatsNormalized.where((f) => f['state'] == 'pendiente').length;

          print('Aceptados: $acceptedCount, Pendientes: $pendingCount');

          // Casos en los que debe ser No Disponible
          if ((acceptedCount == 2) || (pendingCount == 2) || (acceptedCount == 1 && pendingCount == 1)) {
            estadoLibro = 'No Disponible';
          }
        } else if (formats.length == 1 && loanedFormatsNormalized.isNotEmpty) {
          final state = loanedFormatsNormalized.first['state'];
          if (state == 'pendiente' || state == 'aceptado') {
            estadoLibro = 'Pendiente';
          }
        }

        print('Estado final del libro: $estadoLibro');
        await bookService.changeState(book.id, estadoLibro);

      // Devuelve el response original y, si existe, el ID de la notificación
      return {
        ...response,
        if (notificationId != null) 'notificationId': notificationId,
      };
    } catch (e) {
      print('Error en requestLoan: $e'); // Si ocurre un error, lo imprimimos
      return {'success': false, 'message': 'Error al realizar la solicitud de préstamo'};
    }
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
  Future<void> updateLoanState(int loanId, String newState, {String? compensation, int? compensationLoanId}) async {
    try {
      final loanResponse = await loanService.getLoanById(loanId);
      if (loanResponse == null || loanResponse['data'] == null) {
        print('Error: El préstamo con id $loanId no fue encontrado o está mal formado.');
        return;
      }

      final loan = loanResponse['data'];
     
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
      if (newState == 'Aceptado' && loan['format'].toString().toLowerCase().contains('físico')) {
        String compensationText = compensation != null ? '\nContraprestación acordada: $compensation.' : '';
        String message = 'Tu solicitud de préstamo para el libro "$bookName" en formato ${loan['format']} ha sido aceptada.$compensationText';

        await NotificationController().createNotification(userId, 'Préstamo Aceptado', loanId, message);

        // Crear conversación
        final ownerId = loan['ownerId'];
        final requesterId = loan['currentHolderId'];

        final ownerResponse = await userService.getUserById(ownerId);
        final requesterResponse = await userService.getUserById(requesterId);

        if (ownerResponse == null || requesterResponse == null) {
          print('Error: No se pudo obtener información de los usuarios involucrados.');
          return;
        }

        final ownerName = ownerResponse['data']['name'];
        final owneruserName = ownerResponse['data']['userName'];
        final ownerEmail = ownerResponse['data']['email'];

        final requesterName = requesterResponse['data']['name'];
        final requesteruserName = requesterResponse['data']['userName'];
        final requesterEmail = requesterResponse['data']['email'];

        // Crear mensajes personalizados para cada usuario
        String chatMessageForOwner = 'Ha iniciado un nuevo intercambio con el usuario $requesterName ($requesteruserName): $bookName a cambio de $compensation. Póngase en contacto para acordar la fecha, hora y lugar de la quedada. Correo electrónico: $requesterEmail';
        String chatMessageForRequester = 'Ha iniciado un nuevo intercambio con el usuario $ownerName ($owneruserName): $bookName a cambio de $compensation. Póngase en contacto para acordar la fecha, hora y lugar de la quedada. Correo electrónico: $ownerEmail';

        // Crear chat (si no existe) y enviar mensajes a ambos
        final chatId = await loanChatService.createChatIfNotExists(loan['id'], ownerId, requesterId, compensationLoanId);
        
        await ChatMessageController().createChatMessage(ownerId, chatId, chatMessageForOwner);
        await ChatMessageController().createChatMessage(requesterId, chatId, chatMessageForRequester);

        // Se guarda la compensación
        await loanService.updateCompensation(compensation, loan['id']);
      } else if (newState == 'Aceptado') {
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
        final usersToNotify = allReminders.where((r) => r.format.trim().toLowerCase() == format.trim().toLowerCase() && !r.notified).map((r) => r.userId).toSet().toList();

        if (usersToNotify.isNotEmpty) {
          final String messageReminder = 'El libro "$bookName" en formato $format vuelve a estar disponible.';
          for (String userId in usersToNotify) {
            await NotificationController().createNotification(userId, 'Recordatorio', bookId, messageReminder);

            // Marcar como notificado
            await ReminderController().markAsNotified(bookId, userId, format);

            // Verificar si TODOS los formatos ya están disponibles
            final bookFormats = (bookResponse['data']['format'] as String).split(',').map((f) => f.trim()).toList();

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


  Future<Map<String, dynamic>> cancelLoanRequest(int bookId, int? notificationId, String? format) async {
    return await loanService.cancelLoan(bookId, notificationId, format);
  }

  // Método que comprueba si el usuario ya ha realizado una solicitud de préstamo para un libro
  Future<Map<String, dynamic>> checkExistingLoanRequest(int bookId, String userId) async {
    return await loanService.checkExistingLoanRequest(bookId, userId);
  }


  Future<List<Map<String, String>>> getLoanedFormatsAndStates(int bookId) async {
    return await loanService.getLoanedFormatsAndStates(bookId);
  }

  
  Future<Map<String, dynamic>> requestOfferPhysicalBookLoan(Book book) async {
      try {
        final DateTime startDate = DateTime.now();
        final DateTime endDate = startDate.add(const Duration(days: 30));

        final createLoanViewModel = CreateLoanViewModel(
          ownerId: book.ownerId,
          currentHolderId: book.ownerId,
          bookId: book.id,
          startDate: startDate.toIso8601String(),
          endDate: endDate.toIso8601String(),
          format: 'Físico',
          state: "Pendiente",
          currentPage: 0,
        );

        // Intentamos crear el préstamo
        final response = await loanService.createLoanOfferPhysicalBook(createLoanViewModel);
        print('requestOfferPhysicalBookLoan response: $response');

       return response;
    } catch (e) {
      print('Error en requestOfferPhysicalBookLoan: $e');
      return {'success': false, 'message': 'Error al realizar la solicitud de préstamo'};
    }
  }

  // Borra loan por libro y usuario (para los libros no seleccionados o si fue fianza)
  Future<void> deleteLoanByBookAndUser(int bookId, String userId) async {
    await loanService.deleteLoanByBookAndUser(bookId, userId);
  }

  Future<int?> acceptCompensationLoan({required int bookId, required String userId, required String? newHolderId, required String compensation}) async {
   return await loanService.acceptCompensationLoan(bookId: bookId, userId: userId, newHolderId: newHolderId, compensation: compensation);
  }

  Future<String> getLoanStateForUser(int loanId, String userId) async {
    return loanService.getLoanStateForUser(loanId, userId);
  }

  Future<int?> getActualLoanIdForUserAndBook(int loanId, String userId) async {
    return await loanService.getActualLoanIdForUserAndBook(loanId, userId);
  }

  Future<void> updateLoanStateByUser(int loanId, int compensationLoanId, String newState) async {
    String? userId = await AccountController().getCurrentUserId();
    await loanService.updateLoanStateByUser(userId, loanId, compensationLoanId, newState);
  }

  Future<Map<String, dynamic>> createLoanFianza(int bookId, String ownerId, String currentHolderId, String bookTitle) async {
      try {
        final DateTime startDate = DateTime.now();
        final DateTime endDate = startDate.add(const Duration(days: 30));

        final createLoanViewModel = CreateLoanViewModel(
          ownerId: ownerId,
          currentHolderId: currentHolderId,
          bookId: 0,
          startDate: startDate.toIso8601String(),
          endDate: endDate.toIso8601String(),
          format: 'Físico',
          state: "Aceptado",
          currentPage: 0
        );

        // Intentamos crear el préstamo
        final response = await loanService.createLoanFianza(createLoanViewModel, bookTitle);
        print('requestOfferPhysicalBookLoan response: $response');

       return response;
    } catch (e) {
      print('Error en requestOfferPhysicalBookLoan: $e');
      return {'success': false, 'message': 'Error al realizar la solicitud de préstamo'};
    }
  }

}
import 'package:booknest/controllers/account_controller.dart';
import 'package:booknest/controllers/base_controller.dart';
import 'package:booknest/controllers/book_controller.dart';
import 'package:booknest/controllers/chat_message_controller.dart';
import 'package:booknest/controllers/notification_controller.dart';
import 'package:booknest/controllers/reminder_controller.dart';
import 'package:booknest/entities/models/book_model.dart';
import 'package:booknest/entities/viewmodels/loan_view_model.dart';

// Controlador con los métodos de las acciones de Préstamos.
class LoanController extends BaseController{
  late NotificationController notificationController;
  late ReminderController reminderController;
  late AccountController accountController;
  late BookController bookController;
  late ChatMessageController chatMessageController;

  // Método asíncrono para solicitar el préstamo de un libro.
    Future<Map<String, dynamic>> requestLoan(Book book, String format, List<Book>? selectedBooks) async {
      try {
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

        // Creamos el préstamo
        final response = await loanService.createLoan(createLoanViewModel);

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

          // Creamos la notificación
          final notificationResponse = await notificationController.createNotification(
            ownerId,
            'Préstamo',
            loan['id'],
            notificationMessage
          );

          if (notificationResponse['success'] && notificationResponse['data'] != null) {
            notificationId = notificationResponse['data']['id']?.toString();
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
      print('Error en requestLoan: $e');
      return {'success': false, 'message': 'Error al realizar la solicitud de préstamo'};
    }
  }

  // Método que obtiene los libros que han sido prestados a un usuario.
  Future<List<Map<String, dynamic>>> getLoansByHolder(String userId) async {
    return await loanService.getLoansByHolder(userId);
  }

  // Método que obtiene las solicitudes de préstamos de un usuario.
  Future<List<Map<String, dynamic>>> getPendingLoansForUser(String userId) async {
    return await loanService.getUserPendingLoans(userId);
  }

  // Método que obtiene una solicitud de préstamo por su id.
  Future<Map<String, dynamic>> getLoanById(int loanId) async {
    return await loanService.getLoanById(loanId);
  }

  // Método para cambiar el estado de una solicitud de préstamo.
  Future<void> updateLoanState(int loanId, String newState, {String? compensation, int? compensationLoanId}) async {
    try {
      final loanResponse = await loanService.getLoanById(loanId);
      if (loanResponse == null || loanResponse['data'] == null) {
        print('Error: loanResponse es nulo o no contiene data');
        return;
      }
      final loanData = loanResponse['data'];
      if (loanData == null || loanData is! Map<String, dynamic>) {
        print('Error: loanData es nulo o no es un mapa válido');
        return;
      }
      final loan = loanData;

      final bookResponse = await bookService.getBookById(loan['bookId']);
      if (bookResponse == null || bookResponse['data'] == null) {
        print('Error: bookResponse es nulo o no contiene data');
        return;
      }
      final bookData = bookResponse['data'];
      if (bookData == null || bookData is! Map<String, dynamic>) {
        print('Error: No se encontró el libro con id ${loan['bookId']}');
        return;
      }

      final book = bookData;
      final bookName = book['title'];

      final userId = loan['currentHolderId'];
      if (userId == null) {
        print('Error: El id del usuario actual (currentHolderId) es nulo.');
        return;
      }

      await loanService.updateLoanState(loanId, newState);

      if (newState == 'Aceptado' && loan['format'].toString().toLowerCase().contains('físico')) {
        String compensationText = compensation != null ? '\nContraprestación acordada: $compensation.' : '';
        String message = 'Tu solicitud de préstamo para el libro "$bookName" en formato ${loan['format']} ha sido aceptada.$compensationText';

        await notificationController.createNotification(userId, 'Préstamo Aceptado', loanId, message);

        final ownerId = loan['ownerId'];
        final requesterId = loan['currentHolderId'];

        final ownerResponse = await userService.getUserById(ownerId);
        final ownerData = ownerResponse['data'];
        if (ownerData == null || ownerData is! Map<String, dynamic>) {
          print('Error: Usuario dueño no encontrado o datos inválidos');
          return;
        }

        final requesterResponse = await userService.getUserById(requesterId);
        final requesterData = requesterResponse['data'];
        if (requesterData == null || requesterData is! Map<String, dynamic>) {
          print('Error: Usuario solicitante no encontrado o datos inválidos');
          return;
        }

        print('ownerData: $ownerData');
        print('requesterData: $requesterData');

        final ownerName = ownerData['name'];
        final owneruserName = ownerData['userName'];
        final ownerEmail = ownerData['email'];

        final requesterName = requesterData['name'];
        final requesteruserName = requesterData['userName'];
        final requesterEmail = requesterData['email'];

        String chatMessageForOwner =
            'Ha iniciado un nuevo intercambio con el usuario $requesterName ($requesteruserName): $bookName a cambio de $compensation. Póngase en contacto para acordar la fecha, hora y lugar de la quedada. Correo electrónico: <a href="https://mail.google.com/mail/?view=cm&fs=1&to=$requesterEmail">$requesterEmail</a>';
        String chatMessageForRequester =
            'Ha iniciado un nuevo intercambio con el usuario $ownerName ($owneruserName): $bookName a cambio de $compensation. Póngase en contacto para acordar la fecha, hora y lugar de la quedada. Correo electrónico: <a href="https://mail.google.com/mail/?view=cm&fs=1&to=$ownerEmail">$ownerEmail</a>';

        final chatId = await loanChatService.createChatIfNotExists(loan['id'], ownerId, requesterId, compensationLoanId);

        await chatMessageController.createChatMessage(ownerId, chatId, chatMessageForOwner);
        await chatMessageController.createChatMessage(requesterId, chatId, chatMessageForRequester);

        await loanService.updateCompensation(compensation, loan['id']);
      } else if (newState == 'Aceptado') {
        String message = 'Tu solicitud de préstamo para el libro "$bookName" en formato ${loan['format']} ha sido aceptada.';
        await notificationController.createNotification(userId, 'Préstamo Aceptado', loanId, message);
      }

      final ownerId = loan['ownerId'];

      if (newState.trim().toLowerCase() == 'devuelto') {
        String message = 'Tu libro "$bookName" en formato ${loan['format']} ha sido devuelto.';
        await notificationController.createNotification(ownerId, 'Préstamo Devuelto', loanId, message);

        final format = loan['format'] as String;
        final bookId = loan['bookId'] as int;

        final allReminders = await reminderController.getRemindersByBook(bookId);

        final usersToNotify = allReminders
            .where((r) => r.format.trim().toLowerCase() == format.trim().toLowerCase() && !r.notified)
            .map((r) => r.userId)
            .toSet()
            .toList();

        if (usersToNotify.isNotEmpty) {
          final String messageReminder = 'El libro "$bookName" en formato $format vuelve a estar disponible.';
          for (String userId in usersToNotify) {
            await notificationController.createNotification(userId, 'Recordatorio', bookId, messageReminder);
            await reminderController.markAsNotified(bookId, userId, format);

            final bookFormats = (book['format'] as String).split(',').map((f) => f.trim()).toList();
            final allAvailable = await loanService.areAllFormatsAvailable(bookId, bookFormats);

            if (allAvailable) {
              for (final f in bookFormats) {
                await reminderController.removeFromReminder(bookId, userId, f);
              }
            }
          }
        }
      }

      if (newState == 'Rechazado') {
        String message = 'Tu solicitud de préstamo para el libro "$bookName" en formato ${loan['format']} ha sido rechazada.';
        await notificationController.createNotification(userId, 'Préstamo Rechazado', loanId, message);
      }
    } catch (e) {
      print('Error al actualizar el estado del préstamo: $e');
    }
  }

  // Método que comprueba si todos los formatos de un libro están disponibles.
  Future<bool> areAllFormatsAvailable(int bookId) async {
    final bookResponse = await bookService.getBookById(bookId);
    if (bookResponse == null || bookResponse['data'] == null) {
      print('Error: No se encontró el libro');
      return false;
    }

    final formatString = bookResponse['data']['format'] as String;
    final formats = formatString.split(',').map((f) => f.trim().toLowerCase()).toList();

    for (var format in formats) {
      final hasActiveLoan = await loanService.getActiveLoanForBookAndFormat(bookId, format);
      if (hasActiveLoan) {
        return false;
      }
    }

    return true;
  }

  // Método para notificar que un libro vuelve a estar disponible a aquellas personas con recordatorio activado.
  Future<void> handleBookReturnAndNotification(int bookId, String format) async {
    final usersIdForReminder = await reminderController.getUsersIdForReminder(bookId);
    final bookResponse = await bookService.getBookById(bookId);

    if (bookResponse == null || bookResponse['data'] == null) {
      print('Error: No se encontró el libro');
      return;
    }

    final bookName = bookResponse['data']['title'];

    // Enviar notificación a los usuarios con recordatorio
    for (String userId in usersIdForReminder) {
      String messageReminder = 'El libro "$bookName" en formato $format vuelve a estar disponible.';
      await notificationController.createNotification(userId, 'Recordatorio', bookId, messageReminder);
    }

    // Verificar si todos los formatos están disponibles
    bool allFormatsAvailable = await areAllFormatsAvailable(bookId);

    if (allFormatsAvailable) {
      // Si todos los formatos están disponibles, desactivar la campana
      await reminderController.updateReminderStateForAllUsers(bookId, false);
    }
  }

  // Método asíncrono para guardar la página actual por la que se está leyendo un libro
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

  // Método asíncrono para obtener los formatos disponibles de un libro.
  Future<List<String>> fetchAvailableFormats(int bookId, List<String> formats) async {
    try {
      final availableFormats = await loanService.getAvailableFormats(bookId, formats);
      return availableFormats;
    } catch (e) {
      print('Error en BookController.fetchAvailableFormats: $e');
      return [];
    }
  }

  // Método asíncrono para obtener los formatos de un libro que están en préstamo.
  Future<List<String>> fetchLoanedFormats(int bookId) async {
    try {
      return await loanService.getLoanedFormats(bookId);
    } catch (e) {
      print('Error en BookController.fetchLoanedFormats: $e');
      return [];
    }
  }

  // Método para obtener los formatos de un libro que están pendientes de préstamo.
  Future<List<String>> fetchPendingFormats(int bookId) async {
    try {
      return await loanService.getPendingFormats(bookId);
    } catch (e) {
      print('Error en BookController.fetchPendingFormats: $e');
      return [];
    }
  }
  
  // Método asíncrono que obtiene las solicitudes de préstamo de un libro por su id.
  Future<List<Map<String, dynamic>>> getLoansByBookId(int bookId) async {
    return await loanService.getLoansByBookId(bookId);
  }

  // Método asíncrono para eliminar una solicitud de préstamo sobre un libro.
  Future<Map<String, dynamic>> cancelLoanRequest(int bookId, int? notificationId, String? format) async {
    return await loanService.cancelLoan(bookId, notificationId, format);
  }

  // Método asíncrono que comprueba si el usuario ya ha realizado una solicitud de préstamo para un libro.
  Future<Map<String, dynamic>> checkExistingLoanRequest(int bookId, String userId) async {
    return await loanService.checkExistingLoanRequest(bookId, userId);
  }

  // Método asíncrono que obtiene los formatos de un libro que están en préstamo y su estado.
  Future<List<Map<String, String>>> getLoanedFormatsAndStates(int bookId) async {
    return await loanService.getLoanedFormatsAndStates(bookId);
  }

  // Método asíncrono para ofrecer libros como contraprestación en un intercambio físico.
  Future<Map<String, dynamic>> requestOfferPhysicalBookLoan(Book book, int principalLoanId) async {
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

        // Creamos la solicitud de préstamo
        final response = await loanService.createLoanOfferPhysicalBook(createLoanViewModel, principalLoanId);
        print('requestOfferPhysicalBookLoan response: $response');

       return response;
    } catch (e) {
      print('Error en requestOfferPhysicalBookLoan: $e');
      return {'success': false, 'message': 'Error al realizar la solicitud de préstamo'};
    }
  }

  // Método asíncrono para borrar una solicitud de préstamo por libro y usuario (para los libros no seleccionados o si fue fianza).
  Future<void> deleteLoanByBookAndUser(int bookId, String userId) async {
    await loanService.deleteLoanByBookAndUser(bookId, userId);
  }

  // Método asíncrono para aceptar una de las compensaciones ofrecidas en un intercambio físico.
  Future<int?> acceptCompensationLoan({required int bookId, required String userId, required String? newHolderId, required String compensation}) async {
   return await loanService.acceptCompensationLoan(bookId: bookId, userId: userId, newHolderId: newHolderId, compensation: compensation);
  }

  // Método asíncrono para obtener el estado de una solicitud de préstamo de un usuario.
  Future<String> getLoanStateForUser(int loanId, String userId) async {
    return loanService.getLoanStateForUser(loanId, userId);
  }

  // Método asíncrono para obtener el id de la solicitud de préstamo de un usuario.
  Future<int?> getActualLoanIdForUserAndBook(int loanId, String userId) async {
    return await loanService.getActualLoanIdForUserAndBook(loanId, userId);
  }

  // Método asíncrono para actualizar el estado de una solicitud de préstamo.
  Future<void> updateLoanStateByUser(int loanId, int compensationLoanId, String newState) async {
    String? userId = await accountController.getCurrentUserId();

    // Marcamos el libro como devuelto
    await loanService.updateLoanStateByUser(userId, loanId, compensationLoanId, newState);

    final loan = await loanService.getLoanById(loanId);
    final compensationLoan = await loanService.getLoanById(compensationLoanId);

    if(loan['data']['ownerId'] == userId){
      final response = await bookService.getBookById(loan['data']['bookId']);

    final ownerId = loan['data']['ownerId'];
      // Si el préstamo ha sido devuelto, se notifica al propietario del libro
      if (newState.trim().toLowerCase() == 'devuelto') {
        String message = 'Tu libro "${response['data']['title']}" en formato ${loan['data']['format']} ha sido devuelto.';
        await notificationController.createNotification(ownerId, 'Préstamo Devuelto', loanId, message);

        final format = loan['data']['format'] as String;
        final bookId = loan['data']['bookId'] as int;

        // Obtener todos los recordatorios del libro
        final allReminders = await reminderController.getRemindersByBook(bookId);

        // Filtrar solo los que coinciden con el formato y no han sido notificados
        final usersToNotify = allReminders.where((r) => r.format.trim().toLowerCase() == format.trim().toLowerCase() && !r.notified).map((r) => r.userId).toSet().toList();

        if (usersToNotify.isNotEmpty) {
          final String messageReminder = 'El libro "${response['data']['title']}" en formato $format vuelve a estar disponible.';
          for (String userId in usersToNotify) {
            await notificationController.createNotification(userId, 'Recordatorio', bookId, messageReminder);

            // Marcar como notificado
            await reminderController.markAsNotified(bookId, userId, format);

            // Verificar si TODOS los formatos ya están disponibles
            final bookFormats = (loan['data']['format'] as String).split(',').map((f) => f.trim()).toList();

            final allAvailable = await loanService.areAllFormatsAvailable(bookId, bookFormats);

            if (allAvailable) {
              // Eliminar todos los recordatorios del usuario para ese libro
              for (final f in bookFormats) {
                await reminderController.removeFromReminder(bookId, userId, f);
              }
            }
          }
        }
      }
        final userid = loan['currentHolderId'];
        // Si el préstamo ha sido rechazado, se notifica al usuario que ha solicitado el libro
        if (newState == 'Rechazado') {
          String message = 'Tu solicitud de préstamo para el libro"${response['data']['title']}" en formato ${loan['data']['format']} ha sido rechazada.';
          await notificationController.createNotification(userid, 'Préstamo Rechazado', compensationLoanId, message);

          // Marcar el libro como disponible
          await bookController.changeState(response['data']['id'], 'Disponible');
        }
    }else if(compensationLoan['data']['ownerId'] == userId){
      final response = await bookService.getBookById(compensationLoan['data']['bookId']);

      final ownerId = compensationLoan['data']['ownerId'];
        // Si el préstamo ha sido devuelto, se notifica al propietario del libro
        if (newState.trim().toLowerCase() == 'devuelto') {
          String message = 'Tu libro "${response['data']['title']}" en formato ${compensationLoan['data']['format']} ha sido devuelto.';
          await notificationController.createNotification(ownerId, 'Préstamo Devuelto', compensationLoanId, message);

          final format = compensationLoan['data']['format'] as String;
          final bookId = compensationLoan['data']['bookId'] as int;

          // Obtener todos los recordatorios del libro
          final allReminders = await reminderController.getRemindersByBook(bookId);

          // Filtrar solo los que coinciden con el formato y no han sido notificados
          final usersToNotify = allReminders.where((r) => r.format.trim().toLowerCase() == format.trim().toLowerCase() && !r.notified).map((r) => r.userId).toSet().toList();

          if (usersToNotify.isNotEmpty) {
            final String messageReminder = 'El libro "${response['data']['title']}" en formato $format vuelve a estar disponible.';
            for (String userId in usersToNotify) {
              await notificationController.createNotification(userId, 'Recordatorio', bookId, messageReminder);

              // Marcar como notificado
              await reminderController.markAsNotified(bookId, userId, format);

              // Verificar si TODOS los formatos ya están disponibles
              final bookFormats = (compensationLoan['data']['format'] as String).split(',').map((f) => f.trim()).toList();

              final allAvailable = await loanService.areAllFormatsAvailable(bookId, bookFormats);

              if (allAvailable) {
                // Eliminar todos los recordatorios del usuario para ese libro
                for (final f in bookFormats) {
                  await reminderController.removeFromReminder(bookId, userId, f);
                }
              }
            }
          }
        }
        final userid = compensationLoan['currentHolderId'];
        // Si el préstamo ha sido rechazado, se notifica al usuario que ha solicitado el libro
        if (newState == 'Rechazado') {
          String message = 'Tu solicitud de préstamo para el libro"${response['data']['title']}" en formato ${compensationLoan['data']['format']} ha sido rechazada.';
          await notificationController.createNotification(userid, 'Préstamo Rechazado', compensationLoanId, message);

          // Marcar el libro como disponible
          await bookController.changeState(response['data']['id'], 'Disponible');
        }
      } 
  }

  // Método asíncrono para la creación de una solicitud de préstamo cuando la contraprestación elegida ha sido Fianza.
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

        // Creamos la solicitud de préstamo
        final response = await loanService.createLoanFianza(createLoanViewModel, bookTitle);
        print('requestOfferPhysicalBookLoan response: $response');

       return response;
    } catch (e) {
      print('Error en requestOfferPhysicalBookLoan: $e');
      return {'success': false, 'message': 'Error al realizar la solicitud de préstamo'};
    }
  }

}
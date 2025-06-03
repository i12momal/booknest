import 'package:booknest/controllers/base_controller.dart';
import 'package:booknest/entities/models/reminder_model.dart';
import 'package:booknest/entities/viewmodels/reminder_view_model.dart';

// Controlador con los métodos de las acciones de Recordatorios.
class ReminderController extends BaseController{

  // Método asíncrono para obtener los recordatorios de un usuario sobre un libro.
  Future<List<Reminder>> getRemindersByBookAndUser(int bookId, String userId) async {
    return await reminderService.getRemindersByBookAndUser(bookId, userId);
  }

  // Método asíncrono para obtener los recordatorios de un libro.
  Future<List<Reminder>> getRemindersByBook(int bookId) async {
    return await reminderService.getRemindersByBook(bookId);
  }

  // Método asíncrono para obtener los ids de los usuarios que tienen activado un recordatorio para un libro.
  Future<List<String>> getUsersIdForReminder(int bookId) async {
    return await reminderService.getUsersIdForReminder(bookId);
  }

  // Método asíncrono para agregar un recordatorio.
  Future<Map<String, dynamic>> addReminder(int bookId, String userId, String format) async {
    try {
      final reminderData = CreateReminderViewModel(userId: userId, bookId: bookId, format:format);

      // Llamamos al servicio para agregar un recordatorio para el libro
      await reminderService.addReminder(reminderData);

      return {'success': true, 'message': 'Libro agregado a recordatorio'};
    } catch (error) {
      return {'success': false, 'message': 'Error al agregar a recordatorio: $error'};
    }
  }

  // Método asíncrono para eliminar un libro de favoritos.
  Future<Map<String, dynamic>> removeFromReminder(int bookId, String userId, String format) async {
    try {
      // Llamamos al servicio para eliminar el libro de recordatorio
      await reminderService.removeFromReminder(bookId, userId, format);
      return {'success': true, 'message': 'Libro eliminado de recordatorio'};
    } catch (error) {
      return {'success': false, 'message': 'Error al eliminar de recordatorio: $error'};
    }
  }

  // Método asíncrono para confirmar que un recordatorio ha sido notificado.
  Future<void> markAsNotified(int bookId, String userId, String format) async {
  await reminderService.markAsNotified(bookId, userId, format);
  }

  // Método asíncrono para actualizar el estado de un recordatorio para los usuarios que lo tuviesen activado para un libro determinado.
  Future<void> updateReminderStateForAllUsers(int bookId, bool notified) async {
    final reminders = await reminderService.getRemindersByBook(bookId);
    for (var reminder in reminders) {
      if (!reminder.notified) {
        await reminderService.updateReminderNotificationStatus(reminder.id, notified);
      }
    }
  }

}
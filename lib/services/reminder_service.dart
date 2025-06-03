import 'package:booknest/entities/models/reminder_model.dart';
import 'package:booknest/entities/viewmodels/reminder_view_model.dart';
import 'package:booknest/services/base_service.dart';

// Servicio con los métodos de negocio para la entidad Recordatorio.
class ReminderService extends BaseService{

  // Método asíncrono para obtener los ids de los usuarios que activaron un recordatorio para un libro
  Future<List<Reminder>> getRemindersByBookAndUser(int bookId, String userId) async {
    try {
      final response = await BaseService.client
          .from('Reminder')
          .select()
          .eq('bookId', bookId)
          .eq('userId', userId);

      if (response == null || response.isEmpty) {
        return [];
      }

      return response.map<Reminder>((item) => Reminder.fromJson(item)).toList();
    } catch (e) {
      print('Error al obtener recordatorios: $e');
      return [];
    }
  }

  // Método asíncrono para obtener los recordatorios activos sobre un libro.
  Future<List<Reminder>> getRemindersByBook(int bookId) async {
    try {
      final response = await BaseService.client.from('Reminder').select().eq('bookId', bookId);

      if (response == null || response.isEmpty) {
        return [];
      }

      return response.map<Reminder>((item) => Reminder.fromJson(item)).toList();
    } catch (e) {
      print('Error al obtener recordatorios: $e');
      return [];
    }
  }

  // Método asíncrono que obtiene el id de los usuarios que tienen un recordatorio activo para un libro.
  Future<List<String>> getUsersIdForReminder(int bookId) async {
    try {
      final response = await BaseService.client
          .from('Reminder')
          .select('userId') 
          .eq('bookId', bookId);

      if (response == null || response.isEmpty) {
        return [];
      }

      return response.map<String>((item) => item['userId'] as String).toList();
    } catch (e) {
      print('Error al obtener recordatorios: $e');
      return [];
    }
  }

  // Método asíncrono para agregar un recordatorio sobre un libro.
  Future<void> addReminder(CreateReminderViewModel createReminderViewModel) async {
    try {
      final currentUser = BaseService.client.auth.currentUser;
      if (currentUser == null) {
        print("Usuario no autenticado");
        return;
      }

      final Map<String, dynamic> reminderData = {
        'userId': createReminderViewModel.userId,
        'bookId': createReminderViewModel.bookId,
        'format': createReminderViewModel.format,
        'notified': false,
      };

      final updateResponse = await BaseService.client
          .from('Reminder')
          .insert(reminderData)
          .select();

      if (updateResponse != null) {
        print("Recordatorio agregado correctamente.");
      } else {
        print("Error al agregar recordatorio.");
      }
       
    } catch (error) {
      print("Error al agregar recordatorio: $error");
    }
  }

  // Método asíncrono para eliminar un recordatorio
  Future<void> removeFromReminder(int bookId, String userId, String format) async {
    try {
      await BaseService.client.from('Reminder').delete().eq('userId', userId).eq('bookId', bookId).eq('format', format);

    } catch (error) {
      print("Error al eliminar recordatorio: $error");
      throw Exception('Error al eliminar recordatorio: $error');
    }
  }

  // Método asíncrono para marcar un recordatorio como notificado
  Future<void> markAsNotified(int bookId, String userId, String format) async {
    try {
      await BaseService.client
      .from('Reminder')
      .update({'notified': true})
      .eq('bookId', bookId)
      .eq('userId', userId)
      .eq('format', format);

    } catch (error) {
      print("Error al marcar el recordatorio como notificado: $error");
      throw Exception('Error al marcar el recordatorio como notificado: $error');
    }
  }

  // Método asíncrono para actualizar el estado de un recordatorio cuando ha sido notificado
  Future<void> updateReminderNotificationStatus(int reminderId, bool notified) async {
    try {
      await BaseService.client.from('Reminder').update({'notified': notified}).eq('id', reminderId);
    } catch (e) {
      print('Error al actualizar el estado del recordatorio: $e');
    }
  }

}
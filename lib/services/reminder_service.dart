// Servicio con los métodos de negocio para la entidad Recordatorio.
import 'package:booknest/entities/viewmodels/reminder_view_model.dart';
import 'package:booknest/services/base_service.dart';

class ReminderService extends BaseService{

  // Obtener los ids de los usuarios que activaron un recordatorio para un libro
  Future<List<String>> getUsersIdForReminder(int bookId) async {
    try {
      if (BaseService.client == null) {
        print('Error: Supabase client no inicializado.');
        return [];
      }

      final response = await BaseService.client
          .from('Reminder')
          .select('userId')
          .eq('bookId', bookId);

      if (response == null || response.isEmpty) {
        print('No hay recordatorios para el libro con ID $bookId');
        return [];
      }

      // Extraer solo los userId de la respuesta
      return response.map<String>((item) => item['userId'] as String).toList();
    } catch (e) {
      print('Error al obtener usuarios del recordatorio: $e');
      return [];
    }
  }

  // Agregar un libro a recordatorio
  Future<void> addReminder(CreateReminderViewModel createReminderViewModel) async {
    try {
      final currentUser = BaseService.client.auth.currentUser;
      if (currentUser == null) {
        print("Usuario no autenticado");
        return;
      }

      final Map<String, dynamic> reminderData = {
        'userId': createReminderViewModel.userId,
        'bookId': createReminderViewModel.bookId
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



  // Eliminar un recordatorio
  Future<void> removeFromReminder(int bookId, String userId) async {
    try {

      await BaseService.client
          .from('Reminder')
          .delete()
          .eq('userId', userId).eq('bookId', bookId);

    } catch (error) {
      print("Error al eliminar recordatorio: $error");
      throw Exception('Error al eliminar recordatorio: $error');
    }
  }


}
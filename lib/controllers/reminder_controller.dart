// Controlador con los métodos de las acciones de Préstamos.
import 'package:booknest/controllers/base_controller.dart';
import 'package:booknest/entities/viewmodels/reminder_view_model.dart';

// Controlador con los métodos de las acciones de Préstamos.
class ReminderController extends BaseController{

  // Obtener los ids de los usuarios que activaron un recordatorio para un libro
  Future<List<String>> getUsersIdForReminder(int bookId) async {
    return await reminderService.getUsersIdForReminder(bookId);
  }

  // Método para agregar un recordatorio
  Future<Map<String, dynamic>> addReminder(int bookId, String userId) async {
    try {
      // Crear un objeto de recordatorio que contenga los detalles necesarios
      final reminderData = CreateReminderViewModel(userId: userId, bookId: bookId);

      // Llamamos al servicio para agregar un recordatorio para el libro
      await reminderService.addReminder(reminderData);

      return {'success': true, 'message': 'Libro agregado a recordatorio'};
    } catch (error) {
      return {'success': false, 'message': 'Error al agregar a recordatorio: $error'};
    }
  }

  // Método para eliminar de favoritos
  Future<Map<String, dynamic>> removeFromReminder(int bookId, String userId) async {
    try {
      // Llamamos al servicio para eliminar el libro de recordatorio
      await reminderService.removeFromReminder(bookId, userId);
      return {'success': true, 'message': 'Libro eliminado de recordatorio'};
    } catch (error) {
      return {'success': false, 'message': 'Error al eliminar de recordatorio: $error'};
    }
  }

}
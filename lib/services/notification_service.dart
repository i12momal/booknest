// Servicio con los métodos de negocio para la entidad Notificación.
import 'package:booknest/entities/viewmodels/notification_view_model.dart';
import 'package:booknest/services/base_service.dart';

class NotificationService extends BaseService{

  // Marcar una notificación como leída
  Future<void> markNotificationAsRead(int notificationId) async {
    try {
      if (BaseService.client == null) {
        return;
      }

      final response = await BaseService.client
          .from('Notifications')
          .update({'read': true})
          .eq('id', notificationId).select();

      if (response == null || response.isEmpty) {
        print('No se pudo actualizar la notificación');
      }
    } catch (e) {
      print('Error al marcar la notificación como leída: $e');
    }
  }

  // Crear una nueva notificación
  Future<Map<String, dynamic>> createNotification(CreateNotificationViewModel createNotificationViewModel) async {
    try {
      if (BaseService.client == null) {
        return {'success': false, 'message': 'Error de conexión a la base de datos.'};
      }

      final user = BaseService.client.auth.currentUser;

      if (user == null) {
        print("El usuario no está autenticado.");
        return {'success': false, 'message': 'El usuario no está autenticado.'};
      }

      // Crear el registro en la tabla Book 
      print("Creando registro en la tabla Notification...");
      final Map<String, dynamic> notificationData = {
        'userId': createNotificationViewModel.userId,
        'type': createNotificationViewModel.type,
        'relatedId': createNotificationViewModel.relatedId,
        'message': createNotificationViewModel.message,
        'read': createNotificationViewModel.read
      };
      print("Datos a insertar: $notificationData");

      final response = await BaseService.client.from('Notifications').insert(notificationData).select().single();

      print("Respuesta de la inserción en Notification: $response");

      if (response != null) {
        print("Notificación registrada exitosamente");

        return {
          'success': true,
          'message': 'Notificación registrada exitosamente',
          'data': response
        };
      } else {
        print("Error: No se pudo crear el registro en la tabla Notification");
        return {'success': false, 'message': 'Error al registrar la notificación'};
      }
    } catch (ex) {
      print("Error en createNotification: $ex");
      return {'success': false, 'message': ex.toString()};
    }
  }

  // Obtener las notificaciones de un usuario
  Future<List<Map<String, dynamic>>> getNotifications(String userId) async {
    try {
      if (BaseService.client == null) {
        return [];
      }

      final response = await BaseService.client
          .from('Notifications')
          .select()
          .eq('userId', userId).order('created_at', ascending: false);

      print("Notificaciones del usuario: $response ");

      return response;
    } catch (e) {
      print('Error al obtener las notificaciones del usuario: $e');
      return [];
    }
  }

  // Obtener las notificaciones no leídas de un usuario
  Future<List<Map<String, dynamic>>> getUnreadNotifications(String userId) async {
    try {
      if (BaseService.client == null) {
        return [];
      }

      final response = await BaseService.client
          .from('Notifications')
          .select()
          .eq('userId', userId)
          .eq('read', 'FALSE');

      print("Notificaciones no leídas del usuario: $response ");

      return response;
    } catch (e) {
      print('Error al obtener las notificaciones no leídas del usuario: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> deleteNotification(int notificationId) async {
    try {
      
      final notificationResponse = await BaseService.client
          .from('Notifications')
          .delete()
          .eq('id', notificationId)
          .select();

      if (notificationResponse.isNotEmpty) {
        return {'success': true};
      } else {
        return {
          'success': false,
          'message': 'Notificación no encontrada o no se pudo eliminar'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error al eliminar la notificación'};
    }
  }


   Future<List<Map<String, dynamic>>> getNotificationsByLoanId (int loanId) async {
    try {
      if (BaseService.client == null) {
        return [];
      }

      final response = await BaseService.client
          .from('Notifications')
          .select()
          .eq('relatedId', loanId);

      print("Notificaciones del préstamo $loanId: $response ");

      return response;
    } catch (e) {
      print('Error al obtener las notificaciones del préstamo $loanId: $e');
      return [];
    }
  }
}
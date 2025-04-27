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
          .eq('userId', userId);

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

}
// Controlador con los métodos de las acciones de Notificaciones.
import 'package:booknest/controllers/base_controller.dart';
import 'package:booknest/entities/viewmodels/notification_view_model.dart';

class NotificationController extends BaseController{

  // Marcar una notificación como leída
  Future<void> markNotificationAsRead(int notificationId) async {
    await notificationService.markNotificationAsRead(notificationId);
  }

  // Crear una nueva notificación
  Future<Map<String, dynamic>> createNotification(String userId, String type, int relatedId, String message) async {
    // Creación del viewModel
    final addNotificationViewModel = CreateNotificationViewModel(
      userId: userId,
      type: type,
      relatedId: relatedId,
      message: message,
      read: false
    );

    // Verificar el contenido del viewModel
    print("Creando notificación con los siguientes datos:");
    print("userId: $userId, type: $type, relatedId: $relatedId, message: $message");
    
    // Llamada al servicio para registrar al usuario
    return await notificationService.createNotification(addNotificationViewModel);
  }

  // Obtener las notificaciones del usuario
  Future<List<Map<String, dynamic>>> getUserNotifications(String userId) async {
    return await notificationService.getNotifications(userId);
  }

  // Obtener las notificaciones no leídas del usuario
  Future<List<Map<String, dynamic>>> getUnreadUserNotifications(String userId) async {
    return await notificationService.getUnreadNotifications(userId);
  }


   Future<Map<String, dynamic>> deleteNotification(int notificationId) async {
    return await notificationService.deleteNotification(notificationId);
  }

  Future<List<Map<String, dynamic>>> getNotificationsByLoanId(int loanId) async {
    return await notificationService.getNotificationsByLoanId(loanId);
  }

}
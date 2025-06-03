import 'package:booknest/controllers/base_controller.dart';
import 'package:booknest/entities/viewmodels/notification_view_model.dart';

// Controlador con los métodos de las acciones de Notificaciones.
class NotificationController extends BaseController{

  // Método asíncrono para marcar una notificación como leída.
  Future<void> markNotificationAsRead(int notificationId) async {
    await notificationService.markNotificationAsRead(notificationId);
  }

  // Método asíncrono para crear una nueva notificación.
  Future<Map<String, dynamic>> createNotification(String userId, String type, int relatedId, String message) async {
    // Creación del viewModel
    final addNotificationViewModel = CreateNotificationViewModel(
      userId: userId,
      type: type,
      relatedId: relatedId,
      message: message,
      read: false
    );
    
    // Llamada al servicio para registrar al usuario
    return await notificationService.createNotification(addNotificationViewModel);
  }

  // Método asíncrono para obtener las notificaciones del usuario
  Future<List<Map<String, dynamic>>> getUserNotifications(String userId) async {
    return await notificationService.getNotifications(userId);
  }

  // Método asíncrono para obtener las notificaciones no leídas del usuario
  Future<List<Map<String, dynamic>>> getUnreadUserNotifications(String userId) async {
    return await notificationService.getUnreadNotifications(userId);
  }

  // Método asíncrono para borrar una notificación.
  Future<Map<String, dynamic>> deleteNotification(int notificationId) async {
  return await notificationService.deleteNotification(notificationId);
  }

  // Método asíncrono para obtener las notificaciones asociadas a una solicitud de préstamo.
  Future<List<Map<String, dynamic>>> getNotificationsByLoanId(int loanId) async {
    return await notificationService.getNotificationsByLoanId(loanId);
  }

}
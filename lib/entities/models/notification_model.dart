// Define la entidad Notificación en el modelo de datos.
class Notification {
  final int id;
  final String userId;
  final String type;
  final int relatedId;
  final String message;
  final bool read;

  Notification({
    required this.id,
    required this.userId,
    required this.type,
    required this.relatedId,
    required this.message,
    required this.read,
  });

  // Convertir un JSON a Notification
  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'],
      userId: json['userId'],
      type: json['type'],
      relatedId: json['relatedId'],
      message: json['message'],
      read: json['read'] ?? false,
    );
  }

}

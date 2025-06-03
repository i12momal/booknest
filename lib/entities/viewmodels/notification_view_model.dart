// Modelo de vista del formulario de creación
class CreateNotificationViewModel {
  final String userId;
  final String type;
  final int relatedId;
  final String message;
  final bool read;

  CreateNotificationViewModel({
    required this.userId,
    required this.type,
    required this.relatedId,
    required this.message,
    required this.read,
  });
}


// Modelo de vista del formulario de edición
class EditNotificationViewModel {
  final String userId;
  final String type;
  final int relatedId;
  final String message;
  final bool read;

  EditNotificationViewModel({
    required this.userId,
    required this.type,
    required this.relatedId,
    required this.message,
    required this.read,
  });
}
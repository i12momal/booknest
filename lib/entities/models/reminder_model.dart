// Define la entidad Recordatorio en el modelo de datos.
class Reminder{
  final int id;
  final String userId;
  final int bookId;

  Reminder({
    required this.id,
    required this.userId,
    required this.bookId
  });

    factory Reminder.fromJson(Map<String, dynamic> json) {
      return Reminder(
        id: json['id'],
        userId: json['userId'] ?? '',
        bookId: json['bookId'] ?? 0
      );
    }
}
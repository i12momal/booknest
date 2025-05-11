// Define la entidad Recordatorio en el modelo de datos.
class Reminder{
  final int id;
  final String userId;
  final int bookId;
  final String format;
  final bool notified;

  Reminder({
    required this.id,
    required this.userId,
    required this.bookId,
    required this.format,
    required this.notified,
  });

    factory Reminder.fromJson(Map<String, dynamic> json) {
      return Reminder(
        id: json['id'],
        userId: json['userId'] ?? '',
        bookId: json['bookId'] ?? 0,
        format: json['format'] ?? '',
        notified: json['notified'] ?? false,
      );
    }
}
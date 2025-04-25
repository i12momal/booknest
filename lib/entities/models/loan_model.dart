// Define la entidad Préstamo en el modelo de datos.
class Loan{
  final int id;
  final String ownerId;
  final String currentHolderId;
  final int bookId;
  final String startDate;
  final String endDate;
  final String format;
  final String state;

  Loan({
    required this.id,
    required this.ownerId,
    required this.currentHolderId,
    required this.bookId,
    required this.startDate,
    required this.endDate,
    required this.format,
    required this.state
  });

    factory Loan.fromJson(Map<String, dynamic> json) {
      return Loan(
        id: json['id'],
        ownerId: json['ownerId'] ?? '',
        currentHolderId: json['currentHolderId'] ?? '',
        bookId: json['bookId'] ?? 0,
        startDate: json['startDate'] ?? '',
        endDate: json['endDate'] ?? '',
        format: json['format'] ?? '',
        state: json['state'] ?? '',
      );
    }
}
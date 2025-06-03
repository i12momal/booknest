// Define la entidad Reseña en el modelo de datos.
class Review{
  final int id;
  final String comment;
  final int rating;
  final String userId;
  final int bookId;

  Review({
    required this.id,
    required this.comment,
    required this.rating,
    required this.userId,
    required this.bookId,
  });

    factory Review.fromJson(Map<String, dynamic> json) {
      return Review(
        id: json['id'],
        comment: json['comment'] ?? '',
        rating: json['rating'] ?? 0,
        userId: json['userId'] ?? '',
        bookId: json['bookId'] ?? 0,
      );
    }
}
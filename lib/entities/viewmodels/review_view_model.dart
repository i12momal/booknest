// Modelo de vista del formulario de creación
class CreateReviewViewModel{
  final String comment;
  final int rating;
  final String userId;
  final int bookId;

  CreateReviewViewModel({
    required this.comment,
    required this.rating,
    required this.userId,
    required this.bookId,
  });
}


// Modelo de vista del formulario de edición
class EditReviewViewModel{
  final int id;
  final String comment;
  final int rating;

  EditReviewViewModel({
    required this.id,
    required this.comment,
    required this.rating
  });
}
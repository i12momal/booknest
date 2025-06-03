// Modelo de vista del formulario de creación
class CreateBookViewModel{
  final String title;
  final String author;
  final String isbn;
  final int pagesNumber;
  final String language;
  final String format;
  final String file;
  final String? cover;
  final String summary;
  final String categories;
  final String state;
  final String ownerId;

  CreateBookViewModel({
    required this.title,
    required this.author,
    required this.isbn,
    required this.pagesNumber,
    required this.language,
    required this.format,
    required this.file,
    required this.cover,
    required this.summary,
    required this.categories,
    required this.state,
    required this.ownerId,
  });
}


// Modelo de vista del formulario de edición
class EditBookViewModel{
  final int id;
  final String title;
  final String author;
  final String isbn;
  final int pagesNumber;
  final String language;
  final String format;
  final String? file;
  final String? cover;
  final String summary;
  final String categories;
  final String state;
  final String ownerId;

  EditBookViewModel({
    required this.id,
    required this.title,
    required this.author,
    required this.isbn,
    required this.pagesNumber,
    required this.language,
    required this.format,
    required this.file,
    required this.cover,
    required this.summary,
    required this.categories,
    required this.state,
    required this.ownerId,
  });
}
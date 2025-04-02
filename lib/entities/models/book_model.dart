// Define la entidad Libro en el modelo de datos.
class Book{
  final int id;
  final String title;
  final String author;
  final String isbn;
  final int pagesNumber;
  final String language;
  final String format;
  final String file;
  final String summary;
  final String categories;
  final String state;
  final String ownerId;
  final String currentHolderId;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.isbn,
    required this.pagesNumber,
    required this.language,
    required this.format,
    required this.file,
    required this.summary,
    required this.categories,
    required this.state,
    required this.ownerId,
    required this.currentHolderId,
  });
}
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
  final String cover;
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
    required this.cover,
    required this.summary,
    required this.categories,
    required this.state,
    required this.ownerId,
    required this.currentHolderId,
  });

    factory Book.fromJson(Map<String, dynamic> json) {
      // Directamente asignamos los valores de 'format' y 'categories' como String
      return Book(
        id: json['id'],
        title: json['title'] ?? '',
        author: json['author'] ?? '',
        isbn: json['isbn'] ?? '',
        pagesNumber: json['pagesNumber'] ?? 0,
        language: json['language'] ?? '',
        format: json['format'] ?? '',  // Aseguramos que sea un String
        file: json['file'] ?? '',
        cover: json['cover'] ?? '',
        summary: json['summary'] ?? '',
        categories: json['categories'] ?? '',  // Aseguramos que sea un String
        state: json['state'] ?? '',
        ownerId: json['owner_id'] ?? '',
        currentHolderId: json['currentHolderId'] ?? '',
      );
    }
}
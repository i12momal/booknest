import 'dart:io';
import 'package:booknest/controllers/base_controller.dart';
import 'package:booknest/entities/models/book_model.dart';
import 'package:booknest/entities/viewmodels/book_view_model.dart';

// Controlador con los métodos de las acciones de Libros.
class BookController extends BaseController{
  bool isUploading = false;
  String? uploadedFileName;

  /* Método asíncrono que permite añadir un nuevo libro.
    Parámetros:
      - title: Cadena con el tútlo del libro.
      - author: Cadena con el nombre del autor.
      - isbn: Cadena con el isbn del libro.
      - pagesNumber: Entero con el número de páginas del libro.
      - language: Cadena con el idioma del libro.
      - format: Cadena con el formato del libro.
      - file: Cadena con la ubicación del archivo del libro.
      - summary: Cadena con un breve resumen del libro.
      - categories: Cadena con los géneros seleccionados.
    Return: 
      Mapa con la clave:
        - success: Indica si la creación del libro fue exitosa (true o false).
        - message: Proporciona un mensaje de estado.
        - data (Opcional): Información del libro creado si la operación fue exitosa.
  */
  Future<Map<String, dynamic>> addBook(String title, String author, String isbn, int pagesNumber,
    String language, String format, File? file, String summary, String categories, File? coverImage) async {

    String? fileUrl = '';
    String? coverImageUrl = '';

    // Obtener el ID del usuario
    final userId = await accountService.getCurrentUserId();
    if (userId == null) {
      return {'success': false, 'message': 'Usuario no autenticado'};
    }

    // Si el usuario sube un archivo, la guardamos en Supabase
    if (file != null) {
      fileUrl = await bookService.uploadFile(file, title, userId);
      if (fileUrl == null) {
        return {'success': false, 'message': 'Error al subir el archivo'};
      }
    }

    // Si el usuario sube una portada, la guardamos también
    if (coverImage != null) {
      coverImageUrl = await bookService.uploadCover(coverImage, title, userId);
      if (coverImageUrl == null) {
        return {'success': false, 'message': 'Error al subir la portada'};
      }
    }

    // Creación del viewModel
    final addBookViewModel = CreateBookViewModel(
      title: title,
      author: author,
      isbn: isbn,
      pagesNumber: pagesNumber,
      language: language,
      format: format,
      file: fileUrl,
      cover: coverImageUrl,
      summary: summary,
      categories: categories,
      state: "Disponible",
      ownerId: userId
    );
    
    // Llamada al servicio para registrar al usuario
    return await bookService.addBook(addBookViewModel);
  }

  /* Método asíncrono que permite editar un libro.
    Parámetros:
      - title: Cadena con el tútlo del libro.
      - author: Cadena con el nombre del autor.
      - isbn: Cadena con el isbn del libro.
      - pagesNumber: Entero con el número de páginas del libro.
      - language: Cadena con el idioma del libro.
      - format: Cadena con el formato del libro.
      - file: Cadena con la ubicación del archivo del libro.
      - summary: Cadena con un breve resumen del libro.
      - categories: Cadena con los géneros seleccionados.
    Return: 
      Mapa con la clave:
        - success: Indica si la edición del libro fue exitosa (true o false).
        - message: Proporciona un mensaje de estado.
        - data (Opcional): Información del libro editado si la operación fue exitosa.
  */
  Future<Map<String, dynamic>> editBook(int id, String title, String author, String isbn, int pagesNumber, String language, String format, File? file, String summary,
    String genres, String state, String ownerId, File? coverImage) async {
    String? imageUrl;
    String? coverUrl;

    // Obtener la URL del archivo actual del libro
    final currentBook = await bookService.getBookById(id);

    String? currentImageUrl;
    String? currentCoverImageUrl;

    if (currentBook['success'] && currentBook['data'] != null) {
      currentImageUrl = currentBook['data']['file'];
      currentCoverImageUrl = currentBook['data']['cover'];
      print("URL del archivo actual: $currentImageUrl");
      print("URL de la portada actual: $currentCoverImageUrl");
    } else {
      print("Error al obtener el libro o archivo actual.");
    }

    // Reglas para archivo según formato
    bool soloFisico = format.toLowerCase().trim() == 'físico';

    if (soloFisico) {
      if (currentImageUrl != null) {
        print("Solo 'Físico' seleccionado. Eliminando archivo...");
        await bookService.deleteFile(currentImageUrl);
      }
      imageUrl = null;
    } else if (file != null && file.path.startsWith('/')) {
      try {
        if (currentImageUrl != null) {
          print("Reemplazando archivo anterior...");
          await bookService.deleteFile(currentImageUrl);
        }

        imageUrl = await bookService.uploadFile(file, title, ownerId);

        if (imageUrl == null) {
          print("Error al subir el archivo. La URL es nula.");
          return {
            'success': false,
            'message': 'Error al subir el archivo. Por favor, intente nuevamente.'
          };
        }

        print("Archivo nuevo subido: $imageUrl");
      } catch (e) {
        print("Error al procesar el archivo: $e");
        return {
          'success': false,
          'message': 'Error al procesar el archivo. Por favor, intente nuevamente.'
        };
      }
    } else {
      imageUrl = currentImageUrl;
    }

    // Subir la nueva portada si es necesario
    if (coverImage != null && coverImage.path.startsWith('/')) {
      try {
        if (currentCoverImageUrl != null) {
          print("Eliminando portada anterior...");
          await bookService.deleteFile(currentCoverImageUrl);
        }

        coverUrl = await bookService.uploadCover(coverImage, title, ownerId);

        if (coverUrl == null) {
          print("Error al subir la portada. La URL es nula.");
          return {
            'success': false,
            'message': 'Error al subir la portada. Por favor, intente nuevamente.'
          };
        }

        print("Nueva URL de la portada: $coverUrl");
      } catch (e) {
        print("Error al procesar la portada: $e");
        return {
          'success': false,
          'message': 'Error al procesar la portada. Por favor, intente nuevamente.'
        };
      }
    } else {
      coverUrl = currentCoverImageUrl ?? '';
    }

    // Crear viewModel con los datos editados
    final editBookViewModel = EditBookViewModel(
      id: id,
      title: title,
      author: author,
      isbn: isbn,
      pagesNumber: pagesNumber,
      language: language,
      format: format,
      categories: genres,
      file: imageUrl,
      cover: coverUrl,
      summary: summary,
      state: state,
      ownerId: ownerId
    );

    // Llamar al servicio para actualizar el libro
    try {
      print("Llamando al servicio para editar el libro...");
      return await bookService.editBook(editBookViewModel);
    } catch (e) {
      print("Error al editar el libro: $e");
      return {
        'success': false,
        'message': 'Error al actualizar los datos del libro. Por favor, intente nuevamente.'
      };
    }
  }

  /* Método asíncrono que devuelve los datos de un libro. */
  Future<Book?> getBookById(int bookId) async {
    var response = await bookService.getBookById(bookId);

    // Depuración para ver qué contiene 'response'
    print("Respuesta de Supabase: $response");

    // Comprobar si 'response' tiene la estructura esperada
    if (response.containsKey('success') && response['success'] == true) {
      print("Éxito: Datos del libro obtenidos");

      if (response['data'] != null) {
        print("Datos del libro: ${response['data']}");  // Diagnóstico

        // Convertir la respuesta en un objeto Book
        var book = Book.fromJson(response['data']);
        print("Libro convertido: ${book.title}, ${book.categories}, ${book.format}");
        return book;
      } else {
        print("Datos del libro son null");  // Diagnóstico
      }
    } else {
      print("Error al obtener el libro: ${response['message']}");  // Diagnóstico
    }
    return null;
  }

  // Método asíncrono que obtiene los libros de un usuario por categorías.
  Future<List<Book>> getUserBooksByCategory(String userId, String categoryName) async {
    try {
      // Llamamos al servicio para obtener los libros filtrados
      final books = await bookService.getBooksByCategoryForUser(userId, categoryName);
      return books;
    } catch (e) {
      throw Exception('Error al obtener los libros por categoría desde el controlador: $e');
    }
  }

}
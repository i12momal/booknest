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
    String language, String format, File? file, String summary, String categories) async {

    String? fileUrl = '';

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

    // Creación del viewModel
    final addBookViewModel = CreateBookViewModel(
      title: title,
      author: author,
      isbn: isbn,
      pagesNumber: pagesNumber,
      language: language,
      format: format,
      file: fileUrl,
      summary: summary,
      categories: categories,
      state: "Disponible",
      ownerId: userId,
      currentHolderId: userId
    );
    
    // Llamada al servicio para registrar al usuario
    return await bookService.addBook(addBookViewModel);
  }

  Future<Map<String, dynamic>> editBook(int id, String title, String author, String isbn, int pagesNumber, String language, String format,
    File? file, String summary, String genres, String state, String ownerId, String currentHolderId) async {
    String? imageUrl;

    // Obtener la URL del archivo actual del libro
    final currentBook = await bookService.getBookById(id);
    String? currentImageUrl;
    if (currentBook['success'] && currentBook['data'] != null) {
      currentImageUrl = currentBook['data']['file'];
      print("URL del archivo actual: $currentImageUrl");
    } else {
      print("Error al obtener el libro o archivo actual.");
    }

    // Validar si el archivo es nuevo y local antes de subirlo
    if (file != null && file.path.startsWith('/')) {
      try {
        // Eliminar archivo anterior si existe
        if (currentImageUrl != null) {
          print("Eliminando archivo anterior...");
          await bookService.deleteFile(currentImageUrl);
        }

        // Subir nuevo archivo y obtener URL
        imageUrl = await bookService.uploadFile(file, title, ownerId);

        if (imageUrl == null) {
          print("Error al subir el archivo. La URL es nula.");
          return {
            'success': false,
            'message': 'Error al subir el archivo. Por favor, intente nuevamente.'
          };
        }
        print("Nueva URL del archivo: $imageUrl");
      } catch (e) {
        print("Error al procesar el archivo: $e");
        return {
          'success': false,
          'message': 'Error al procesar el archivo. Por favor, intente nuevamente.'
        };
      }
    } else {
      // No se subió un nuevo archivo, mantener el actual
      imageUrl = currentImageUrl ?? '';
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
      summary: summary,
      state: state,
      ownerId: ownerId,
      currentHolderId: currentHolderId
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


}
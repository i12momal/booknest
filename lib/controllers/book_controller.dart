import 'dart:io';
import 'package:booknest/controllers/base_controller.dart';
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
}
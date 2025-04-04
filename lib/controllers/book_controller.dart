import 'dart:io';
import 'package:booknest/controllers/base_controller.dart';
import 'package:booknest/entities/viewmodels/book_view_model.dart';
import 'package:file_picker/file_picker.dart';

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

    String fileUrl = '';

    // Si el usuario sube un archivo, la guardamos en Supabase
    if (file != null) {
      //fileUrl = await uploadBookFile(file, title);
      if (fileUrl == null) {
        return {'success': false, 'message': 'Error al subir el archivo'};
      }
    }

    // Obtener el ID del usuario
    final userId = await accountService.getCurrentUserId();
    if (userId == null) {
      return {'success': false, 'message': 'Usuario no autenticado'};
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

  /* Método para guardar un archivo en Supabase.
     Parámetros:
      - file: archivo del libro.
      - title: título del libro para crear el nombre con el que se va a almacenar el archivo.
  */
  Future<String?> pickAndUploadFile(String bookTitle, String? userId) async {
    FilePickerResult? filePickerResult = await FilePicker.platform.pickFiles(allowMultiple: false);
    if (filePickerResult == null) return null;

    File file = File(filePickerResult.files.single.path!);
    isUploading = true;

    // Llamar a `uploadFile` con los parámetros adecuados
    String? fileName = await bookService.uploadFile(file, bookTitle, userId);

    isUploading = false;

    if (fileName != null) {
      print("Archivo subido correctamente: $fileName");
      return fileName; // Devuelve el nombre del archivo
    } else {
      print("Error al subir el archivo.");
      return null;
    }
}



}
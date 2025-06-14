import 'dart:io';
import 'dart:typed_data';
import 'package:booknest/controllers/base_controller.dart';
import 'package:booknest/entities/models/book_model.dart';
import 'package:booknest/entities/viewmodels/book_view_model.dart';

// Controlador con los métodos de las acciones de Libros.
class BookController extends BaseController{
  bool isUploading = false;
  String? uploadedFileName;

  // Método asíncrono que permite añadir un nuevo libro.
  Future<Map<String, dynamic>> addBook(String title, String author, String isbn, int pagesNumber,
    String language, String format, dynamic file, String summary, String categories, dynamic coverImage) async {

    String? fileUrl = '';
    String? coverImageUrl = '';

    // Obtener el ID del usuario
    final userId = await accountService.getCurrentUserId();
    if (userId == null) {
      return {'success': false, 'message': 'Usuario no autenticado'};
    }

    // Si el usuario sube un archivo, la guardamos en Supabase
    if (file != null) {
      if (file is File) {
        fileUrl = await bookService.uploadFile(file, title, userId);
      } else if (file is Uint8List) {
        fileUrl = await bookService.uploadFileWeb(file, title, userId);
      } else {
        return {'success': false, 'message': 'Tipo de archivo no soportado'};
      }

      if (fileUrl == null) {
        return {'success': false, 'message': 'Error al subir el archivo'};
      }
    }

    // Subir portada (File o Uint8List)
    if (coverImage != null) {
      if (coverImage is File) {
        coverImageUrl = await bookService.uploadCoverMobile(coverImage, title, userId);
      } else if (coverImage is Uint8List) {
        coverImageUrl = await bookService.uploadCoverWeb(coverImage, title, userId);
      }

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
    
    // Llamada al servicio para registrar el libro
    return await bookService.addBook(addBookViewModel);
  }

  // Método asíncrono que permite editar un libro.
  Future<Map<String, dynamic>> editBook(int id, String title, String author, String isbn, int pagesNumber, String language, String format, dynamic file, String summary,
    String genres, String state, String ownerId, dynamic coverImage) async {
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
    } else if (file != null) {
      try {
        if (currentImageUrl != null) {
          print("Reemplazando archivo anterior...");
          await bookService.deleteFile(currentImageUrl);
        }

        if (file is File && file.path.startsWith('/')) {
          // Dispositivos móviles o escritorio
          imageUrl = await bookService.uploadFile(file, title, ownerId);
        } else if (file is Uint8List) {
          // Flutter Web
          imageUrl = await bookService.uploadFileWeb(file, title, ownerId);
        } else {
          print("Tipo de archivo no soportado: ${file.runtimeType}");
          return {
            'success': false,
            'message': 'Tipo de archivo no soportado para el libro.'
          };
        }

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
    if (coverImage != null) {
      try {
        if (currentCoverImageUrl != null) {
          print("Eliminando portada anterior...");
          await bookService.deleteFile(currentCoverImageUrl);
        }

        if (coverImage is File) {
          // Dispositivos móviles o escritorio
          coverUrl = await bookService.uploadCoverMobile(coverImage, title, ownerId);
        } else if (coverImage is Uint8List) {
          // Flutter Web
          coverUrl = await bookService.uploadCoverWeb(coverImage, title, ownerId);
        } else {
          print("Tipo de portada no soportado: ${coverImage.runtimeType}");
          return {
            'success': false,
            'message': 'Tipo de imagen no soportado para la portada.'
          };
        }

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

  // Método asíncrono que devuelve los datos de un libro en base a su id.
  Future<Book?> getBookById(int bookId) async {
    var response = await bookService.getBookById(bookId);

    // Comprobar si 'response' tiene la estructura esperada
    if (response.containsKey('success') && response['success'] == true) {
      print("Éxito: Datos del libro obtenidos");

      if (response['data'] != null) {
        print("Datos del libro: ${response['data']}");

        // Convertir la respuesta en un objeto Book
        var book = Book.fromJson(response['data']);
        print("Libro convertido: ${book.title}, ${book.categories}, ${book.format}");
        return book;
      } else {
        print("Datos del libro son null");
      }
    } else {
      print("Error al obtener el libro: ${response['message']}");
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

  // Método asíncrono para eliminar un libro en base a su id.
  Future<Map<String, dynamic>> deleteBook(int bookId) async {
    return await bookService.deleteBook(bookId);
  }

  // Método asíncrono que obtiene todos los libros que hay en el sistema.
  Future<List<Map<String, dynamic>>> fetchAllBooks() async {
    return bookService.fetchAllBooks();
  }

  // Método asíncrono que obtiene los libros de un usuario.
  Future<List<Book>> getUserBooks(String userId) async {
    try {
      // Llamamos al servicio para obtener los libros filtrados
      final books = await bookService.getBooksForUser(userId);
      return books;
    } catch (e) {
      throw Exception('Error al obtener los libros del usuario desde el controlador: $e');
    }
  }

  // Método asíncrono que obtiene los libros físicos de un usuario.
  Future<List<Book>> getUserPhysicalBooks(String userId) async {
    try {
      // Llamamos al servicio para obtener los libros filtrados
      final books = await bookService.getUserPhysicalBooks(userId);
      return books;
    } catch (e) {
      throw Exception('Error al obtener los libros del usuario desde el controlador: $e');
    }
  }

  // Método Asíncrono que obtiene los libros físicos disponibles del usuario.
  Future<List<Book>> getUserAvailablePhysicalBooks(String userId) async {
    try {
      // Llamamos al servicio para obtener los libros físicos disponibles filtrados
      final books = await bookService.getUserAvailablePhysicalBooks(userId);
      return books;
    } catch (e) {
      throw Exception('Error al obtener los libros del usuario desde el controlador: $e');
    }
  }

  // Método asíncrono para cambiar el estado de un libro.
  Future<void> changeState(int bookId, String state) async {
    await bookService.changeState(bookId, state);
  }

  // Método asíncrono para obtener el id de un libro por su título y propietario.
  Future<int?> getBookIdByTitleAndOwner(String title, String ownerId) async{
    return await bookService.getBookIdByTitleAndOwner(title, ownerId);
  }

  // Método que comprueba si el título de un libro ya existe.
  Future<bool> checkTitleExists(String title, String ownerId) async {
    return await bookService.checkTitleExists(title, ownerId);
  }

  // Obtener la Url firmada de un archivo (web)
   Future<String?> getSignedUrl(String filePath) {
    return bookService.getSignedUrl(filePath);
  }

}
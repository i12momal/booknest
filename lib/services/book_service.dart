import 'dart:io';
import 'package:booknest/controllers/geolocation_controller.dart';
import 'package:booknest/entities/models/book_model.dart';
import 'package:booknest/entities/viewmodels/book_view_model.dart';
import 'package:booknest/services/base_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:diacritic/diacritic.dart';

// Servicio con los métodos de negocio para la entidad Libro.
class BookService extends BaseService{

  // Método asíncrono que permite añadir un nuevo libro.
  Future<Map<String, dynamic>> addBook(CreateBookViewModel createBookViewModel) async {
    try {
      if (BaseService.client == null) {
        return {'success': false, 'message': 'Error de conexión a la base de datos.'};
      }

      // Crear el registro en la tabla Book 
      print("Creando registro en la tabla Book...");
      final Map<String, dynamic> bookData = {
        'title': createBookViewModel.title,
        'author': createBookViewModel.author,
        'isbn': createBookViewModel.isbn,
        'pagesNumber': createBookViewModel.pagesNumber,
        'language': createBookViewModel.language,
        'format': createBookViewModel.format,
        'file': createBookViewModel.file,
        'cover': createBookViewModel.cover,
        'summary': createBookViewModel.summary,
        'categories': createBookViewModel.categories,
        'state': createBookViewModel.state,
        'owner_id': createBookViewModel.ownerId,
      };
      print("Datos a insertar: $bookData");

      final response = await BaseService.client.from('Book').insert(bookData).select().single();

      print("Respuesta de la inserción en Book: $response");

      if (response != null) {
        print("Libro registrado exitosamente");

        // Actualizar ubicación y libros del usuario
        try {
          await GeolocationController().actualizarLibrosEnUbicacion();
          print("Ubicación y libros actualizados correctamente.");
        } catch (geoError) {
          print("Error al guardar ubicación y libros: $geoError");
        }

        return {
          'success': true,
          'message': 'Libro registrado exitosamente',
          'data': response
        };
      } else {
        print("Error: No se pudo crear el registro en la tabla Book");
        return {'success': false, 'message': 'Error al registrar el libro'};
      }
    } catch (ex) {
      print("Error en addBook: $ex");
      return {'success': false, 'message': ex.toString()};
    }
  }

  // Método para subir un archivo a Supabase Storage.
  Future<String?> uploadFile(File file, String bookTitle, String? userId) async {
    try {
      String sanitizedTitle = removeDiacritics(bookTitle).replaceAll(' ', '_');
      String fileExt = file.path.split('.').last;
      int timestamp = DateTime.now().millisecondsSinceEpoch;
      String fileName = "${sanitizedTitle}_${userId}_$timestamp.$fileExt";

      // Obtener lista de archivos actuales
      final List<FileObject> existingFiles = await Supabase.instance.client.storage
          .from('books')
          .list(path: 'books/');

      // Eliminar archivos anteriores del mismo usuario/libro
      final userFiles = existingFiles.where((file) =>
          file.name.startsWith('${sanitizedTitle}_$userId')).toList();

      for (var file in userFiles) {
        try {
          await Supabase.instance.client.storage
              .from('books')
              .remove(['books/${file.name}']);
          print("Archivo anterior eliminado: ${file.name}");
        } catch (deleteError) {
          print("Error al eliminar archivo anterior: $deleteError");
        }
      }

      // Subir nuevo archivo con timestamp
      final response = await Supabase.instance.client.storage
          .from("books")
          .upload("books/$fileName", file);

      final String publicUrl = Supabase.instance.client.storage
          .from("books")
          .getPublicUrl("books/$fileName");

      print("Archivo subido correctamente: $fileName");
      return publicUrl;
    } catch (e) {
      print("Error al procesar el archivo: $e");
      return null;
    }
  }

  // Método asíncrono para subir una imagen de portada de libro a Supabase
  Future<String?> uploadCover(File file, String bookTitle, String? userId) async {
    try {
      // Normalizamos el título para crear un nombre de archivo único
      String sanitizedTitle = removeDiacritics(bookTitle).replaceAll(' ', '_');
      String fileExt = file.path.split('.').last;
      int timestamp = DateTime.now().millisecondsSinceEpoch;
      String fileName = "${sanitizedTitle}_${userId}_$timestamp.$fileExt";

      // Obtener lista de archivos actuales
      final List<FileObject> existingFiles = await Supabase.instance.client.storage.from('books').list(path: 'covers/');

      // Eliminar archivos anteriores del mismo usuario/libro (optimizando la eliminación)
      final userFiles = existingFiles.where((file) =>
          file.name.startsWith('${sanitizedTitle}_$userId')).toList();

      if (userFiles.isNotEmpty) {
        // Realizamos la eliminación en bloque para evitar múltiples llamadas
        final fileNamesToDelete = userFiles.map((file) => 'covers/${file.name}').toList();
        await Supabase.instance.client.storage.from('books').remove(fileNamesToDelete);
        print("Portadas anteriores eliminadas: $fileNamesToDelete");
      }

      // Subir nuevo archivo con timestamp
      final response = await Supabase.instance.client.storage.from("books").upload("covers/$fileName", file);

      // Obtener URL pública del archivo subido
      final String publicUrl = Supabase.instance.client.storage.from("books").getPublicUrl("covers/$fileName");

      print("Portada subida correctamente: $fileName");
      return publicUrl;
    } catch (e) {
      print("Error al procesar la portada: $e");
      return null;
    }
  }

  // Método asíncrono que obtiene los datos de un libro.
  Future<Map<String, dynamic>> getBookById(int bookId) async {
    try {
      // Comprobamos si la conexión a Supabase está activa.
      if (BaseService.client == null) {
        return {'success': false, 'message': 'Error de conexión a la base de datos.'};
      }

      // Llamada a la base de datos para obtener los datos del libro.
      final response = await BaseService.client.from('Book').select().eq('id', bookId).maybeSingle();

      // Verificamos si la respuesta contiene datos.
      if (response != null && response.isNotEmpty) {
        return {'success': true, 'message': 'Libro obtenido correctamente', 'data': response};
      } else {
        return {'success': false, 'message': 'No se ha encontrado el libro'};
      }
    } catch (ex) {
      // Si ocurre alguna excepción, devolverla.
      return {'success': false, 'message': ex.toString()};
    }
  }

  // Método asíncrono que permite editar un libro.
  Future<Map<String, dynamic>> editBook(EditBookViewModel editBookViewModel) async {
    try {
      // Comprobamos si la conexión a Supabase está activa.
      if (BaseService.client == null) {
        return {'success': false, 'message': 'Error de conexión a la base de datos.'};
      }

      // Obtener el ID del usuario autenticado
      final currentUser = BaseService.client.auth.currentUser;
      if (currentUser == null) {
        print("Error: Usuario no autenticado");
        return {'success': false, 'message': 'Usuario no autenticado'};
      }

      // Verificar que el libro existe
      print("Verificando existencia del libro...");
      final existingBook = await BaseService.client.from('Book').select().eq('id', editBookViewModel.id).single();
      if (existingBook == null) {
        print("Error: Usuario no encontrado en la base de datos");
        return {'success': false, 'message': 'Libro no encontrado'};
      }

      print("Preparando los datos de actualización...");

      // Preparar los datos para actualización
      final Map<String, dynamic> updateData = {};

      // Solo agregar campos que han cambiado
      if (existingBook['title'] != editBookViewModel.title) {
        updateData['title'] = editBookViewModel.title;
      }
      if (existingBook['author'] != editBookViewModel.author) {
        updateData['author'] = editBookViewModel.author;
      }
      if (existingBook['isbn'] != editBookViewModel.isbn) {
        updateData['isbn'] = editBookViewModel.isbn;
      }
      if (existingBook['pagesNumber'] != editBookViewModel.pagesNumber) {
        updateData['pagesNumber'] = editBookViewModel.pagesNumber;
      }
      if (existingBook['language'] != editBookViewModel.language) {
        updateData['language'] = editBookViewModel.language;
      }
      if (existingBook['format'] != editBookViewModel.format) {
        updateData['format'] = editBookViewModel.format;
      }
      if (existingBook['summary'] != editBookViewModel.summary) {
        updateData['summary'] = editBookViewModel.summary;
      }
      if (existingBook['categories'] != editBookViewModel.categories) {
        updateData['categories'] = editBookViewModel.categories;
      }
      // Aquí es donde se asegura de actualizar el archivo con la nueva URL.
      if (editBookViewModel.file != existingBook['file']) {
        updateData['file'] = editBookViewModel.file;
      }
      if (editBookViewModel.cover != existingBook['cover']) {
        updateData['cover'] = editBookViewModel.cover; 
      }

      print("Datos a actualizar: $updateData");

      // Si no hay cambios, retornar éxito sin actualizar
      if (updateData.isEmpty) {
        print("No hay cambios para actualizar");
        return {'success': true, 'message': 'No hay cambios para actualizar', 'data': existingBook};
      }

      // Actualizar el usuario y obtener los datos actualizados en una sola operación
      print("Intentando actualizar libro...");
      final response = await BaseService.client.from('Book').update(updateData).eq('id', editBookViewModel.id).select().single();

      print("Respuesta de la actualización: $response");

      if (response != null) {
        try {
          await GeolocationController().actualizarLibrosEnUbicacion();
          print("Ubicación y libros actualizados correctamente después de editar el libro.");
        } catch (geoError) {
          print("Error al actualizar ubicación y libros tras la edición: $geoError");
        }

        return {'success': true, 'message': 'Libro actualizado exitosamente', 'data': response};
      } else {
        print("Error: No se pudo actualizar el libro");
        return {'success': false, 'message': 'Error al editar la información del libro'};
      }
    } catch (ex) {
      print("Error en editBook: $ex");
      return {'success': false, 'message': ex.toString()};
    }
  }

  // Método asíncrono para eliminar un archivo 
  Future<void> deleteFile(String fileUrl) async {
    try {
      // Eliminar el archivo anterior utilizando la URL del archivo
      final fileName = fileUrl.split('/').last;
      await Supabase.instance.client.storage
          .from('books')
          .remove(['books/$fileName']);
      print("Archivo anterior eliminado: $fileName");
    } catch (e) {
      print("Error al eliminar el archivo anterior: $e");
    }
  }

  // Método asíncrono que obtiene los libros relacionados con una categoría.
  Future<List<Map<String, dynamic>>> getBooksByCategories(List<String> categories) async {
    final filters = categories.map((cat) => "categories.ilike.%$cat%").join(',');

    final List<dynamic> response = await Supabase.instance.client.from('Book').select().or(filters);

    return response.map((e) => Map<String, dynamic>.from(e)).toList();

  }

  // Método asíncrono que obtiene todos los libros existentes
  Future<List<Map<String, dynamic>>> getAllBooks({bool includeUnavailable = false}) async {
    var query = Supabase.instance.client.from('Book').select();

    if (!includeUnavailable) {
      query = query.eq('state', 'Disponible');
    }

    final List<dynamic> response = await query;
    return response.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  // Método asíncrono que busca los libros por título o autor
  Future<List<Map<String, dynamic>>> searchBooksByTitleOrAuthor(String query) async {
    // Creamos el filtro compuesto para búsqueda por título o autor
    final filters = ["title.ilike.%$query%","author.ilike.%$query%",].join(',');

    // Realizamos la consulta a la base de datos
    final List<dynamic> response = await BaseService.client.from('Book').select().or(filters); // Aplicamos el filtro OR con el título o autor

    // Devolvemos los resultados como una lista de mapas
    return response.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  // Método asíncrono para obtener los libros del usuario
  Future<List<Book>> getBooksForUser(String userId) async {
    try {
      final response = await BaseService.client.from('Book').select().eq('owner_id', userId);

      // Verificamos si la respuesta es nula o si no contiene datos
      if (response == null || response.isEmpty) {
        return [];
      }

      // Convertimos los datos en una lista de libros
      List<dynamic> data = response;
      return data.map((book) => Book.fromJson(book)).toList();
    } catch (e) {
      print('Error obteniendo libros: $e');
      return [];
    }
  }

  // Método asíncrono para obtener los libros físicos de un usuario.
  Future<List<Book>> getUserPhysicalBooks(String userId) async {
    try {
      final response = await BaseService.client.from('Book').select().eq('owner_id', userId).like('format', '%Físico%');

      // Verificamos si la respuesta es nula o si no contiene datos
      if (response == null || response.isEmpty) {
        return [];
      }

      // Convertimos los datos en una lista de libros
      List<dynamic> data = response;
      return data.map((book) => Book.fromJson(book)).toList();
    } catch (e) {
      print('Error obteniendo libros: $e');
      return [];
    }
  }

  // Método asíncrono para obtener los libros físicos disponibles del usuario.
  Future<List<Book>> getUserAvailablePhysicalBooks(String userId) async {
    try {
      final response = await BaseService.client.from('Book').select().eq('owner_id', userId).eq('state', 'Disponible').eq('format', 'Físico');
      //.like('format', '%Físico%');    

      // Verificamos si la respuesta es nula o si no contiene datos
      if (response == null || response.isEmpty) {
        return [];
      }

      // Convertimos los datos en una lista de libros
      List<dynamic> data = response;
      return data.map((book) => Book.fromJson(book)).toList();
    } catch (e) {
      print('Error obteniendo libros: $e');
      return [];
    }
  }

  // Método asíncrono para obtener los libros de un usuario y filtrar por categoría
  Future<List<Book>> getBooksByCategoryForUser(String userId, String categoryName) async {
    try {
      // Primero obtenemos todos los libros del usuario
      final books = await getBooksForUser(userId);

      // Filtramos los libros que contienen la categoría especificada
      List<Book> filteredBooks = books.where((book) {
        if (book.categories == null || book.categories.isEmpty) {
          return false; // Si no tiene categorías, no lo incluimos
        }

        // Dividimos las categorías y las limpiamos de espacios extras
        List<String> categories = book.categories.split(',').map((category) => category.trim()).toList();

        // Verificar si la categoría especificada está entre las categorías del libro
        bool matchFound = categories.any((category) => category.toLowerCase() == categoryName.toLowerCase());

        return matchFound;
      }).toList();

      return filteredBooks;
    } catch (e) {
      print('Error al obtener los libros por categoría para el usuario: $e');
      return [];
    }
  }

  // Método asíncrono para eliminar un libro
  Future<Map<String, dynamic>> deleteBook(int bookId) async {
    try {
      // Paso 1: Obtener todos los préstamos asociados con el libro
      final loans = await BaseService.client.from('Loan').select('id').eq('bookId', bookId);

      //Paso 2: Eliminar los préstamos asociados al libro
      await BaseService.client.from('Loan').delete().eq('bookId', bookId);

      // Paso 3: Eliminar reseñas
      await BaseService.client.from('Review').delete().eq('bookId', bookId);

      // Paso 4: Eliminar notificaciones
      for (var loan in loans) {
        final loanId = loan['id']; // Obtenemos el id de cada préstamo
        await BaseService.client.from('Notifications').delete().eq('relatedId', loanId); // Eliminar las notificaciones cuyo relatedId es el loanId
      }

      // Paso 5: Eliminar el libro
      final bookResponse = await BaseService.client.from('Book').delete().eq('id', bookId).select();

      if (bookResponse.isNotEmpty) {
        return {'success': true};
      } else {
        return {
          'success': false,
          'message': 'Libro no encontrado o no se pudo eliminar'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error al eliminar el libro'};
    }
  }

  // Método asíncrono para obtener todos los libros existentes.
  Future<List<Map<String, dynamic>>> fetchAllBooks() async {
    try {
      final response = await Supabase.instance.client.from('Book').select();

      if (response != null && response is List) {
        return response.map((e) => Map<String, dynamic>.from(e)).toList();
      } else {
        return [];
      }
    } catch (e) {
      print('Error al obtener libros: $e');
      return [];
    }
  }

  // Método asíncrono para cambiar el estado de un libro.
  Future<void> changeState(int bookId, String state) async {
    try {
      print('Intentando actualizar el estado del libro $bookId a "$state"...');

      final response = await BaseService.client.from('Book').update({'state': state}).eq('id', bookId).select();

      print('Respuesta de Supabase al cambiar el estado: $response');
    } catch (e) {
      print('Error al cambiar el estado de Book: $e');
    }
  }

  // Método asíncrono que obtiene el id de un libro por título y propietario
  Future<int?> getBookIdByTitleAndOwner(String title, String ownerId) async {
    try {
      final response = await BaseService.client
          .from('Book')
          .select('id')
          .eq('title', title.trim())
          .eq('owner_id', ownerId)
          .limit(1)
          .maybeSingle();

      if (response == null) {
        print(' No se encontró ningún libro con ese título y owner_id');
        return null;
      }

      return response['id'] as int?;
    } catch (e) {
      print(' Error obteniendo ID del libro: $e');
      return null;
    }
  }

  // Método asíncrono que comprueba si un título ya existe.
  Future<bool> checkTitleExists(String title, String ownerId) async {
    final response = await Supabase.instance.client
      .from('Book')
      .select('id')
      .eq('title', title).eq('owner_id', ownerId)
      .maybeSingle();

    return response != null;
  }

  // Obtener la Url firmada de un archivo (web)
  Future<String?> getSignedUrl(String filePath) async {
    try {
      final signedUrl = await BaseService.client.storage.from('books').createSignedUrl(filePath, 7200);
      return signedUrl;
    } catch (e) {
      return null;
    }
  }


}
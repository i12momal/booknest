import 'dart:io';
import 'package:booknest/entities/viewmodels/book_view_model.dart';
import 'package:booknest/services/base_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BookService extends BaseService{

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
        'summary': createBookViewModel.summary,
        'categories': createBookViewModel.categories,
        'state': createBookViewModel.state,
        'owner_id': createBookViewModel.ownerId,
        'currentHolderId': createBookViewModel.currentHolderId,
      };
      print("Datos a insertar: $bookData");

      final response = await BaseService.client.from('Book').insert(bookData).select().single();

      print("Respuesta de la inserción en Book: $response");

      if (response != null) {
        print("Libro registrado exitosamente");

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

  /* Método para subir un archivo a Supabase Storage.
     Parámetros:
      - file: archivo del libro.
      - title: título del libro para crear el nombre con el que se va a almacenar el archivo.
  */
  Future<String?> uploadFile(File file, String bookTitle, String? userId) async {
    try {
      // Normalizamos el título para crear un nombre de archivo único
      String sanitizedTitle = bookTitle.replaceAll(' ', '_');
      String fileExt = file.path.split('.').last;
      int timestamp = DateTime.now().millisecondsSinceEpoch;

      // Nuevo nombre con timestamp para evitar caché
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





  // Método asíncrono que obtiene los datos de un libro.
  Future<Map<String, dynamic>> getBookById(int bookId) async {
    try {
      // Comprobamos si la conexión a Supabase está activa.
      if (BaseService.client == null) {
        return {'success': false, 'message': 'Error de conexión a la base de datos.'};
      }

      // Llamada a la base de datos para obtener los datos del libro.
      final response = await BaseService.client
          .from('Book')
          .select()
          .eq('id', bookId)
          .maybeSingle();

      print("Respuesta de Supabase: $response");

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

  Future<Map<String, dynamic>> editBook(EditBookViewModel editBookViewModel) async {
    try {
      // Comprobamos si la conexión a Supabase está activa.
      if (BaseService.client == null) {
        return {'success': false, 'message': 'Error de conexión a la base de datos.'};
      }

      print("Iniciando edición del libro...");
      print("ID del libro a editar: ${editBookViewModel.id}");

      // Obtener el ID del usuario autenticado
      final currentUser = BaseService.client.auth.currentUser;
      if (currentUser == null) {
        print("Error: Usuario no autenticado");
        return {'success': false, 'message': 'Usuario no autenticado'};
      }

      print("ID del usuario autenticado (auth.uid): ${currentUser.id}");
      print("Email del usuario autenticado: ${currentUser.email}");

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

      print("Datos a actualizar: $updateData");

      // Si no hay cambios, retornar éxito sin actualizar
      if (updateData.isEmpty) {
        print("No hay cambios para actualizar");
        return {'success': true, 'message': 'No hay cambios para actualizar', 'data': existingBook};
      }

      // Actualizar el usuario y obtener los datos actualizados en una sola operación
      print("Intentando actualizar libro...");
      final response = await BaseService.client
          .from('Book')
          .update(updateData)
          .eq('id', editBookViewModel.id)
          .select()
          .single();

      print("Respuesta de la actualización: $response");

      if (response != null) {
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

}
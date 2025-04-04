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
        'ownerId': createBookViewModel.ownerId,
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
      // Normalizar el título del libro para evitar caracteres problemáticos en el nombre del archivo
      String sanitizedTitle = bookTitle.replaceAll(' ', '_');
      
      // Definir la extensión del archivo
      String fileExt = file.path.split('.').last;

      // Crear el nombre de archivo con el título, UID y timestamp
      String fileName = "${sanitizedTitle}_$userId.$fileExt";

      // Buscar archivos existentes del mismo libro y usuario
      try {
        final List<FileObject> existingFiles = await Supabase.instance.client.storage
            .from('books')
            .list(path: 'books/');

        // Filtrar archivos que coincidan con el libro y usuario
        final userFiles = existingFiles.where((file) => 
          file.name.startsWith('${sanitizedTitle}_$userId')
        ).toList();

        // Eliminar el archivo anterior si existe
        if (userFiles.isNotEmpty) {
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
        }
      } catch (listError) {
        print("Error al listar archivos existentes: $listError");
      }

      // Subir el nuevo archivo
      await Supabase.instance.client.storage.from("books").upload(fileName, file);

      print("Archivo subido correctamente: $fileName");
      return fileName;
    } catch (e) {
      print("Error al subir el archivo: $e");
      return null;
    }
  }

}
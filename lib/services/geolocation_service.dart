import 'package:booknest/entities/models/book_model.dart';
import 'package:booknest/entities/models/geolocation_model.dart';
import 'package:booknest/services/base_service.dart';
import 'package:geolocator/geolocator.dart';

class GeolocationService extends BaseService{
  
  Future<List<Geolocation>> getNearbyUsers(Position position) async {
    final response = await BaseService.client
        .from('Geolocation')
        .select('userId, userName, latitude, longitude, books');

    final List<dynamic> data = response;

    // Convertir la lista JSON a objetos Geolocation
    List<Geolocation> allUsers = data.map((json) => Geolocation.fromJson(json)).toList();

    // Filtrar los que están dentro de 100km
    return allUsers.where((user) {
      double distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        user.latitude,
        user.longitude,
      );
      return distance <= 100000; // 100 km en metros
    }).toList();
  }


 Future<void> upsertUserLocation({required String userId, required String userName, required double latitude, required double longitude, required List<Book> books}) async {
  final List<Map<String, dynamic>> booksJson = books.map((book) => {
    'id': book.id,
    'title': book.title,
    'author': book.author,
    'isbn': book.isbn,
    'pagesNumber': book.pagesNumber,
    'language': book.language,
    'format': book.format,
    'file': book.file,
    'cover': book.cover,
    'summary': book.summary,
    'categories': book.categories,
    'state': book.state,
    'owner_id': book.ownerId,
  }).toList();

  try {
    final response = await BaseService.client
        .from('Geolocation')
        .upsert({
          'userId': userId,
          'userName': userName,
          'latitude': latitude,
          'longitude': longitude,
          'books': booksJson,
        });

    // Aquí simplemente imprimimos la respuesta, no intentamos acceder a response.error
    print('Ubicación y libros guardados correctamente. Respuesta: $response');
  } catch (e) {
    print('Excepción al guardar la ubicación y libros: $e');
  }
}



  Future<void> deleteUserLocationIfExists(String userId) async {
    try {
      final response = await BaseService.client
          .from('Geolocation')
          .delete()
          .eq('userId', userId);

      // Solo imprime la respuesta si es útil para debug
      print('Ubicación anterior eliminada. Respuesta: $response');
    } catch (e) {
      print('Error eliminando ubicación anterior: $e');
    }
  }


}
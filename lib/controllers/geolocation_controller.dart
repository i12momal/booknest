import 'package:booknest/controllers/account_controller.dart';
import 'package:booknest/controllers/base_controller.dart';
import 'package:booknest/controllers/book_controller.dart';
import 'package:booknest/entities/models/book_model.dart';
import 'package:booknest/entities/models/geolocation_model.dart';
import 'package:booknest/entities/models/user_model.dart' as user;
import 'package:geolocator/geolocator.dart';

class GeolocationController extends BaseController{

  Future<Position> getUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      // No puedes saber si lo habilitó o no, así que vuelve a verificar
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Los servicios de localización están deshabilitados');
      }
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Permiso de ubicación denegado');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Permiso de ubicación denegado permanentemente. Debes ir a Ajustes > Aplicaciones > Permisos para habilitarlo.');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }


  // Calcular la distancia entre dos puntos (en metros)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  // Filtrar los usuarios dentro de un radio
  List<Geolocation> filterUsersByDistance(
    List<Geolocation> users, Position currentPosition, double radiusInKm) {
    double radiusInMeters = radiusInKm * 1000;
    return users.where((user) {
      double distance = _calculateDistance(
        currentPosition.latitude,
        currentPosition.longitude,
        user.latitude,
        user.longitude,
      );
      return distance <= radiusInMeters;
    }).toList();
  }

  Future<List<Geolocation>> getNearbyUsers(Position position) async {
    return await geolocationService.getNearbyUsers(position);
  }

  Future<List<Book>> guardarUbicacionYLibros({bool? geolocationEnabled}) async {
    try {
      // ✅ Verifica permisos correctamente
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) throw Exception('Servicios de ubicación desactivados');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Permisos de ubicación denegados');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Permisos de ubicación denegados permanentemente');
      }

      final position = await getUserLocation();

      String userId = await AccountController().getCurrentUserIdNonNull();
      user.User currentUser = await accountService.getCurrentUser();
      String userName = currentUser.userName;

      final List<Book> librosDelUsuario = await BookController().getUserPhysicalBooks(userId);

      await geolocationService.upsertUserLocation(
        userId: userId,
        userName: userName,
        latitude: position.latitude,
        longitude: position.longitude,
        books: librosDelUsuario,
        geolocationEnabled: true,
      );

      print('Ubicación actualizada con éxito');
      return librosDelUsuario;
    } catch (e) {
      print('Error al guardar ubicación: $e');
      return [];
    }
  }


  Future<bool> isAvailable(int bookId) async {
    return geolocationService.isAvailable(bookId);
  }

  Future<bool> isUserGeolocationEnabled(String userId) async {
    return geolocationService.isUserGeolocationEnabled(userId);
  }

  Future<void> updateUserGeolocation(String userId, bool enabled) async {
    await geolocationService.updateUserGeolocation(userId, enabled);
  }

  Future<Geolocation?> getUserGeolocation(String userId) async {
    return await geolocationService.getUserGeolocation(userId);
  }

  Future<void> actualizarLibrosEnUbicacion() async {
  try {
    final userId = await AccountController().getCurrentUserIdNonNull();
    final librosDelUsuario = await BookController().getUserPhysicalBooks(userId);

    // ✅ Actualiza solo el campo de libros
    await geolocationService.updateUserBooksInLocation(userId: userId, books: librosDelUsuario);

    print("Libros actualizados en la ubicación con éxito");
  } catch (e) {
    print("Error al actualizar los libros en ubicación: $e");
  }
}

}
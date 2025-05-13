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
      serviceEnabled = await Geolocator.openLocationSettings();
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

    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
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

  Future<List<Book>> guardarUbicacionYLibros() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      String userId = await AccountController().getCurrentUserIdNonNull();

      user.User currentUser = await accountService.getCurrentUser();
      String userName = currentUser.userName;

      final List<Book> librosDelUsuario = await BookController().getUserPhysicalBooks(userId);

      // ✅ Eliminar ubicación anterior si existe
      await geolocationService.deleteUserLocationIfExists(userId);

      // ✅ Insertar nueva ubicación
      await geolocationService.upsertUserLocation(
        userId: userId,
        userName: userName,
        latitude: position.latitude,
        longitude: position.longitude,
        books: librosDelUsuario,
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
}
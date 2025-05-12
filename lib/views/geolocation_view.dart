import 'package:booknest/controllers/account_controller.dart';
import 'package:booknest/controllers/geolocation_controller.dart';
import 'package:booknest/entities/models/geolocation_model.dart';
import 'package:booknest/views/book_details_owner_view.dart';
import 'package:booknest/views/user_profile_view.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';

class GeolocationMap extends StatefulWidget {
  const GeolocationMap({super.key});

  @override
  State<GeolocationMap> createState() => _GeolocationMapState();
}


class _GeolocationMapState extends State<GeolocationMap> {
  late GoogleMapController mapController;
  LatLng _center = const LatLng(0, 0);
  final Set<Marker> _markers = {};
  List<Geolocation> _nearbyUsers = [];
  GeolocationController geoController = GeolocationController();
  String? userId;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    _loadUserId();
  }

  Future<void> _getUserLocation() async {
    try {
      final position = await geoController.getUserLocation();
      _center = LatLng(position.latitude, position.longitude);

      // Guarda la ubicación y libros del usuario (fuera de setState)
      geoController.guardarUbicacionYLibros();

      // Luego obtén los usuarios cercanos, pero no agregamos el usuario actual a los marcadores
      final users = await geoController.getNearbyUsers(position);
      _nearbyUsers = users;

      // Actualiza el estado visual con los marcadores
      setState(() {
        updateMarkers(_nearbyUsers);
      });

      // Mueve la cámara al centro de la ubicación
      mapController.animateCamera(CameraUpdate.newLatLng(_center));
    } catch (e) {
      print("Error obteniendo la ubicación: $e");
    }
  }

  void _loadUserId() async {
    final id = await AccountController().getCurrentUserId();
    setState(() {
      userId = id;
    });
  }

  void updateMarkers(List<Geolocation> nearbyUsers) {
    _markers.clear(); // Limpiar marcadores anteriores

    // Agregar marcador para la ubicación del usuario actual (solo "Tu ubicación")
    _markers.add(Marker(
      markerId: const MarkerId("user_location"),
      position: _center,
      infoWindow: const InfoWindow(title: "Tu ubicación"),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    ));

    // Ahora solo agregamos los marcadores de los usuarios cercanos (si no es el mismo que el usuario actual)
    for (var user in nearbyUsers) {
      if (user.userId != userId && user.books.isNotEmpty) { 
        _markers.add(Marker(
          markerId: MarkerId(user.userId),
          position: LatLng(user.latitude, user.longitude),
          infoWindow: InfoWindow(
            title: user.userName,
            snippet: '${user.books.length} libros disponibles',
            onTap: () {
              // Mostrar el nombre de usuario y los libros disponibles en una ventana emergente
              _showUserBooksDialog(user);
            },
          ),
        ));
      }
    }

    setState(() {});
  }

  void _showUserBooksDialog(Geolocation user) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFF112363), width: 3),
          ),
          title: Center(child: Text(user.userName)),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${user.books.length} libros disponibles:'),
                const SizedBox(height: 10),
                ...user.books.map((book) {
                  return GestureDetector(
                    onTap: () {
                      // Lógica para ir al detalle del libro
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BookDetailsOwnerView(bookId: book.id),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        book.title,
                        style: const TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserProfileView(userId: user.userId),
                  ),
                );
              },
              child: const Text('Ver perfil'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(
          child: Text("Mapa de Ubicación"),
        ),
      ),
      body: GoogleMap(
        onMapCreated: (GoogleMapController controller) {
          mapController = controller;
        },
        initialCameraPosition: CameraPosition(
          target: _center,
          zoom: 12,
        ),
        markers: _markers,
      ),
    );
  }
}

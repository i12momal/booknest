import 'package:booknest/controllers/geolocation_controller.dart';
import 'package:booknest/entities/models/geolocation_model.dart';
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

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    try {
      final position = await geoController.getUserLocation();
      _center = LatLng(position.latitude, position.longitude);

      // Guarda la ubicación y libros del usuario (fuera de setState)
      geoController.guardarUbicacionYLibros();

      // Luego obtén los usuarios cercanos
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

  void updateMarkers(List<Geolocation> nearbyUsers) {
    _markers.clear(); // Limpiar marcadores anteriores
    // Agregar marcador para el usuario actual
    _markers.add(Marker(
      markerId: const MarkerId("user_location"),
      position: _center,
      infoWindow: const InfoWindow(title: "Tu ubicación"),
    ));

    // Agregar marcadores para los usuarios cercanos
    for (var user in nearbyUsers) {
      _markers.add(Marker(
        markerId: MarkerId(user.userId),
        position: LatLng(user.latitude, user.longitude),
        infoWindow: InfoWindow(
          title: user.userName,
          snippet: '${user.books.length} libros disponibles',
        ),
        onTap: () {
          // Lógica para abrir el perfil del usuario
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => UserProfileView(userId: user.userId)),
          );
        },
      ));
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mapa de intercambio de libros")),
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

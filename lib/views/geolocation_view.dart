import 'package:booknest/controllers/account_controller.dart';
import 'package:booknest/controllers/geolocation_controller.dart';
import 'package:booknest/entities/models/book_model.dart';
import 'package:booknest/entities/models/geolocation_model.dart';
import 'package:booknest/views/book_details_owner_view.dart';
import 'package:booknest/views/user_profile_view.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';

class GeolocationMap extends StatefulWidget {
  final LatLng? focusLocation;
  final Geolocation? focusedUser;

  const GeolocationMap({super.key, this.focusLocation, this.focusedUser});

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

  Geolocation? _focusedUser;
  MarkerId? _focusedMarkerId;

  final List<Book> availableBooks = [];
  final List<Book> loanBooks = [];

  @override
  void initState() {
    super.initState();
    _focusedUser = widget.focusedUser;
    _getUserLocation();
    _loadUserId();
  }

  Future<void> _getUserLocation() async {
    try {
      // Obtener ubicación actual
      final position = await geoController.getUserLocation();
      final currentLocation = LatLng(position.latitude, position.longitude);

      // Guardar libros y ubicación del usuario
      await geoController.guardarUbicacionYLibros();

      // Obtener usuarios cercanos (excluyendo al actual)
      final users = await geoController.getNearbyUsers(position);

      // Limpiar listas anteriores
      availableBooks.clear();
      loanBooks.clear();

      // Clasificar libros disponibles y prestados
      for (var user in users) {
        for (var book in user.books) {
          final isAvailable = await geoController.isAvailable(book.id);
          if (isAvailable) {
            availableBooks.add(book);
          } else {
            loanBooks.add(book);
          }
        }
      }

      // Actualizar variables y marcadores en el estado
      setState(() {
        _center = currentLocation;
        _nearbyUsers = users;
        updateMarkers(_nearbyUsers);
      });

      // Mover la cámara del mapa a la ubicación actual
      mapController.animateCamera(CameraUpdate.newLatLng(currentLocation));
      // Si hay un usuario enfocado, mostrar su diálogo y mover la cámara a su ubicación
      if (_focusedUser != null) {
        final focused = _nearbyUsers.firstWhere(
          (u) => u.userId == _focusedUser!.userId,
          orElse: () => _focusedUser!,
        );

        // Mover la cámara al usuario enfocado
        mapController.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(focused.latitude, focused.longitude),
          ),
        );

        // Mostrar el diálogo tras un breve delay (asegura que el mapa está listo)
        Future.delayed(const Duration(milliseconds: 500), () {
          _showUserBooksDialog(focused);
        });
      }

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
        final isFocused = widget.focusedUser != null && widget.focusedUser!.userId == user.userId;
        final markerId = MarkerId(user.userId);

        if (isFocused) {
          _focusedMarkerId = markerId;
        }

        _markers.add(Marker(
          markerId: markerId,
          position: LatLng(user.latitude, user.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            isFocused ? BitmapDescriptor.hueYellow : BitmapDescriptor.hueRed,
          ),
          infoWindow: InfoWindow(
            title: user.userName,
            snippet: '${user.books.length} libros físicos',
            onTap: () {
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
                Text('${user.books.length} libros físicos:'),
                const SizedBox(height: 10),
                ...user.books.map((book) {
                  final isAvailable = availableBooks.any((b) => b.id == book.id);
                  final isLoaned = loanBooks.any((b) => b.id == book.id);

                  Icon statusIcon;
                  if (isAvailable) {
                    statusIcon = const Icon(Icons.check_circle, color: Colors.green, size: 18);
                  } else if (isLoaned) {
                    statusIcon = const Icon(Icons.cancel, color: Colors.red, size: 18);
                  } else {
                    statusIcon = const Icon(Icons.help_outline, color: Colors.grey, size: 18);
                  }

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
                      child: Row(
                        children: [
                          statusIcon,
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              book.title,
                              style: const TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
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

          if (_focusedMarkerId != null) {
            Future.delayed(const Duration(milliseconds: 500), () {
              final markerExists = _markers.any((m) => m.markerId == _focusedMarkerId);
              if (markerExists) {
                mapController.showMarkerInfoWindow(_focusedMarkerId!);
              }
            });
          }
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

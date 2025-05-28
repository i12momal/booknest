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
  GoogleMapController? mapController;
  LatLng _center = const LatLng(0, 0);
  final Set<Marker> _markers = {};
  List<Geolocation> _nearbyUsers = [];
  GeolocationController geoController = GeolocationController();
  String? userId;

  Geolocation? _focusedUser;
  MarkerId? _focusedMarkerId;

  final List<Book> availableBooks = [];
  final List<Book> loanBooks = [];

  bool _isLocationEnabled = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _focusedUser = widget.focusedUser;
    _loadUserIdAndCheckGeolocation();
  }

  void _loadUserIdAndCheckGeolocation() async {
    final id = await AccountController().getCurrentUserId();
    setState(() {
      userId = id;
    });

    final isEnabled = await GeolocationController().isUserGeolocationEnabled(userId!);

    if (!isEnabled) {
      final activar = await _mostrarDialogoActivarGeolocalizacion();

      if (!activar) {
        Navigator.pop(context);
        return;
      }

      // Si acepta, actualiza el valor en la base de datos
     await geoController.guardarUbicacionYLibros(geolocationEnabled: true);
      setState(() {
        _isLocationEnabled = true;
      });

    }

    // Si ya está activado o lo activó, continúa
    _getUserLocation();
  }

  Future<bool> _mostrarDialogoActivarGeolocalizacion() async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Geolocalización desactivada", style: TextStyle(fontSize: 20)),
        content: const Text("¿Deseas activar tu geolocalización para ver el mapa y los libros disponibles?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Activar"),
          ),
        ],
      ),
    ) ?? false;
  }



  Future<void> _getUserLocation() async {
    try {
      // Obtener ubicación actual
      final position = await geoController.getUserLocation();
      final currentLocation = LatLng(position.latitude, position.longitude);

      final isEnabled = await GeolocationController().isUserGeolocationEnabled(userId!);
      if (isEnabled) {
        await geoController.guardarUbicacionYLibros();
      }

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
        _isLoading = false;
      });

      // Mover la cámara del mapa a la ubicación actual
      if (mounted && mapController != null) {
        mapController!.animateCamera(CameraUpdate.newLatLng(currentLocation));
      }

     // Si hay un usuario enfocado, mostrar su diálogo y mover la cámara a su ubicación
    if (_focusedUser != null) {
      final focused = _nearbyUsers.firstWhere(
        (u) => u.userId == _focusedUser!.userId,
        orElse: () => _focusedUser!,
      );

      // Mover la cámara al usuario enfocado
      if (mapController != null) {
        mapController!.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(focused.latitude, focused.longitude),
          ),
        );
      }
    }

    } catch (e) {
      print("Error obteniendo la ubicación: $e");
    }
  }

  void updateMarkers(List<Geolocation> nearbyUsers) {
    _markers.clear(); 

    // Agregar marcador del usuario solo si tiene geolocalización habilitada
    if (_isLocationEnabled) {
      _markers.add(Marker(
        markerId: const MarkerId("user_location"),
        position: _center,
        infoWindow: const InfoWindow(title: "Tu ubicación"),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ));
    }

    // Agregar marcadores de usuarios cercanos
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
      body: _isLoading
    ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Cargando mapa...',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      )
      : GoogleMap(
        /*onMapCreated: (GoogleMapController controller) {
          mapController = controller;

          if (_focusedMarkerId != null) {
            Future.delayed(const Duration(milliseconds: 500), () {
              final markerExists = _markers.any((m) => m.markerId == _focusedMarkerId);
              if (markerExists) {
                mapController.showMarkerInfoWindow(_focusedMarkerId!);
              }
            });
          }
           setState(() {
            _isLoading = false;
          });
        },*/

        onMapCreated: (GoogleMapController controller) async {
          mapController = controller;

          if (_focusedUser != null) {
            // Espera un poco a que los marcadores estén en el mapa
            await Future.delayed(const Duration(milliseconds: 300));

            final focused = _nearbyUsers.firstWhere(
              (u) => u.userId == _focusedUser!.userId,
              orElse: () => _focusedUser!,
            );

            final focusLatLng = LatLng(focused.latitude, focused.longitude);
            
            await mapController!.animateCamera(CameraUpdate.newLatLngZoom(focusLatLng, 14));

            // Muestra el diálogo tras un pequeño delay para asegurar visibilidad
            Future.delayed(const Duration(milliseconds: 500), () {
              _showUserBooksDialog(focused);
            });
          }

          if (_focusedMarkerId != null && mapController != null) {
            final markerExists = _markers.any((m) => m.markerId == _focusedMarkerId);
            if (markerExists) {
              mapController!.showMarkerInfoWindow(_focusedMarkerId!);
            }
          }

          setState(() {
            _isLoading = false;
          });
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

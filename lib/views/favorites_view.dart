import 'package:booknest/controllers/account_controller.dart';
import 'package:booknest/controllers/book_controller.dart';
import 'package:booknest/controllers/loan_controller.dart';
import 'package:booknest/controllers/reminder_controller.dart';
import 'package:booknest/controllers/user_controller.dart';
import 'package:booknest/views/book_details_owner_view.dart';
import 'package:booknest/views/geolocation_view.dart';
import 'package:booknest/views/home_view.dart';
import 'package:booknest/views/owner_profile_view.dart';
import 'package:booknest/views/user_search_view.dart';
import 'package:booknest/widgets/background.dart';
import 'package:booknest/widgets/footer.dart';
import 'package:flutter/material.dart';

// Vista para la acción de Visualizar los libros favoritos de un usuario
class FavoritesView extends StatefulWidget {
  const FavoritesView({super.key});

  @override
  State<FavoritesView> createState() => _FavoritesViewState();
}

class _FavoritesViewState extends State<FavoritesView> {
  List<Map<String, dynamic>> allFavorites = [];
  List<Map<String, dynamic>> filteredFavorites = [];
  String selectedLetter = '';
  String? userId;

  List<bool> isReminderActiveList = [];

  int currentPage = 1;
  final int itemsPerPage = 20;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _loadUserId();
  }

  // Función para obtener el id del usuario actual
  Future<void> _loadUserId() async {
    final id = await AccountController().getCurrentUserId();
    setState(() {
      userId = id;
    });
  }

  // Función para cargar los libros favoritos del usuario
  Future<void> _loadFavorites() async {
    setState(() {
      isLoading = true;
    });

    final response = await UserController().getFavorites();
    
    // Verifica si la respuesta tiene los favoritos
    final userFavoritesIds = List<String>.from(response['favorites'] ?? []);
    
    // Si no hay favoritos, mostramos una lista vacía
    if (userFavoritesIds.isEmpty) {
      setState(() {
        allFavorites = [];
        filteredFavorites = [];
        isLoading = false;
      });
      return;
    }

    // Todos los libros
    final allBooks = await BookController().fetchAllBooks();

    // Filtra los libros favoritos 
    final favorites = allBooks.where((book) => userFavoritesIds.contains(book['id'].toString())).toList();

    // Inicializamos el estado de los recordatorios
    List<bool> reminderStates = [];
    for (var book in favorites) {
      final reminders = await ReminderController().getRemindersByBookAndUser(book['id'], userId!);
      reminderStates.add(reminders.isNotEmpty);
    }

    setState(() {
      allFavorites = favorites;
      filteredFavorites = favorites;
      isReminderActiveList = reminderStates;
      isLoading = false;
    });
  }

  // Función para filtrar los libros
  void _filterByLetter(String letter) {
    setState(() {
      selectedLetter = letter;
      currentPage = 1;

      if (letter == '') {
        filteredFavorites = allFavorites;
      } else {
        filteredFavorites = allFavorites.where((book) {
          final title = (book['title'] ?? '').toString().toUpperCase();
          return title.startsWith(letter);
        }).toList();
      }
    });
  }

  // Función que maneja la letra seleccionada para el filtrado
  Future<void> _toggleReminder(int bookId, int index) async {
    final reminders = await ReminderController().getRemindersByBookAndUser(bookId, userId!);
    final isActive = reminders.isNotEmpty;

    final formats = (allFavorites[index]['format'] as String).split(',').map((f) => f.trim()).toList();

    setState(() {
      isReminderActiveList[index] = !isActive;
    });

    if (isActive) {
      // Elimina todos los recordatorios de ese libro para ese usuario
      for (final r in reminders) {
        await ReminderController().removeFromReminder(bookId, userId!, r.format);
      }
    } else {
      // Crea un recordatorio por cada formato disponible
      for (final format in formats) {
        await ReminderController().addReminder(bookId, userId!, format);
      }
    }

    // Actualizar visualmente la campana si todos los formatos están disponibles
    final allFormatsAvailable = await LoanController().areAllFormatsAvailable(bookId);
    if (allFormatsAvailable) {
      setState(() {
        isReminderActiveList[index] = false; // Cambia la campana a gris (inactiva)
      });
    }

    setState(() {});
  }


  @override
  Widget build(BuildContext context) {
    final startIndex = (currentPage - 1) * itemsPerPage;
    final endIndex = (startIndex + itemsPerPage).clamp(0, filteredFavorites.length);
    final paginatedFavorites = filteredFavorites.sublist(startIndex, endIndex);

    final totalPages = (filteredFavorites.length / itemsPerPage).ceil();

    return Scaffold(
      body: Background(
        title: 'Favoritos',
        showRowIcon: false,
        onBack: () => Navigator.pop(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            SizedBox(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  const SizedBox(width: 8),
                  _buildCircleFilter('All', ''),
                  ...List.generate(26, (index) {
                    final letter = String.fromCharCode(65 + index);
                    return _buildCircleFilter(letter, letter);
                  }),
                  const SizedBox(width: 8),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : paginatedFavorites.isEmpty
                  ? const Center(
                      child: Text(
                        'No hay libros seleccionados como favoritos.',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                    )
              
              : paginatedFavorites.isEmpty
                  ? const Center(
                      child: Text(
                        'No hay libros seleccionados como favoritos.',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                    )
                  : ListView.builder(
                      itemCount: paginatedFavorites.length,
                      itemBuilder: (context, index) {
                        final book = paginatedFavorites[index];

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BookDetailsOwnerView(bookId: book['id']),
                              ),
                            );
                          },
                          child: Card(
                            color: const Color(0xFFEAF0FB),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: Color(0xFF112363), width: 2),
                            ),
                            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            child: Stack(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          book['cover'] ?? '',
                                          width: 60,
                                          height: 90,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) =>
                                              const Icon(Icons.broken_image),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              book['title'] ?? 'Sin título',
                                              style: const TextStyle(
                                                  fontSize: 16, fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              book['author'] ?? 'Autor desconocido',
                                              style: const TextStyle(fontSize: 14),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Positioned(
                                  bottom: 8,
                                  right: 8,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      InkWell(
                                        onTap: () => _toggleReminder(book['id'], index),
                                        child: Icon(
                                          Icons.notifications,
                                          color: isReminderActiveList[index] ? Colors.amber : Colors.grey,
                                          size: 25,
                                        ),
                                      ),
                                      const SizedBox(width: 7),
                                      InkWell(
                                        onTap: () async {
                                          await UserController().removeFromFavorites(book['id']);
                                          await _loadFavorites();
                                        },
                                        child: const Icon(
                                          Icons.favorite,
                                          color: Colors.red,
                                          size: 25,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            if (totalPages > 1)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(totalPages, (index) {
                    final page = index + 1;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          currentPage = page;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: currentPage == page
                              ? const Color(0xFF112363)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF112363)),
                        ),
                        child: Text(
                          '$page',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: currentPage == page
                                ? Colors.white
                                : const Color(0xFF112363),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: Footer(
          selectedIndex: 0, 
          onItemTapped: (index) {
            switch (index) {
              case 0:
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HomeView()),
                );
                break;
              case 1:
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UserSearchView()),
                );
                break;
              case 2:
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const GeolocationMap()),
                );
                break;
              case 3:
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FavoritesView()),
                );
                break;
              case 4:
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => OwnerProfileView(userId: userId!)),
                );
                break;
            }
          },
        ),
    );
  }

  // Widget para construir el método de filtrado
  Widget _buildCircleFilter(String label, String value) {
    final isSelected = value == selectedLetter;

    return GestureDetector(
      onTap: () => _filterByLetter(value),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? const Color(0xFF112363) : Colors.transparent,
          border: Border.all(color: const Color(0xFF112363)),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : const Color(0xFF112363),
              fontSize: label.length > 1 ? 10 : 14,
            ),
          ),
        ),
      ),
    );
  }

}
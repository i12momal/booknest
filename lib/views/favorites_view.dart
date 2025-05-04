import 'package:booknest/controllers/account_controller.dart';
import 'package:booknest/controllers/book_controller.dart';
import 'package:booknest/controllers/user_controller.dart';
import 'package:booknest/views/book_details_owner_view.dart';
import 'package:booknest/views/home_view.dart';
import 'package:booknest/views/user_profile_view.dart';
import 'package:booknest/views/user_search_view.dart';
import 'package:booknest/widgets/background.dart';
import 'package:booknest/widgets/footer.dart';
import 'package:flutter/material.dart';

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

  int currentPage = 1;
  final int itemsPerPage = 20;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final id = await AccountController().getCurrentUserId();
    setState(() {
      userId = id;
    });
  }

  Future<void> _loadFavorites() async {
    final response = await UserController().getFavorites();
    
    // Verifica si la respuesta tiene los favoritos
    final userFavoritesIds = List<String>.from(response['favorites'] ?? []);
    
    // Si no hay favoritos, mostramos una lista vacía
    if (userFavoritesIds.isEmpty) {
      setState(() {
        allFavorites = [];
        filteredFavorites = [];
      });
      return;
    }

    // Todos los libros
    final allBooks = await BookController().fetchAllBooks();

    // Filtra los libros favoritos 
    final favorites = allBooks
        .where((book) => userFavoritesIds.contains(book['id'].toString()))
        .toList();

    setState(() {
      allFavorites = favorites;
      filteredFavorites = favorites;
    });
  }


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
              child: paginatedFavorites.isEmpty
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
                                  child: IconButton(
                                    icon: const Icon(Icons.favorite, color: Colors.red),
                                    onPressed: () async {
                                      await UserController()
                                          .removeFromFavorites(book['id']);
                                      await _loadFavorites(); // Refresca la vista
                                    },
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
        selectedIndex: 3,
        onItemTapped: (index) {
          switch (index) {
            case 0:
              Navigator.push(context, MaterialPageRoute(builder: (context) => const HomeView()));
              break;
            case 1:
              Navigator.push(context, MaterialPageRoute(builder: (context) => const UserSearchView()));
              break;
            case 2:
              Navigator.push(context, MaterialPageRoute(builder: (context) => const HomeView()));
              break;
            case 3:
              Navigator.push(context, MaterialPageRoute(builder: (context) => const FavoritesView()));
              break;
            case 4:
              Navigator.push(context, MaterialPageRoute(builder: (context) => UserProfileView(userId: userId!)));
              break;
          }
        },
      ),
    );
  }

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

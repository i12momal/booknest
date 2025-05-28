import 'package:booknest/controllers/account_controller.dart';
import 'package:booknest/controllers/book_controller.dart';
import 'package:booknest/controllers/loan_controller.dart';
import 'package:booknest/entities/models/book_model.dart';
import 'package:booknest/views/book_details_owner_view.dart';
import 'package:booknest/views/favorites_view.dart';
import 'package:booknest/views/geolocation_view.dart';
import 'package:booknest/views/home_view.dart';
import 'package:booknest/views/owner_profile_view.dart';
import 'package:booknest/views/user_search_view.dart';
import 'package:booknest/widgets/background.dart';
import 'package:booknest/widgets/footer.dart';
import 'package:flutter/material.dart';

class CategoryView extends StatefulWidget {
  final String categoryName;
  final String categoryImageUrl;
  final String userId;

  const CategoryView({
    super.key,
    required this.categoryName,
    required this.categoryImageUrl,
    required this.userId,
  });

  @override
  State<CategoryView> createState() => _CategoryViewState();
}

class _CategoryViewState extends State<CategoryView> {
  bool _isLoading = true;
  String _message = '';
  List<Book> _allFilteredBooks = [];
  List<Book> _books = [];
  final BookController _bookController = BookController();
  final LoanController _loanController = LoanController();

  int _currentPage = 1;
  final int _booksPerPage = 20;

  @override
  void initState() {
    super.initState();
    _fetchBooksByCategory();
  }

  Future<void> _fetchBooksByCategory() async {
    try {
      final books = await _bookController.getUserBooksByCategory(widget.userId, widget.categoryName);
      final filteredBooks = books.where((book) {
        final bookCategories = book.categories.split(',').map((e) => e.trim()).toList();
        return bookCategories.contains(widget.categoryName);
      }).toList();

      setState(() {
        _allFilteredBooks = filteredBooks;
        _books = _paginateBooks();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _message = 'Error al obtener los libros.';
        _isLoading = false;
      });
    }
  }

  List<Book> _paginateBooks() {
    final start = (_currentPage - 1) * _booksPerPage;
    final end = (start + _booksPerPage).clamp(0, _allFilteredBooks.length);
    return _allFilteredBooks.sublist(start, end);
  }

  void _changePage(int page) {
    setState(() {
      _currentPage = page;
      _books = _paginateBooks();
    });
  }

  void _removeBook(int bookId) {
    setState(() {
      // Eliminamos el libro de la lista de libros filtrados
      _allFilteredBooks.removeWhere((b) => b.id == bookId);

      // Ajustamos la paginación
      if (_currentPage > _totalPages) {
        _currentPage = _totalPages;
      }

      _books = _paginateBooks();
    });
  }

  int get _totalPages => (_allFilteredBooks.length / _booksPerPage).ceil().clamp(1, double.infinity).toInt();

  int _calculateCrossAxisCount(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth >= 1200) return 7;
    if (screenWidth >= 900) return 6;
    if (screenWidth >= 600) return 5;
    if (screenWidth >= 400) return 4;
    return 3;
  }

  String getAvailabilityStatus(Book book, List<String> loanedFormats) {
    final List<String> formats = book.format
        .split(',')
        .map((f) => f.trim().toLowerCase())
        .where((f) => f.isNotEmpty)
        .toList();

    final List<String> disponibles = formats
        .where((format) => !loanedFormats.map((f) => f.toLowerCase()).contains(format))
        .toList();

    if (disponibles.isEmpty) {
      return 'Prestado';
    } else if (disponibles.length == formats.length) {
      return 'Disponible';
    } else if (disponibles.length == 1) {
      final formatCapitalized = disponibles.first[0].toUpperCase() + disponibles.first.substring(1);
      return formatCapitalized;
    } else {
      if (disponibles.contains('físico') && !disponibles.contains('digital')) {
        return 'Físico';
      } else if (disponibles.contains('digital') && !disponibles.contains('físico')) {
        return 'Digital';
      } else {
        return 'Disponible';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: AccountController().getCurrentUserId(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return const Scaffold(
            body: Center(child: Text("Error al cargar el usuario")),
          );
        }

        final currentUserId = snapshot.data!;

        return Scaffold(
          body: Background(
            title: widget.categoryName,
            onBack: () => Navigator.pop(context),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _message.isNotEmpty
                    ? Center(child: Text(_message))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: NetworkImage(widget.categoryImageUrl),
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          const SizedBox(height: 25),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Center(
                              child: Text(
                                'Libros en esta categoría',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF112363),
                                ),
                              ),
                            ),
                          ),
                          const Divider(thickness: 1, color: Color(0xFF112363)),
                          const SizedBox(height: 8),
                          Expanded(
                            child: _books.isEmpty
                                ? const Center(
                                    child: Text(
                                      "No se encontraron libros.",
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                                    ),
                                  )
                                : GridView.builder(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: _calculateCrossAxisCount(context),
                                      crossAxisSpacing: 8,
                                      mainAxisSpacing: 8,
                                      childAspectRatio: 0.5,
                                    ),
                                    itemCount: _books.length,
                                    itemBuilder: (context, index) {
                                      final book = _books[index];
                                      return FutureBuilder<List<String>>(
                                        future: _loanController.fetchLoanedFormats(book.id),
                                        builder: (context, snapshot) {
                                          if (!snapshot.hasData) {
                                            return const Center(child: CircularProgressIndicator(strokeWidth: 1));
                                          }

                                          final loanedFormats = snapshot.data!;
                                          final status = getAvailabilityStatus(book, loanedFormats);
                                          final normalizedStatus = status.trim().toLowerCase();
                      
                                          Icon statusIcon;
                                          if (normalizedStatus == 'disponible') {
                                            statusIcon = const Icon(Icons.check_circle, color: Colors.green, size: 20);
                                          } else if (normalizedStatus == 'prestado') {
                                            statusIcon = const Icon(Icons.cancel, color: Colors.red, size: 20);
                                          } else {
                                            statusIcon = const Icon(Icons.check_circle, color: Colors.orange, size: 20);
                                          }

                                          return GestureDetector(
                                            onTap: () async {
                                              final deletedBookId = await Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => BookDetailsOwnerView(bookId: book.id),
                                                ),
                                              );
                                              if (deletedBookId != null && deletedBookId is int) {
                                                _removeBook(deletedBookId);
                                              }
                                            },
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Stack(
                                                  alignment: Alignment.topRight,
                                                  children: [
                                                    ClipRRect(
                                                      borderRadius: BorderRadius.circular(8),
                                                      child: AspectRatio(
                                                        aspectRatio: 0.7,
                                                        child: Image.network(
                                                          book.cover,
                                                          fit: BoxFit.cover,
                                                          errorBuilder: (context, error, stackTrace) =>
                                                              const Icon(Icons.broken_image),
                                                        ),
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding: const EdgeInsets.all(4.0),
                                                      child: statusIcon,
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  book.title,
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      );

                                    },
                                  ),
                          ),
                          if (_totalPages > 1)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(_totalPages, (index) {
                                  final pageNum = index + 1;
                                  return GestureDetector(
                                    onTap: () => _changePage(pageNum),
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 4),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: _currentPage == pageNum
                                            ? const Color(0xFF112363)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '$pageNum',
                                        style: TextStyle(
                                          color: _currentPage == pageNum ? Colors.white : Colors.black,
                                          fontWeight: FontWeight.bold,
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
                    MaterialPageRoute(builder: (context) => OwnerProfileView(userId: currentUserId)),
                  );
                  break;
              }
            },
          ),
        );
      },
    );
  }
}

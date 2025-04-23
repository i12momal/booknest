import 'package:booknest/controllers/book_controller.dart';
import 'package:booknest/entities/models/book_model.dart';
import 'package:booknest/views/book_details_owner_view.dart';
import 'package:booknest/widgets/background.dart';
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
  List<Book> _books = [];
  final BookController _bookController = BookController();

  // Paginación
  int _currentPage = 1;
  final int _booksPerPage = 20;
  int _totalBooks = 0;

  @override
  void initState() {
    super.initState();
    _fetchBooksByCategory();
  }

  // Función para obtener los libros filtrados por categoría y paginados
  Future<void> _fetchBooksByCategory() async {
    try {
      final books = await _bookController.getUserBooksByCategory(widget.userId, widget.categoryName);
      final filteredBooks = books.where((book) {
        List<String> bookCategories = book.categories.split(',').map((e) => e.trim()).toList();  // Elimina los espacios
        return bookCategories.contains(widget.categoryName);
      }).toList();

      setState(() {
        _totalBooks = filteredBooks.length;
        _books = _paginateBooks(filteredBooks);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _message = 'Error al obtener los libros.';
        _isLoading = false;
      });
    }
  }

  // Función para dividir los libros en páginas
  List<Book> _paginateBooks(List<Book> books) {
    final start = (_currentPage - 1) * _booksPerPage;
    final end = (start + _booksPerPage).clamp(0, books.length);
    return books.sublist(start, end);
  }

  // Función para cambiar de página
  void _changePage(int page) {
    setState(() {
      _currentPage = page;
      _books = _paginateBooks(_books);
    });
  }

  int _calculateCrossAxisCount(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth >= 1200) return 7;
    if (screenWidth >= 900) return 6;
    if (screenWidth >= 600) return 5;
    if (screenWidth >= 400) return 4;
    return 3;
  }

  // Función para calcular el número total de páginas
  int get _totalPages {
    return (_totalBooks / _booksPerPage).ceil();
  }

  @override
  Widget build(BuildContext context) {
    return Background(
      title: widget.categoryName,
      onBack: () => Navigator.pop(context),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _message.isNotEmpty
              ? Center(child: Text(_message))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Imagen de la categoría
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
                                return GestureDetector(
                                  onTap: () {
                                    // Navegar a la página de detalles del libro
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => BookDetailsOwnerView(bookId: book.id),
                                      ),
                                    );
                                  },
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
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
                                      const SizedBox(height: 6),
                                      Text(
                                        book.title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),

                    // Paginación
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
    );
  }
}

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:booknest/widgets/background.dart';
import '../controllers/home_controller.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final HomeController _controller = HomeController();
  List<Map<String, dynamic>> categories = [];
  String? selectedCategory;

  // Lista de libros (simulados con categoría incluida)
  final List<Map<String, dynamic>> allBooks = List.generate(80, (index) {
    final genres = ['Misterio', 'Amor', 'Policíaca', 'Terror', 'Fantasía'];
    return {
      'image': 'assets/harry${index % 8}.jpg',
      'genre': genres[index % genres.length],
    };
  });

  List<Map<String, dynamic>> filteredBooks = [];
  int currentPage = 1;
  final int booksPerPage = 20;

  @override
  void initState() {
    super.initState();
    _loadCategoriesAndBooks();
  }

  Future<void> _loadCategoriesAndBooks() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      final userCategories = await _controller.loadUserGenres(userId);

      final categoryNames = userCategories.map((c) => c['name'].toString()).toList();

      final books = await _controller.loadBooksByUserCategories(categoryNames);

      setState(() {
        categories = userCategories;
        filteredBooks = books;
        currentPage = 1;
      });
    }
  }

  void _toggleCategory(String category) {
    setState(() {
      if (selectedCategory == category) {
        // Deseleccionamos
        selectedCategory = null;
        filteredBooks = allBooks.where((book) => categories.contains(book['genre'])).toList();
      } else {
        // Seleccionamos una categoría específica
        selectedCategory = category;
        filteredBooks = allBooks.where((book) => book['genre'] == category).toList();
      }
      currentPage = 1;
    });
  }

  List<Map<String, dynamic>> get currentBooks {
    final start = (currentPage - 1) * booksPerPage;
    final end = (start + booksPerPage).clamp(0, filteredBooks.length);
    return filteredBooks.sublist(start, end);
  }

  int get totalPages => (filteredBooks.length / booksPerPage).ceil();

  @override
  Widget build(BuildContext context) {
    return Background(
      title: 'BookNest',
      onBack: null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Buscador
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar por Título o Autor',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: Color(0xFF112363), width: 2),
                ),
              ),
            ),
          ),

          // Categorías
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Text("Categorías", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                Spacer(),
                Icon(Icons.add_circle_outline),
              ],
            ),
          ),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = selectedCategory == category['name'];

                return GestureDetector(
                  onTap: () => _toggleCategory(category['name']),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.grey.withAlpha((0.1 * 255).toInt()) : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Colors.grey.withAlpha((0.1 * 255).toInt()),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              )
                            ]
                          : [],
                    ),
                    child: Column(
                      children: [
                        Transform.scale(
                          scale: isSelected ? 1.1 : 1.0,
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Colors.grey : const Color(0xFF112363),
                                width: 2,
                              ),
                            ),
                            child: ClipOval(
                              child: Image.network(
                                category['image'],
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                           category['name'],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                );

              },
            ),
          ),

          const SizedBox(height: 25),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text("Libros relacionados", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          ),

          // Lista de libros
          Expanded(
            child: GridView.builder(
              itemCount: currentBooks.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.7,
              ),
              itemBuilder: (context, index) {
                return Image.asset(currentBooks[index]['image'], fit: BoxFit.cover);
              },
            ),
          ),

          // Paginación
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(totalPages, (index) {
                final pageNum = index + 1;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      currentPage = pageNum;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: currentPage == pageNum ? const Color(0xFF112363) : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$pageNum',
                      style: TextStyle(
                        color: currentPage == pageNum ? Colors.white : Colors.black,
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

import 'package:booknest/controllers/categories_controller.dart';
import 'package:booknest/widgets/category_selection_popup.dart';
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
  final TextEditingController _searchController = TextEditingController();

  List<String> allCategories = [];

  List<Map<String, dynamic>> filteredBooks = [];
  int currentPage = 1;
  final int booksPerPage = 20;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategoriesAndBooks();
  }

  List<Map<String, dynamic>> allLoadedBooks = [];
  List<Map<String, dynamic>> allCategoryBooks = []; 

  // Función de búsqueda de libros por título o autor
  Future<void> _searchBooks(String query) async {
    final normalizedQuery = _controller.normalize(query);

    final filtered = allCategoryBooks.where((book) {
      final title = _controller.normalize(book['title'] ?? '');
      final author = _controller.normalize(book['author'] ?? '');
      return title.contains(normalizedQuery) || author.contains(normalizedQuery);
    }).toList();

    setState(() {
      filteredBooks = query.isEmpty ? allCategoryBooks : filtered;
    });
  }

  Future<void> _loadCategoriesAndBooks() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {

      setState(() {
        isLoading = true;
      });

      await Future.delayed(const Duration(milliseconds: 1515));

      final userCategories = await _controller.loadUserGenres(userId);
      final categoryNames = userCategories.map((c) => c['name'].toString()).toList();

      // Aquí cargamos todas las categorías del sistema
      final systemCategories = await CategoriesController().getCategories();
      final books = await _controller.loadBooksByUserCategories(categoryNames);

      setState(() {
        categories = userCategories;
        allCategories = systemCategories;
        allCategoryBooks = books;
        filteredBooks = books;
        selectedCategory = null;
        currentPage = 1;
        isLoading = false;
      });
    }
  }

  int _calculateCrossAxisCount(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth >= 1200) return 7; // pantallas grandes
    if (screenWidth >= 900) return 6;
    if (screenWidth >= 600) return 5;
    if (screenWidth >= 400) return 4;
    return 3; // móvil pequeño
  }

  void _showCategorySelectionPopup(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 5,
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.5,
          child: CategorySelectionPopup(
            allCategories: allCategories,
            selectedCategories: categories.map((c) => c['name'].toString()).toList(),
            onSave: (newSelectedCategories) async {
              Navigator.pop(context); // Cierra el popup primero

              setState(() {
                isLoading = true; // Muestra el loader
              });

              final userId = Supabase.instance.client.auth.currentUser?.id;
              if (userId != null) {
                // Guarda las nuevas categorías en el campo 'genres'
                final genresString = newSelectedCategories.join(',');
                await Supabase.instance.client
                    .from('User')
                    .update({'genres': genresString})
                    .eq('id', userId);

                // Recarga las categorías y los libros
                await _loadCategoriesAndBooks();
              }

              setState(() {
                isLoading = false; // Oculta el loader
              });
            },
          ),
        ),
      );
    },
  );
}



  void _toggleCategory(String category) {
    setState(() {
      if (selectedCategory == category) {
        // Deseleccionamos → volver a mostrar todos los libros relacionados con las categorías del usuario
        selectedCategory = null;
        filteredBooks = allCategoryBooks;
      } else {
        // Seleccionamos una categoría específica
        selectedCategory = category;
       filteredBooks = allCategoryBooks.where((book) => (book['categories'] as String).toLowerCase().contains(category.toLowerCase())).toList();
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

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus(); // Oculta el teclado
      },
      child: Background(
        title: 'BookNest',
        onBack: null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if(isLoading)...[
              Center(
                 child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/gifs/cargando.gif', height: 500, width: 500),
                    const SizedBox(height: 10),
                    const Text(
                      'Cargando...',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF112363)),
                    ),
                  ],
                ),
              )
            ]else...[
              // Buscador
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar por Título o Autor',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: Color(0xFF112363), width: 2),
                    ),
                  ),
                  onChanged: (query) {
                    _searchBooks(query);
                  },
                ),
              ),
            
              // Categorías
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Text("Categorías", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () {
                        _showCategorySelectionPopup(context);
                      },
                    )
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
              const Divider(thickness: 1, color: Color(0xFF112363)),

              // Lista de libros
              Expanded(
                child: filteredBooks.isEmpty
                ? const Center(
                    child: Text(
                      "No se encontraron libros.",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  )
                : GridView.builder(
                  itemCount: currentBooks.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _calculateCrossAxisCount(context),
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.5,
                  ),
                  itemBuilder: (context, index) {
                    final book = currentBooks[index];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: AspectRatio(
                            aspectRatio: 0.7,
                            child: Image.network(
                              book['cover'], // asegúrate de que este campo exista
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.broken_image),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          book['title'] ?? 'Sin título',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ],
                    );

                  }
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
          ],
        ),
      ),
    );


  }
}
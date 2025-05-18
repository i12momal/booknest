import 'package:booknest/controllers/account_controller.dart';
import 'package:booknest/controllers/categories_controller.dart';
import 'package:booknest/views/book_details_owner_view.dart';
import 'package:booknest/views/favorites_view.dart';
import 'package:booknest/views/geolocation_view.dart';
import 'package:booknest/views/owner_profile_view.dart';
import 'package:booknest/views/user_search_view.dart';
import 'package:booknest/widgets/book_format_dropdown.dart';
import 'package:booknest/widgets/category_selection_popup.dart';
import 'package:booknest/widgets/footer.dart';
import 'package:booknest/widgets/language_dropdown.dart';
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
  final TextEditingController _languageFilterController = TextEditingController();
  final TextEditingController _formatFilterController = TextEditingController();

  List<String> allCategories = [];

  List<Map<String, dynamic>> filteredBooks = [];
  int currentPage = 1;
  final int booksPerPage = 20;

  bool isLoading = true;
  String? userId;

  @override
  void initState() {
    super.initState();
    _loadCategoriesAndBooks();
    _loadUserId();
  }

  List<Map<String, dynamic>> allLoadedBooks = [];
  List<Map<String, dynamic>> allCategoryBooks = []; 
  List<Map<String, dynamic>> allBooksIncludingUnavailable = [];

  String? selectedLanguage;
  String? selectedFormat;

  Future<void> _loadCategoriesAndBooks() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      setState(() {
        isLoading = true;
      });

      final userCategories = await _controller.loadUserGenres(userId);
      final categoryNames = userCategories.map((c) => c['name'].toString()).toList();

      // Aquí cargamos todas las categorías del sistema
      final systemCategories = await CategoriesController().getCategories();
      final books = await _controller.loadBooksByUserCategories(categoryNames);
      
      final allBooks = await _controller.loadAllBooks();
      final allBooksRaw = await _controller.loadAllBooks(includeUnavailable: true);

      // Filtrar los libros para excluir los del usuario actual
      final filteredBooks = allBooks.where((book) {
        return book['owner_id'] != userId;
      }).toList();

      setState(() {
        categories = userCategories;
        allCategories = systemCategories;
        allCategoryBooks = books;
        this.filteredBooks = filteredBooks;
        selectedCategory = null;
        currentPage = 1;
        isLoading = false;
        allLoadedBooks = filteredBooks;
        allBooksIncludingUnavailable = allBooksRaw;
      });
    }
  }

  // Función de búsqueda de libros por título o autor
  Future<void> _searchBooks(String query) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    final normalizedQuery = _controller.normalize(query);

    final filtered = allBooksIncludingUnavailable.where((book) {
      final title = _controller.normalize(book['title']?.toString() ?? '');
      final author = _controller.normalize(book['author']?.toString() ?? '');
      final ownerId = book['owner_id'];

      // Ignorar libros del usuario actual
      if (ownerId == userId) return false;

      return title.contains(normalizedQuery) || author.contains(normalizedQuery);
    }).toList();

    setState(() {
      filteredBooks = query.isEmpty ? allLoadedBooks : filtered;
    });
  }


  Future<void> _loadUserId() async {
    final id = await AccountController().getCurrentUserId();
    setState(() {
      userId = id;
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

  void _showLanguageFilterPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFF112363), width: 3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Filtrar por idioma',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF112363),
                  ),
                ),
                const SizedBox(height: 16),
                LanguageDropdown(
                  controller: _languageFilterController,
                  languages: const ['All', 'Español', 'Inglés', 'Francés', 'Alemán', 'Italiano','Portugués', 'Ruso', 'Chino', 'Japonés', 'Coreano', 'Árabe','Otro'],
                  onChanged: (selected) {
                    if (selected == 'All') {
                      selectedLanguage = null;
                      _languageFilterController.clear();
                    } else {
                      selectedLanguage = selected;
                      _languageFilterController.text = selected!;
                    }
                  },
                ),
                const SizedBox(height: 20),
                const Text(
                  'Filtrar por formato',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF112363),
                  ),
                ),
                const SizedBox(height: 16),
                BookFormatDropdown(
                  controller: _formatFilterController,
                  formats: const ['All', 'Físico', 'Digital'],
                  onChanged: (selected) {
                    if (selected == 'All') {
                      selectedFormat = null;
                      _formatFilterController.clear();
                    } else {
                      selectedFormat = selected;
                      _formatFilterController.text = selected!;
                    }
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _applyFilters();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFAD0000),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                      side: const BorderSide(color: Color(0xFF700101), width: 3),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  ),
                  child: const Text(
                    'Aplicar filtro', 
                    style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),),
                ),
              ],
            ),
          ),
        );
      },
    );
  }



  void _applyFilters() {
    List<Map<String, dynamic>> books = selectedCategory != null
        ? allCategoryBooks.where((book) {
            return (book['categories'] as String).toLowerCase().contains(selectedCategory!.toLowerCase()) &&
                  book['owner_id'] != userId;
          }).toList()
        : allLoadedBooks;

    if (selectedLanguage != null) {
      books = books.where((book) {
        final bookLanguage = book['language']?.toString().toLowerCase() ?? '';
        return bookLanguage == selectedLanguage!.toLowerCase();
      }).toList();
    }

    if (selectedFormat != null) {
      books = books.where((book) {
        final bookFormat = book['format']?.toString().toLowerCase() ?? '';
        return bookFormat.split(',').map((f) => f.trim()).contains(selectedFormat!.toLowerCase());
      }).toList();
    }


    setState(() {
      filteredBooks = books;
      currentPage = 1;
    });
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
                  isLoading = false;
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
        selectedCategory = null;
        filteredBooks = allLoadedBooks.where((book) {
          return book['owner_id'] != Supabase.instance.client.auth.currentUser?.id; 
        }).toList();
      } else {
        // Seleccionamos una categoría específica
        selectedCategory = category;
        filteredBooks = allCategoryBooks.where((book) {
          return (book['categories'] as String).toLowerCase().contains(category.toLowerCase()) &&
                book['owner_id'] != Supabase.instance.client.auth.currentUser?.id;
        }).toList();
      }
      currentPage = 1;
    });
  }


  List<Map<String, dynamic>> get currentBooks {
    final start = (currentPage - 1) * booksPerPage;
    final end = (start + booksPerPage).clamp(0, filteredBooks.length);

    if (start >= filteredBooks.length) return [];
    return filteredBooks.sublist(start, end);
  }


  int get totalPages => (filteredBooks.length / booksPerPage).ceil();

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Scaffold(
          body: Background(
            title: 'BookNest',
            onBack: null,
            showChatIcon: true,
            showRowIcon: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isLoading)...[
                  const Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 100,
                            width: 100,
                            child: CircularProgressIndicator(
                              color: Color(0xFF112363),
                            ),
                          ),
                          SizedBox(height: 20),
                          Text(
                            'Cargando...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF112363),
                            ),
                          ),
                        ],
                      ),
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

                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Text(
                          "Libros relacionados",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.filter_alt_outlined, color: Color(0xFF112363)),
                          tooltip: 'Filtrar por idioma',
                          onPressed: () => _showLanguageFilterPopup(context),
                        ),
                      ],
                    ),
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
                        return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BookDetailsOwnerView(bookId: book['id']),
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
                                  book['cover'],
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
                        ),
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
        ),
      )
    );
  }


}
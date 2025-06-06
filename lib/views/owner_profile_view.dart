import 'package:booknest/controllers/account_controller.dart';
import 'package:booknest/controllers/book_controller.dart';
import 'package:booknest/controllers/geolocation_controller.dart';
import 'package:booknest/controllers/loan_controller.dart';
import 'package:booknest/controllers/user_controller.dart';
import 'package:booknest/entities/models/book_model.dart';
import 'package:booknest/entities/models/category_model.dart';
import 'package:booknest/entities/models/user_model.dart';
import 'package:booknest/views/add_book_view.dart';
import 'package:booknest/views/book_details_owner_view.dart';
import 'package:booknest/views/book_reader_view.dart';
import 'package:booknest/views/category_view.dart';
import 'package:booknest/views/edit_user_view.dart';
import 'package:booknest/views/favorites_view.dart';
import 'package:booknest/views/geolocation_view.dart';
import 'package:booknest/views/home_view.dart';
import 'package:booknest/views/login_view.dart';
import 'package:booknest/views/user_search_view.dart';
import 'package:booknest/widgets/background.dart';
import 'package:booknest/widgets/footer.dart';
import 'package:booknest/widgets/success_dialog.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' as kisweb;
import 'package:universal_html/html.dart' as html;
import 'package:http/http.dart' as http;

// Vista para las acciones del Perfil del Usuario Propietario
class OwnerProfileView extends StatefulWidget {
  final String userId;
  const OwnerProfileView({super.key, required this.userId});

  @override
  State<OwnerProfileView> createState() => _OwnerProfileViewState();
}

class _OwnerProfileViewState extends State<OwnerProfileView> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? currentImageUrl;

  List<Category> categories = [];
  bool _isLoading = false;
  String _message = '';

  bool _isReturning = false;

  final UserController _userController = UserController();

  List<Map<String, dynamic>> activeLoans = [];

  final TextEditingController _searchController = TextEditingController();
  final BookController _bookController = BookController();
  List<Book> filteredBooks = [];

  bool _isLocationEnabled = false;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _fetchUserGeolocation();
    _fetchUserCategoriesFromBooks();
    _fetchActiveLoans();
  }

  // Método para cargar los datos del usuario
  Future<void> _fetchUserData() async {
    setState(() {
      _isLoading = true;
      _message = '';
    });

    try {
      final User? userData = await _userController.getUserById(widget.userId);
      
      if (userData != null) {
        setState(() {
          _nameController.text = userData.name;
          _emailController.text = userData.email;
          _descriptionController.text = userData.description!;
          _phoneNumberController.text = userData.phoneNumber.toString();
          currentImageUrl = userData.image ?? '';
          _isLoading = false;
        });
      } else {
        setState(() {
          _message = 'No se encontró la información del usuario. Por favor, intente nuevamente.';
          _isLoading = false;
        });
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (context) => const LoginView()));
          }
        });
      }
    } catch (e) {
      setState(() {
        _message = 'Error al cargar los datos del usuario. Por favor, intente nuevamente.';
        _isLoading = false;
      });
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => const LoginView()));
        }
      });
    }
  }

  // Método para compronar si el usuario tiene la geolocalización activa
  Future<void> _fetchUserGeolocation() async {
    try {
      final isEnabled = await GeolocationController().isUserGeolocationEnabled(widget.userId);
      setState(() {
        _isLocationEnabled = isEnabled;
      });
    } catch (e) {
      print("Error en _fetchUserGeolocation: $e");
    }
  }

  // Método para obtener las categorías del usuario que tienen libros creados.
  void _fetchUserCategoriesFromBooks() async {
    try {
      final categoriesFromBooks =
          await _userController.getCategoriesFromBooks(widget.userId);
      setState(() {
        categories = categoriesFromBooks;
      });
    } catch (e) {
      setState(() {
        _message = 'Error al cargar las categorías de los libros.';
      });
    }
  }

  // Método para obtener los libros obtenidos de préstamo
  Future<void> _fetchActiveLoans() async {
    try {
      final userId = await AccountController().getCurrentUserId();
      if (userId == null) return;

      final rawLoans = await LoanController().getLoansByHolder(userId);

      List<Map<String, dynamic>> loansWithBooks = [];

      for (var loan in rawLoans) {
        final bookId = loan['bookId'];
        final book = await BookController().getBookById(bookId);

        if (book != null) {
          loansWithBooks.add({
            'loan': loan,
            'book': book,
            'currentPage': loan['currentPage'],
          });
        }
      }

      setState(() {
        activeLoans = loansWithBooks;
      });
    } catch (e) {
      print('Error fetching active loans: $e');
    }
  }

  // Función que muestra un diálogo de éxito de devolución de un libro digital.
  void _showSuccessDialog() {
    SuccessDialog.show(
      context,
      'Devolución Exitosa',
      '¡Tu libro ha sido devuelto con éxito!',
      () {},
    );
  }

  // Función que muestra un diálogo de error de devolución de un libro digital.
  void _showErrorDialog() {
    SuccessDialog.show(
      context,
      'Error en la devolución',
      'Ha ocurrido un error en la devolución del libro.',
      () {},
    );
  }

  // // Función que muestra un diálogo de confirmación de devolución de un libro digital.
  Future<bool?> _showConfirmDialog(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar devolución'),
        content: const Text('¿Estás seguro de que quieres devolver este libro?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Devolver'),
          ),
        ],
      ),
    );
  }

  // Método para devolver un libro digital
  void _returnBook(int loanId) async {
    setState(() {
      _isReturning = true;
    });

    try {
      await LoanController().updateLoanState(loanId, 'Devuelto');
      await _fetchActiveLoans();
      _showSuccessDialog();
    } catch (e) {
      print('Error al devolver el libro: $e');
      _showErrorDialog();
    } finally {
      setState(() {
        _isReturning = false;
      });
    }
  }

  // Función para buscar un libro del usuario
  Future<void> _searchBooks(String query, Function setState) async {
    final userId = await AccountController().getCurrentUserId();

    // Recuperamos los libros del propietario
    final userBooks = await _bookController.getUserBooks(userId!);

    // Normalizamos el query para hacer la búsqueda insensible a mayúsculas/minúsculas
    final normalizedQuery = query.toLowerCase();

    // Filtramos los libros del propietario según el título o autor
    final filtered = userBooks.where((book) {
      final title = (book.title).toString().toLowerCase();
      final author = (book.author).toString().toLowerCase();
      return title.contains(normalizedQuery) || author.contains(normalizedQuery);
    }).toList();

    // Actualizamos el estado del widget para reflejar los resultados filtrados
    setState(() {
      filteredBooks = query.isEmpty ? userBooks : filtered;
    });
  }

  // Función que muestra el diálogo de búsqueda de libros del usuario.
  void _showSearchDialog(BuildContext context) {
    _searchController.clear();
    filteredBooks.clear();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Colors.white,
          child: Container(
            width: 500,
            height: 400,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF112363), width: 3),
            ),
            child: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    const SizedBox(height: 15),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
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
                          _searchBooks(query, setState);
                        },
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            if (_searchController.text.isEmpty)
                              const SizedBox.shrink(),
                            if (filteredBooks.isEmpty && _searchController.text.isNotEmpty)
                              const Center(child: Text('No se encontraron resultados.')),
                            if (filteredBooks.isNotEmpty)
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: filteredBooks.length,
                                itemBuilder: (context, index) {
                                  final book = filteredBooks[index];
                                  return ListTile(
                                    leading: Image.network(
                                      book.cover,
                                      width: 40,
                                      height: 60,
                                      fit: BoxFit.cover,
                                    ),
                                    title: Text(book.title),
                                    subtitle: Text(book.author),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => BookDetailsOwnerView(bookId: book.id)),
                                      );
                                    },
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  // Función para obtener la ruta relativa de un archivo a partir de su url pública
  String getRelativePathFromUrl(String url) {
    final uri = Uri.parse(url);
    final segments = uri.pathSegments;

    final publicIndex = segments.indexOf('public');
    final relativeSegments = segments.sublist(publicIndex + 2); // saltar 'public' y 'books'

    return relativeSegments.join('/');
  }



  @override
  Widget build(BuildContext context) {
    final hasDescription = _descriptionController.text.trim().isNotEmpty &&
        _descriptionController.text.trim().toLowerCase() != 'null';

    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 100,
                width: 100,
                child: CircularProgressIndicator(color: Color(0xFF112363)),
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
      );
    }

    if (_message.isNotEmpty) {
      return Scaffold(
        body: Center(child: Text(_message)),
      );
    }

    return Scaffold(
      body: Background(
        showExitIcon: false,
        showRowIcon: false,
        title: 'Mi Perfil',
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 40),
              Row(
                crossAxisAlignment: hasDescription ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.black12,
                    backgroundImage: currentImageUrl != null && currentImageUrl!.isNotEmpty
                        ? NetworkImage(currentImageUrl!)
                        : const AssetImage('assets/images/default.png') as ImageProvider,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditUserView(userId: widget.userId),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF112363)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _nameController.text,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            const SizedBox(height: 4),
                            if (hasDescription)
                              Row(
                                children: [
                                  Expanded(child: Text(_descriptionController.text)),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text(
                    'Ubicación',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 8),
                  Switch(
                    value: _isLocationEnabled,
                    onChanged: (bool newValue) async {
                      setState(() {
                        _isLocationEnabled = newValue;
                      });
                      await GeolocationController().updateUserGeolocation(widget.userId, newValue);
                    },
                    activeColor: const Color(0xFF112363),
                  ),
                ],
              ),
              const SizedBox(height: 50),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Center(
                      child: Text(
                        'Mi Biblioteca',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.search, color: Colors.black),
                            onPressed: () => _showSearchDialog(context),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline, color: Colors.black),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const AddBookView(origin: 'profile')),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(thickness: 1, color: Color(0xFF112363)),
              const SizedBox(height: 8),

              // Biblioteca responsive
              SizedBox(
                height: categories.isEmpty
                    ? 100
                    : isMobile
                        ? (categories.length > 4 ? 200 : 100)
                        : 220,
                child: categories.isEmpty
                    ? const Center(child: Text('No tiene libros subidos actualmente.'))
                    : isMobile
                        ? (categories.length > 4
                            ? GridView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: categories.length,
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 20,
                                  childAspectRatio: 0.8,
                                ),
                                itemBuilder: (context, index) {
                                  final category = categories[index];
                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => CategoryView(
                                            categoryName: category.name,
                                            categoryImageUrl: category.image,
                                            userId: widget.userId,
                                          ),
                                        ),
                                      );
                                    },
                                    child: _CategoryItem(
                                      label: category.name,
                                      imageUrl: category.image,
                                    ),
                                  );
                                },
                              )
                            : SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: categories.map((category) {
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 20),
                                      child: GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => CategoryView(
                                                categoryName: category.name,
                                                categoryImageUrl: category.image,
                                                userId: widget.userId,
                                              ),
                                            ),
                                          );
                                        },
                                        child: _CategoryItem(
                                          label: category.name,
                                          imageUrl: category.image,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ))
                        : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 220),
                              child: Wrap(
                                spacing: 20,
                                runSpacing: 20,
                                children: categories.map((category) {
                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => CategoryView(
                                            categoryName: category.name,
                                            categoryImageUrl: category.image,
                                            userId: widget.userId,
                                          ),
                                        ),
                                      );
                                    },
                                    child: _CategoryItem(
                                      label: category.name,
                                      imageUrl: category.image,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
              ),

              const SizedBox(height: 20),
              const Text('Prestados', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              const Divider(thickness: 1, color: Color(0xFF112363)),
              SizedBox(
                height: 250,
                child: activeLoans.isEmpty
                    ? const Center(child: Text('No tienes libros prestados actualmente.'))
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: activeLoans.length,
                        itemBuilder: (context, index) {
                          final loanData = activeLoans[index]['loan'];
                          final book = activeLoans[index]['book'];
                          final currentPage = loanData['currentPage'] ?? 0;
                          final loanId = loanData['id'];
                          final formattedEnd = loanData['endDate'].split('T').first;

                          return GestureDetector(
                            onTap: () async {
                              String? url;

                              if (kisweb.kIsWeb) {
                                final relativePath = getRelativePathFromUrl(book.file);
                                url = await BookController().getSignedUrl(relativePath);

                                if (url == null || url.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Error obteniendo el archivo')),
                                  );
                                  return;
                                }

                                  final cleanTitle = book.title.replaceAll(' ', '_') + '.pdf';
                                  final renamedUrl = '$url#filename=$cleanTitle';

                                  try {
                                    final res = await http.get(Uri.parse(url));
                                    if (res.statusCode != 200) {
                                      throw Exception("Archivo no disponible aún");
                                    }
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Esperando a que el archivo esté disponible...')),
                                    );
                                    return;
                                  }

                                  final viewerUrl = 'https://docs.google.com/gview?embedded=true&url=${Uri.encodeComponent(renamedUrl)}';
                                  html.window.open(viewerUrl, '_blank');

                              } else {
                                // En móvil usa la URL directa
                                url = book.file;

                                if (url != null && url.isNotEmpty) {
                                  final uri = Uri.parse(url);
                                  if (await canLaunchUrl(uri)) {
                                    if (!context.mounted) return;
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => BookReaderView(
                                          bookId: book.id,
                                          url: url!,
                                          initialPage: currentPage,
                                          userId: widget.userId,
                                          bookTitle: book.title,
                                        ),
                                      ),
                                    ).then((returnedPage) {
                                      if (returnedPage != null) {
                                        LoanController().saveCurrentPageProgress(widget.userId, book.id, returnedPage);
                                      }
                                    });
                                  }
                                }
                              }
                            },


                            child: Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: Column(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      book.cover,
                                      width: 100,
                                      height: 130,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  SizedBox(
                                    width: 150,
                                    child: Text(
                                      book.title,
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  SizedBox(
                                    width: 150,
                                    child: Text(
                                      "Formato: ${loanData['format']}",
                                      style: const TextStyle(fontSize: 10),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  if (loanData['format'] == 'Digital') ...[
                                    const SizedBox(height: 4),
                                    SizedBox(
                                      width: 150,
                                      child: Text(
                                        "Vencimiento: $formattedEnd",
                                        style: const TextStyle(fontSize: 10),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ElevatedButton(
                                      onPressed: _isReturning
                                          ? null
                                          : () async {
                                              bool? confirm = await _showConfirmDialog(context);
                                              if (confirm == true) {
                                                _returnBook(loanId);
                                              }
                                            },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFAD0000),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(30),
                                          side: const BorderSide(color: Color(0xFF700101), width: 3),
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 7),
                                      ),
                                      child: _isReturning
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Text(
                                              "Devolver",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Footer(
        selectedIndex: 0,
        onItemTapped: (index) {
          switch (index) {
            case 0:
              Navigator.push(context, MaterialPageRoute(builder: (context) => const HomeView()));
              break;
            case 1:
              Navigator.push(context, MaterialPageRoute(builder: (context) => const UserSearchView()));
              break;
            case 2:
              Navigator.push(context, MaterialPageRoute(builder: (context) => const GeolocationMap()));
              break;
            case 3:
              Navigator.push(context, MaterialPageRoute(builder: (context) => const FavoritesView()));
              break;
            case 4:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => OwnerProfileView(userId: widget.userId)),
              );
              break;
          }
        },
      ),
    );
  }
}


class _CategoryItem extends StatelessWidget {
  final String label;
  final String? imageUrl;

  const _CategoryItem({
    required this.label,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,  
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF112363),
                width: 2,
              ),
            ),
            child: ClipOval(
              child: Image.network(
                imageUrl ?? '',  
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.normal,  
              color: Colors.black87,
            ),
            overflow: TextOverflow.ellipsis,  // Truncar texto si es largo
            maxLines: 1,  // Asegurarnos que el texto no se extienda a más de una línea
          ),
        ],
      ),
    );
  }
  
}
import 'package:booknest/controllers/account_controller.dart';
import 'package:booknest/controllers/book_controller.dart';
import 'package:booknest/controllers/loan_controller.dart';
import 'package:booknest/controllers/user_controller.dart';
import 'package:booknest/entities/models/category_model.dart';
import 'package:booknest/entities/models/user_model.dart';
import 'package:booknest/views/book_reader_view.dart';
import 'package:booknest/views/category_view.dart';
import 'package:booknest/views/edit_user_view.dart';
import 'package:booknest/views/favorites_view.dart';
import 'package:booknest/views/home_view.dart';
import 'package:booknest/views/login_view.dart';
import 'package:booknest/views/user_search_view.dart';
import 'package:booknest/widgets/background.dart';
import 'package:booknest/widgets/footer.dart';
import 'package:booknest/widgets/success_dialog.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
  String? currentImageUrl;

  List<Category> categories = [];
  bool _isLoading = false;
  String _message = '';

  final UserController _userController = UserController();

  List<Map<String, dynamic>> activeLoans = [];

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _fetchUserCategoriesFromBooks();
    _fetchActiveLoans();
  }

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

  void _returnBook(int loanId) async {
    try {
      await LoanController().updateLoanStateToReturned(loanId);
      await _fetchActiveLoans();
      _showSuccessDialog();
    } catch (e) {
      print('Error al devolver el libro: $e');
      _showErrorDialog();
    }
  }

  void _showSuccessDialog() {
    SuccessDialog.show(
      context,
      'Devolución Exitosa',
      '¡Tu libro ha sido devuelto con éxito!',
      () {},
    );
  }

  void _showErrorDialog() {
    SuccessDialog.show(
      context,
      'Error en la devolución',
      'Ha ocurrido un error en la devolución del libro.',
      () {},
    );
  }

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

  @override
  Widget build(BuildContext context) {
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
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                                Row(
                                  children: [
                                    const Icon(Icons.email, size: 16),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        _emailController.text,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.phone, size: 16),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        _phoneNumberController.text,
                                        softWrap: false,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 50),
                  const Text('Mi Biblioteca', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),
                  const Divider(thickness: 1, color: Color(0xFF112363)),
                  SizedBox(
                    height: categories.length > 4 ? 200 : 100,
                    child: categories.length > 4
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
                                child: _CategoryItem(label: category.name, imageUrl: category.image),
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
                                    child: _CategoryItem(label: category.name, imageUrl: category.image),
                                  ),
                                );
                              }).toList(),
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
                                  final url = book.file;
                                  if (url != null && url.isNotEmpty) {
                                    final uri = Uri.parse(url);
                                    if (await canLaunchUrl(uri)) {
                                      if (!context.mounted) return;
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => BookReaderView(
                                            bookId: book.id,
                                            url: book.file,
                                            initialPage: currentPage,
                                            userId: widget.userId,
                                            bookTitle: book.title,
                                          ),
                                        ),
                                      ).then((returnedPage) {
                                        if (returnedPage != null) {
                                          LoanController().saveCurrentPageProgress(
                                            widget.userId,
                                            book.id,
                                            returnedPage,
                                          );
                                        }
                                      });
                                    } else {
                                      print('No se pudo abrir el archivo');
                                    }
                                  } else {
                                    print('El libro no tiene un archivo asociado');
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
                                          "Formato: " + loanData['format'],
                                          style: const TextStyle(fontSize: 10),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      SizedBox(
                                        width: 150,
                                        child: Text(
                                          "Vencimiento: " + formattedEnd,
                                          style: const TextStyle(fontSize: 10),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      ElevatedButton(
                                        onPressed: () async {
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
                                        child: const Text(
                                          "Devolver",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
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
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const HomeView()));
                  break;
                case 3:
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const FavoritesView()));
                  break;
                case 4:
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => OwnerProfileView(userId: widget.userId)));
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
      width: 80,  // Limitar el ancho del contenedor para evitar desbordamientos
      child: Column(
        children: [
          // Contenedor con borde azul y circular para la imagen
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF112363),  // Borde azul
                width: 2,
              ),
            ),
            child: ClipOval(
              child: Image.network(
                imageUrl ?? '',  // Si no hay URL, se muestra la imagen por defecto
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Texto con truncamiento en caso de ser muy largo
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.normal,  // El texto no se pone en negrita
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
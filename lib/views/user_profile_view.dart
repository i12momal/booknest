import 'package:booknest/controllers/account_controller.dart';
import 'package:booknest/controllers/user_controller.dart';
import 'package:booknest/entities/models/category_model.dart';
import 'package:booknest/entities/models/user_model.dart';
import 'package:booknest/views/category_view.dart';
import 'package:booknest/views/home_view.dart';
import 'package:booknest/views/login_view.dart';
import 'package:booknest/widgets/background.dart';
import 'package:booknest/widgets/footer.dart';
import 'package:booknest/widgets/tap_bubble_text.dart';
import 'package:flutter/material.dart';

class UserProfileView extends StatefulWidget {
  final String userId;
  const UserProfileView({super.key, required this.userId});

  @override
  State<UserProfileView> createState() => _UserProfileViewState();
}

class _UserProfileViewState extends State<UserProfileView> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  String? currentImageUrl;

  List<Category> categories = [];
  bool _isLoading = false;
  String _message = '';

  final UserController _userController = UserController();

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _fetchUserCategoriesFromBooks();
  }

  // Obtener categorías desde los libros
  void _fetchUserCategoriesFromBooks() async {
    try {
      final categoriesFromBooks = await _userController.getCategoriesFromBooks(widget.userId);
      setState(() {
        categories = categoriesFromBooks;
      });
    } catch (e) {
      setState(() {
        _message = 'Error al cargar las categorías de los libros.';
      });
    }
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
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginView()));
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
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginView()));
        }
      });
    }
  }

 @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: AccountController().getCurrentUserId(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return const Scaffold(body: Center(child: Text("Error al cargar el usuario")));
        }

        final currentUserId = snapshot.data!;

        if (_isLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (_message.isNotEmpty) {
          return Scaffold(body: Center(child: Text(_message)));
        }

        return Scaffold(
          body: Background(
            title: 'Mi Perfil',
            onBack: () => Navigator.pop(context),
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
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFF112363)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TapBubbleText(
                                  text: _nameController.text,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.email, size: 16),
                                    const SizedBox(width: 4),
                                    Expanded(child: TapBubbleText(text: _emailController.text)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                  const Text('Biblioteca', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),
                  const Divider(thickness: 1, color: Color(0xFF112363)),

                  // Contenedor con Scroll Horizontal para categorías
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
                                        categoryImageUrl: category.image ?? '',
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
                                            categoryImageUrl: category.image ?? '',
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeView()),
                  );
                  break;
                case 1:
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeView()),
                  );
                  break;
                case 2:
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeView()),
                  );
                  break;
                case 3:
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeView()),
                  );
                  break;
                case 4:
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => UserProfileView(userId: widget.userId)),
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

class _CategoryItem extends StatelessWidget {
  final String label;
  final String? imageUrl;  // URL de la imagen para la categoría

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

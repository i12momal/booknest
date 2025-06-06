import 'package:booknest/controllers/account_controller.dart';
import 'package:booknest/controllers/user_controller.dart';
import 'package:booknest/entities/models/category_model.dart';
import 'package:booknest/entities/models/user_model.dart';
import 'package:booknest/views/category_view.dart';
import 'package:booknest/views/favorites_view.dart';
import 'package:booknest/views/geolocation_view.dart';
import 'package:booknest/views/home_view.dart';
import 'package:booknest/views/login_view.dart';
import 'package:booknest/views/owner_profile_view.dart';
import 'package:booknest/views/user_search_view.dart';
import 'package:booknest/widgets/background.dart';
import 'package:booknest/widgets/footer.dart';
import 'package:booknest/widgets/tap_bubble_text.dart';
import 'package:flutter/material.dart';

// Vista para la acción del Perfil de un Usuario cualquiera de la aplicación
class UserProfileView extends StatefulWidget {
  final String userId;
  const UserProfileView({super.key, required this.userId});

  @override
  State<UserProfileView> createState() => _UserProfileViewState();
}

class _UserProfileViewState extends State<UserProfileView> {
  final _nameController = TextEditingController();
  final _userNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? currentImageUrl;

  String? _currentUserId;

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

  // Obtener los datos del usuario
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
          _userNameController.text = userData.userName;
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
    final screenWidth = MediaQuery.of(context).size.width;

    bool isMobile = screenWidth < 600;
    bool isTablet = screenWidth >= 600 && screenWidth < 1024;
    bool isDesktop = screenWidth >= 1024;

    final hasDescription = _descriptionController.text.trim().isNotEmpty &&
        _descriptionController.text.trim().toLowerCase() != 'null';

    return FutureBuilder<String?>(
      future: AccountController().getCurrentUserId(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return const Scaffold(body: Center(child: Text("Error al cargar el usuario")));
        }

        if (_isLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (_message.isNotEmpty) {
          return Scaffold(body: Center(child: Text(_message)));
        }

        _currentUserId = snapshot.data;

        // Categorias responsive
        Widget categoryLayout;

        if (categories.isEmpty) {
          categoryLayout = const Center(child: Text('No tiene libros subidos actualmente.'));
        } else if (isMobile) {
          categoryLayout = categories.length > 4
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
                    return _buildCategoryItem(category);
                  },
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: categories.map((category) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 20),
                        child: _buildCategoryItem(category),
                      );
                    }).toList(),
                  ),
                );
        } else {
          // Tablets y ordenadores
          categoryLayout = SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: Wrap(
                spacing: 20,
                runSpacing: 20,
                children: categories.map((category) {
                  return _buildCategoryItem(category);
                }).toList(),
              ),
            ),
          );

        }

        return Scaffold(
          body: Background(
            title: _userNameController.text,
            onBack: () => Navigator.pop(context),
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

                  const SizedBox(height: 50),
                  const Text('Biblioteca', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),
                  const Divider(thickness: 1, color: Color(0xFF112363)),

                  // Categorías según tipo de dispositivo
                  SizedBox(
                    height: isMobile ? (categories.length > 4 ? 200 : 100) : null,
                    child: categoryLayout,
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
                  Navigator.push(context, MaterialPageRoute(builder: (context) => OwnerProfileView(userId: _currentUserId!)));
                  break;
              }
            },
          ),
        );
      },
    );
  }

  // Helper para evitar repetición
  Widget _buildCategoryItem(Category category) {
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
  }

}

// Categorías
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
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }
  
}
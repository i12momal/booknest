import 'package:booknest/controllers/user_controller.dart';
import 'package:booknest/entities/models/user_model.dart';
import 'package:booknest/views/edit_user_view.dart';
import 'package:booknest/views/login_view.dart';
import 'package:booknest/widgets/background.dart';
import 'package:booknest/widgets/tap_bubble_text.dart';
import 'package:flutter/material.dart';

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

  List<String> categories = [];
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
      List<String> categoriesFromBooks = await _userController.getCategoriesFromBooks(widget.userId);
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
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_message.isNotEmpty) return Center(child: Text(_message));

    return Background(
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
            const Text('Mi Biblioteca', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            const Divider(thickness: 1, color: Color(0xFF112363)),

            // Contenedor con Scroll Horizontal para categorías
            SizedBox(
              height: 100,  // Establecemos la altura fija para el contenedor
              child: ListView(
                scrollDirection: Axis.horizontal, // Permitir scroll horizontal
                children: [
                  Wrap(
                    spacing: 12,  // Espacio entre elementos
                    runSpacing: 12,  // Espacio entre filas
                    alignment: WrapAlignment.start,  // Alineación a la izquierda
                    children: categories.map((category) {
                      // Asegúrate de tener una URL de imagen para cada categoría
                      String imageUrl = 'URL_DE_LA_IMAGEN_DE_LA_CATEGORIA'; // Aquí se podría poner una imagen asociada a cada categoría
                      return _CategoryItem(
                        label: category,
                        imageUrl: imageUrl,  // Aquí pasas la URL de la imagen
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Text('Prestados', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            const Divider(thickness: 1, color: Color(0xFF112363)),
            SizedBox(
              height: 150,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: const [
                  _BookImage('assets/culpa_tuya.png'),
                  _BookImage('assets/culpa_mia.png'),
                  _BookImage('assets/culpa_nuestra.png'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryItem extends StatelessWidget {
  final String label;
  final String? imageUrl;  // URL de la imagen para la categoría
  const _CategoryItem({required this.label, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 25,
          backgroundImage: imageUrl != null && imageUrl!.isNotEmpty
              ? NetworkImage(imageUrl!)  // Usamos la URL de la imagen
              : const AssetImage('assets/estanteria.jpg') as ImageProvider,  // Imagen por defecto
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _BookImage extends StatelessWidget {
  final String path;
  const _BookImage(this.path);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(path, width: 100, fit: BoxFit.cover),
      ),
    );
  }
}

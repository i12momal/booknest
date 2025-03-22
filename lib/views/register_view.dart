import 'dart:io';
import 'package:booknest/widgets/image_picker.dart';
import 'package:booknest/views/login_view.dart';
import 'package:flutter/material.dart';
import 'package:booknest/controllers/account_controller.dart';
import 'package:booknest/controllers/categories_controller.dart';
import 'package:booknest/widgets/background.dart';
import 'package:booknest/widgets/custom_text_field.dart';
import 'package:booknest/widgets/page_navigation.dart';
import 'package:booknest/widgets/success_dialog.dart';
import 'package:booknest/widgets/genre_selection.dart';

// Vista para la acción de Registro de Usuario 
class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _nameController = TextEditingController();
  final _userNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  File? _imageFile;
  final _formKey = GlobalKey<FormState>();

  final PageController _pageController = PageController();
  final AccountController _userController = AccountController();
  final CategoriesController _categoryController = CategoriesController();

  String _message = '';
  int _currentPage = 0;
  
  List<String> genres = [];
  List<String> selectedGenres = [];

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  // Función que maneja la imagen seleccionada
  void _handleImagePicked(File? image) {
    setState(() {
      _imageFile = image;
    });
  }

  // Función para obtener las categorías
  void _fetchCategories() async {
    List<String> categories = await _categoryController.getCategories();
    setState(() {
      genres = categories;
    });
  }

  // Función para pasar a la página de selección de géneros desde la página de datos personales
  Future<void> nextPage() async {
    if (_formKey.currentState?.validate() ?? false) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentPage = 1;
      });
    }
  }

  // Función para pasar a la página de datos personales desde la selección de géneros
  void prevPage() {
    _pageController.previousPage(
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    setState(() {
      _currentPage = 0;
    });
  }

  // Método que realiza la función de registro del usuario
  Future<void> _registerUser() async {
    if (selectedGenres.isEmpty) {
      setState(() {
        _message = "* Seleccione al menos un género favorito";
      });
      return;
    }

    // Limpiar el mensaje de error si ya se seleccionaron géneros
    setState(() { _message = '';});

    final name = _nameController.text;
    final userName = _userNameController.text;
    final email = _emailController.text;
    final phoneNumber = int.tryParse(_phoneNumberController.text) ?? 0;
    final address = _addressController.text;
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    final result = await _userController.registerUser(
        name, userName, email, phoneNumber, address, password, confirmPassword, _imageFile, selectedGenres.join(", "));

    setState(() {
      _message = result['message'];
    });

    if (result['success']) {
      // Mostrar ventana emergente de éxito
      setState(() {
        _message = ''; // Limpiar el mensaje
      });
      _showSuccessDialog();
    }
  }

  // Función que muestra el dialogo de éxito al registrar un usuario
  void _showSuccessDialog() {
    SuccessDialog.show(
      context,
      'Registro Exitoso', 
      '¡Tu cuenta ha sido creada con éxito!',
      () {
        Navigator.pop(context);

        // Redirigir a la pantalla de inicio de sesión después de que el usuario acepte
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginView()),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Background(
      title: 'Registro',
      onBack: prevPage,
      child: PageNavigation(
        pageController: _pageController,
        currentPage: _currentPage,
        firstPage: _buildPersonalInfoPage(),
        secondPage: _buildGenreSelectionPage(),
      ),
    );
  }

  // Página de registro: Datos Personales
  Widget _buildPersonalInfoPage() {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(16.0),
    child: Form( 
      key: _formKey, 
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          const Row(
            children: [
              Text(
                'Datos Personales',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(width: 5),
              Icon(Icons.person_outline),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF687CFF), Color(0xFF2E3C94)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.29, 0.55],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF112363),
                width: 3,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 5,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nombre Completo',
                    style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  CustomTextField(
                    icon: Icons.person, 
                    hint: '',
                    controller: _nameController,
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Nombre de Usuario',
                    style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  CustomTextField(
                    icon: Icons.account_circle, 
                    hint: '',
                    controller: _userNameController,
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Correo Electrónico',
                    style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  CustomTextField(
                    icon: Icons.email,
                    hint: '',
                    controller: _emailController,
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Número de Teléfono',
                    style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  CustomTextField(
                    icon: Icons.phone, 
                    hint: '',
                    controller: _phoneNumberController,
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Dirección',
                    style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  CustomTextField(
                    icon: Icons.home, 
                    hint: '',
                    controller: _addressController,
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Contraseña',
                    style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  CustomTextField(
                    icon: Icons.visibility, 
                    hint: '',
                    isPassword: true,
                    controller: _passwordController,
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Confirmar Contraseña',
                    style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  CustomTextField(
                    icon: Icons.visibility, 
                    hint: '',
                    isPassword: true,
                    controller: _confirmPasswordController,
                  ),
                  const SizedBox(height: 15),
                  
                  ImagePickerWidget(
                      initialImage: _imageFile,
                      onImagePicked: _handleImagePicked,
                    ),

                  const SizedBox(height: 22),
                  Align(
                    alignment: Alignment.center,
                    child: ElevatedButton(
                      onPressed: nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFAD0000),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                          side: const BorderSide(color: Colors.white, width: 3),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                      ),
                      child: const Text(
                        "Siguiente",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}


  // Página de registro: Selección de Géneros
  Widget _buildGenreSelectionPage() {
    return GenreSelectionWidget(
      genres: genres,
      selectedGenres: selectedGenres,
      message: _message,
      onGenreSelected: (genre) {
        setState(() {
          if (selectedGenres.contains(genre)) {
            selectedGenres.remove(genre);
          } else {
            selectedGenres.add(genre);
          }
          if (selectedGenres.isNotEmpty) {
            _message = '';
          }
        });
      },
      onRegister: _registerUser,
    );
  }

}

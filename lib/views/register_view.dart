import 'dart:io';
import 'package:booknest/views/login_view.dart';
import 'package:flutter/material.dart';
import 'package:booknest/controllers/account_controller.dart';
import 'package:booknest/controllers/categories_controller.dart';
import 'package:booknest/widgets/background.dart';
import 'package:booknest/widgets/page_navigation.dart';
import 'package:booknest/widgets/success_dialog.dart';
import 'package:booknest/widgets/genre_selection.dart';
import 'package:booknest/widgets/personal_info_form.dart';

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
  final AccountController _accountController = AccountController();
  final CategoriesController _categoryController = CategoriesController();

  String _message = '';
  int _currentPage = 0;

  final isEditMode = false;
  
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
    // Primero cerramos el teclado
    FocusScope.of(context).unfocus();

    // Hacemos una pequeña espera para asegurarnos de que el teclado se haya cerrado antes de cambiar de página
    await Future.delayed(const Duration(milliseconds: 500));

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

    final name = _nameController.text.trim();
    final userName = _userNameController.text.trim();
    final email = _emailController.text.trim();
    final phoneNumber = int.tryParse(_phoneNumberController.text.trim()) ?? 0;
    final address = _addressController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    final result = await _accountController.registerUser(
        name, userName, email, phoneNumber, address, password, confirmPassword, _imageFile, selectedGenres.join(", "));

    setState(() {
      _message = result['message'];
    });

    if (result['success']) {
      setState(() {
        _message = '';
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
    return GestureDetector(
      onTap: () {
        // Al tocar fuera del campo de texto, se oculta el teclado
        FocusScope.of(context).unfocus();
      },
      child: Background(
        title: 'Registro',
        onBack: prevPage,
        child: PageNavigation(
          pageController: _pageController,
          currentPage: _currentPage,
          firstPage: _buildPersonalInfoPage(),
          secondPage: _buildGenreSelectionPage(),
        ),
      ),
    );
  }

  // Página de registro: Datos Personales
  Widget _buildPersonalInfoPage() {
    return PersonalInfoForm(
      nameController: _nameController,
      userNameController: _userNameController,
      emailController: _emailController,
      phoneNumberController: _phoneNumberController,
      addressController: _addressController,
      passwordController: _passwordController,
      confirmPasswordController: _confirmPasswordController,
      imageFile: _imageFile,
      onImagePicked: _handleImagePicked,
      onNext: nextPage,
      formKey: _formKey,
      isEditMode: isEditMode,
    );
  }

  // Página de registro: Selección de Géneros
  Widget _buildGenreSelectionPage() {
    return GenreSelectionWidget(
      isEditMode: isEditMode,
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
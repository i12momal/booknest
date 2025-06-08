import 'dart:io';
import 'package:booknest/views/login_view.dart';
import 'package:flutter/material.dart';
import 'package:booknest/controllers/account_controller.dart';
import 'package:booknest/controllers/categories_controller.dart';
import 'package:booknest/widgets/background.dart';
import 'package:booknest/widgets/page_navigation.dart';
import 'package:booknest/widgets/genre_selection_register.dart';
import 'package:booknest/widgets/personal_info_form.dart';
import 'package:flutter/foundation.dart';

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
  final _descriptionController = TextEditingController();
  File? _imageFile;             // Para móvil
  Uint8List? _imageWebBytes;    // Para web
  final _formKey = GlobalKey<FormState>();

  final PageController _pageController = PageController();
  final AccountController _accountController = AccountController();
  final CategoriesController _categoryController = CategoriesController();

  String _message = '';
  int _currentPage = 0;

  final isEditMode = false;
  bool _isLoading = false;
  
  List<String> genres = [];
  List<String> selectedGenres = [];

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  // Función que maneja la imagen seleccionada
  void _handleImagePickedMobile(File? image) {
    setState(() {
      _imageFile = image;
    });
  }

  void _handleImagePickedWeb(Uint8List? bytes) {
    setState(() {
      _imageWebBytes = bytes;
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
    FocusScope.of(context).unfocus();

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
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentPage--;
      });
    } else {
      Navigator.pop(context);
    }
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
    final description = _descriptionController.text.trim();

    final imageToUpload = kIsWeb ? _imageWebBytes : _imageFile;

    setState(() {
      _isLoading = true;
    });

    final result = await _accountController.registerUser(name, userName, email, phoneNumber, address, password, confirmPassword, imageToUpload, selectedGenres.join(", "), description);

    setState(() {
      _message = result['message'];
      _isLoading = false;
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registro Exitoso'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [Text('¡Tu cuenta ha sido creada con éxito!')],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginView()),
              );
            },
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Background(
        title: 'Registro',
        showNotificationIcon: false,
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
      descriptionController: _descriptionController,
      initialImageFile: _imageFile,
      initialImageWebBytes: _imageWebBytes,
      onImagePickedMobile: _handleImagePickedMobile,
      onImagePickedWeb: _handleImagePickedWeb,
      onNext: nextPage,
      formKey: _formKey,
      isEditMode: isEditMode,
      originalEmail: null,
      originalUsername: null,
      imageUrl: null,
    );
  }

  // Página de registro: Selección de Géneros
  Widget _buildGenreSelectionPage() {
    return GenreSelectionRegisterWidget(
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
      isLoading: _isLoading,
    );
  }
  
}
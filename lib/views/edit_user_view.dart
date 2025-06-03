import 'dart:io';
import 'package:booknest/entities/models/user_model.dart';
import 'package:booknest/views/login_view.dart';
import 'package:booknest/views/owner_profile_view.dart';
import 'package:flutter/material.dart';
import 'package:booknest/controllers/user_controller.dart';
import 'package:booknest/controllers/categories_controller.dart';
import 'package:booknest/widgets/background.dart';
import 'package:booknest/widgets/page_navigation.dart';
import 'package:booknest/widgets/success_dialog.dart';
import 'package:booknest/widgets/genre_selection_register.dart';
import 'package:booknest/widgets/personal_info_form.dart';

// Vista para la acción de Edición de Datos de Usuario 
class EditUserView extends StatefulWidget {
  final String userId;
  const EditUserView({super.key, required this.userId});

  @override
  State<EditUserView> createState() => _EditUserViewState();
}

class _EditUserViewState extends State<EditUserView> {
  final _nameController = TextEditingController();
  final _userNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _descriptionController = TextEditingController();
  File? _imageFile;
  final _formKey = GlobalKey<FormState>();

  final PageController _pageController = PageController();
  final UserController _userController = UserController();
  final CategoriesController _categoryController = CategoriesController();

  final bool isEditMode = true;
  bool _isLoading = false;
  String _message = '';
  int _currentPage = 0;
  
  List<String> genres = [];
  List<String> selectedGenres = [];
  String? currentImageUrl;

  String? _originalEmail;
  String? _originalUsername;


  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _fetchCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _userNameController.dispose();
    _emailController.dispose();
    _phoneNumberController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _pageController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // Función que maneja la imagen seleccionada
  void _handleImagePicked(File? image) {
    setState(() {
      _imageFile = image;
    });
  }

  // Función para cargar datos del usuario
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
          _phoneNumberController.text = userData.phoneNumber.toString();
          _addressController.text = userData.address;
          _descriptionController.text = userData.description!;
          selectedGenres = List<String>.from(userData.genres);
          currentImageUrl = userData.image ?? '';
          _originalEmail = userData.email;
          _originalUsername = userData.userName;
          _isLoading = false;
        });
      } else {
        setState(() {
          _message = 'No se encontró la información del usuario. Por favor, intente nuevamente.';
          _isLoading = false;
        });
        // Redirigir al login 
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginView()),
            );
          }
        });
      }
    } catch (e) {
      setState(() {
        _message = 'Error al cargar los datos del usuario. Por favor, intente nuevamente.';
        _isLoading = false;
      });
      // Redirigir al login 
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginView()),
          );
        }
      });
    }
  }

  // Función para obtener las categorías
  void _fetchCategories() async {
    try {
      List<String> categories = await _categoryController.getCategories();
      setState(() {
        genres = categories;
      });
    } catch (e) {
      setState(() {
        _message = 'Error al cargar las categorías';
      });
    }
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

  // Función que muestra el dialogo de éxito al actualizar un usuario
  void _showSuccessDialog() {
    SuccessDialog.show(
      context,
      'Actualización Exitosa', 
      '¡Tus datos han sido actualizados correctamente!',
      () {
        Navigator.pop(context);
        Future.microtask(() {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => OwnerProfileView(userId: widget.userId),
            ),
          );
        });
      },
    );
  }

  // Método para actualizar el usuario
  Future<void> _updateUser() async {
    if (selectedGenres.isEmpty) {
      setState(() {
        _message = "* Seleccione al menos un género favorito";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = '';
    });

    try {
      final name = _nameController.text.trim();
      final userName = _userNameController.text.trim();
      final email = _emailController.text.trim();
      final description = _descriptionController.text.trim();
      final phoneNumber = int.tryParse(_phoneNumberController.text.trim()) ?? 0;
      final address = _addressController.text.trim();
      final password = _passwordController.text.isNotEmpty ? _passwordController.text.trim() : null;
      final confirmPassword = _confirmPasswordController.text.isNotEmpty ? _confirmPasswordController.text.trim() : null;

      // Mantener la imagen actual si no se ha seleccionado una nueva
      // final imageUrl = _imageFile ?? currentImageUrl ?? '';

      final result = await _userController.editUser(widget.userId, name, userName, email, phoneNumber, address, password ?? '', confirmPassword ?? '', _imageFile,
        selectedGenres.join(", "), description);

      if (result['success']) {
        _showSuccessDialog();
      } else {
        setState(() {
          _message = result['message'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _message = 'Error al actualizar los datos del usuario';
        _isLoading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Background(
        title: 'Editar Usuario',
        onBack: prevPage,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : PageNavigation(
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
      imageFile: _imageFile,
      onImagePicked: _handleImagePicked,
      onNext: nextPage,
      formKey: _formKey,
      isEditMode: isEditMode,
      imageUrl: currentImageUrl,
      originalEmail: _originalEmail,
      originalUsername: _originalUsername,
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
      onRegister: _updateUser,
      isLoading: _isLoading,
    );
  }
  
}
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:booknest/views/login_view.dart';
import 'package:flutter/material.dart';
import 'package:booknest/controllers/account_controller.dart';
import 'package:booknest/controllers/categories_controller.dart';
import 'package:booknest/widgets/background.dart';
import 'package:booknest/widgets/custom_text_field.dart';
import 'package:booknest/widgets/success_dialog.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:email_validator/email_validator.dart';

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
  final String _defaultImagePath = 'assets/images/default.png';
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

  // Función para adjuntar una imagen
  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
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

  /*
  // Método para realizar validaciones de los datos introducidos
  Future<bool> _isPersonalInfoValid() async {
    if (_nameController.text.length < 5) {
      setState(() {
        _message = "El nombre debe tener al menos 5 caracteres.";
      });
      return false;
    }

    if (_userNameController.text.length < 5) {
      setState(() {
        _message = "El nombre de usuario debe tener al menos 5 caracteres.";
      });
      return false;
    }

    if (await _userController.isUsernameTaken(_userNameController.text)) {
      setState(() {
        _message = "El nombre de usuario ya está en uso.";
      });
      return false;
    }

    if (!EmailValidator.validate(_emailController.text)) {
      setState(() {
        _message = "Por favor, ingrese un correo electrónico válido.";
      });
      return false;
    }

    if (_phoneNumberController.text.length != 9) {
      setState(() {
        _message = "El número de teléfono debe tener 9 cifras.";
      });
      return false;
    }

    if (_addressController.text.isEmpty) {
      setState(() {
        _message = "La dirección es obligatoria.";
      });
      return false;
    }

    if (_passwordController.text.length < 8) {
      setState(() {
        _message = "La contraseña debe tener al menos 8 caracteres.";
      });
      return false;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _message = "Las contraseñas no coinciden.";
      });
      return false;
    }

    return true;
  }*/

  @override
  Widget build(BuildContext context) {
    
    return Background(
      title: 'Registro',
      onBack: prevPage,
      child: Column(
        children: [
          LinearProgressIndicator(
            value: _currentPage == 0 ? 0.5 : 1.0,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFAD0000)),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildPersonalInfoPage(),
                _buildGenreSelectionPage(),
              ],
            ),
          ),
        ],
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
                    /*validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingrese su nombre';
                      }
                      if (value.length < 3) {
                        return 'El nombre debe tener al menos 3 caracteres';
                      }
                      return null;
                    },*/
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
                    /*validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingrese un nombre de usuario';
                      }
                      if (value.length < 5) {
                        return 'El nombre de usuario debe tener al menos 5 caracteres';
                      }
                      return null;
                    },*/
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
                    /*validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingrese un correo electrónico';
                      }
                      if (!EmailValidator.validate(value)) {
                        return 'Por favor ingrese un correo electrónico válido';
                      }
                      return null;
                    },*/
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
                    /*validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingrese su número de teléfono';
                      }
                      if (value.length != 9) {
                        return 'El número de teléfono debe tener 9 dígitos';
                      }
                      return null;
                    },*/
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
                    /*validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingrese su dirección';
                      }
                      return null;
                    },*/
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
                    /*validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingrese su contraseña';
                      }
                      if (value.length < 8) {
                        return 'La contraseña debe tener al menos 8 caracteres';
                      }
                      return null;
                    },*/
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
                    /*validator: (value) {
                      if (value != _passwordController.text) {
                        return 'Las contraseñas no coinciden';
                      }
                      return null;
                    },*/
                  ),
                  const SizedBox(height: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start, 
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Foto',
                            style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.file_present_sharp, color: Colors.black),
                            onPressed: _pickImage,
                          ),
                        ],
                      ),

                      const SizedBox(height: 6), // Espacio entre el texto/ícono y la imagen

                      // Imagen circular centrada
                      Center(
                        child: ClipOval(
                          child: _imageFile != null
                              ? Image.file(
                                  _imageFile!,
                                  width: 100, // Tamaño de la imagen
                                  height: 100,
                                  fit: BoxFit.cover,
                                )
                              : Image.asset(
                                  _defaultImagePath, // Imagen por defecto
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),
                    ],
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
    return LayoutBuilder(
      builder: (context, constraints){
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Text(
                    'Seleccione sus géneros favoritos',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 5),
                  Icon(Icons.favorite_border, size: 20),
                ],
              ),
              const SizedBox(height: 18), 

              Container(
                width: constraints.maxWidth,
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
                padding: const EdgeInsets.all(16.0),
                child: Wrap(
                  spacing: 16.0, 
                  runSpacing: 12.0, 
                  children: genres.map((genre) => _buildGenreChip(genre)).toList(),
                ),
              ),
              const SizedBox(height: 10),
              Text(_message, style: const TextStyle(color: Color(0xFFAD0000))),
              const Spacer(), 
              Align(
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown, 
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginView()),
                          );
                        },
                        child: const Text(
                          '¿Ya tiene una cuenta? ¡Inicie sesión!',
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10), // Espacio entre los botones
                    ElevatedButton(
                      onPressed: _registerUser,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFAD0000),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                          side: const BorderSide(color: Color.fromARGB(255, 112, 1, 1), width: 3),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                      ),
                      child: const Text(
                        "Registrarse",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        );
      }
    );
  }

  // Función para la selección de géneros
  Widget _buildGenreChip(String genre) {
    final isSelected = selectedGenres.contains(genre);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            selectedGenres.remove(genre);
          } else {
            selectedGenres.add(genre);
          }
          // Limpiar el mensaje de error si ya se seleccionó al menos un género
          if (selectedGenres.isNotEmpty) {
            _message = '';
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFAD0000) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.white : const Color(0xFF112363), 
            width: 2,
          ),
        ),
        child: AutoSizeText(
          genre,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black, 
          ),
        ),
      ),
    );
  }
}

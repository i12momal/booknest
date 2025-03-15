import 'package:booknest/views/login_view.dart';
import 'package:flutter/material.dart';
import 'package:booknest/controllers/account_controller.dart';
import 'package:booknest/widgets/background.dart';
import 'package:booknest/widgets/custom_text_field.dart';
import 'package:email_validator/email_validator.dart';

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
  final _imageController = TextEditingController();

  final AccountController _userController = AccountController();
  String _message = '';
  int _currentPage = 0;
  final PageController _pageController = PageController();
  List<String> selectedGenres = [];
  final List<String> genres = [
    "Drama", "Misterio", "Ciencia Ficción", "Amor", "Policíaca", "Historia", "Fantasía", "Terror"
  ];

  /*
  Future<void> nextPage() async {
    if (await _isPersonalInfoValid()) {
      _pageController.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() {
        _currentPage = 1;
      });
    }
  }*/

  Future<void> nextPage() async {
    _pageController.nextPage(
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    setState(() {
      _currentPage = 1;
    });
  }

  void prevPage() {
    _pageController.previousPage(
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    setState(() {
      _currentPage = 0;
    });
  }

  Future<void> _registerUser() async {
    if (selectedGenres.isEmpty) {
      setState(() {
        _message = "Seleccione al menos un género favorito";
      });
      return;
    }

    final name = _nameController.text;
    final userName = _userNameController.text;
    final email = _emailController.text;
    final phoneNumber = int.tryParse(_phoneNumberController.text) ?? 0;
    final address = _addressController.text;
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final image = _imageController.text;

    final result = await _userController.registerUser(
        name, userName, email, phoneNumber, address, password, confirmPassword, image, selectedGenres.join(", "));

    setState(() {
      _message = result['message'];
    });
  }

  Future<bool> _isPersonalInfoValid() async {
    if (_nameController.text.length < 3) {
      setState(() {
        _message = "El nombre debe tener al menos 3 caracteres.";
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
  }

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

  Widget _buildPersonalInfoPage() {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(16.0),
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
                CustomTextField(icon: Icons.person, hint: '', controller: _nameController),
                const SizedBox(height: 15),
                const Text(
                  'Nombre de Usuario',
                  style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                CustomTextField(icon: Icons.account_circle, hint: '', controller: _userNameController),
                const SizedBox(height: 15),
                const Text(
                  'Correo Electrónico',
                  style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                CustomTextField(icon: Icons.email, hint: '', controller: _emailController),
                const SizedBox(height: 15),
                const Text(
                  'Número de Teléfono',
                  style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                CustomTextField(icon: Icons.phone, hint: '', controller: _phoneNumberController),
                const SizedBox(height: 15),
                const Text(
                  'Dirección',
                  style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                CustomTextField(icon: Icons.home, hint: '', controller: _addressController),
                const SizedBox(height: 15),
                const Text(
                  'Contraseña',
                  style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                CustomTextField(icon: Icons.visibility, hint: '', isPassword: true, controller: _passwordController),
                const SizedBox(height: 15),
                const Text(
                  'Confirmar Contraseña',
                  style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                CustomTextField(icon: Icons.visibility, hint: '', isPassword: true, controller: _confirmPasswordController),
                const SizedBox(height: 15),
                const Text(
                  'Foto',
                  style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                CustomTextField(icon: Icons.photo, hint: '', controller: _imageController),
                const SizedBox(height: 15),
                Align(
                  alignment: Alignment.center,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const LoginView()),
                      );
                    },
                    child: const Text(
                      '¿Ya tiene una cuenta? ¡Inicie sesión!',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
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
  );
}


  Widget _buildGenreSelectionPage() {
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
        const SizedBox(height: 20), // Separación entre el texto y el contenedor

        // Contenedor con el listado de géneros
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
          padding: const EdgeInsets.all(16.0),
          child: Wrap(
            spacing: 16.0, // Aumenta la distancia entre los géneros horizontalmente
            runSpacing: 12.0, // Aumenta la distancia vertical entre las filas
            children: genres.map((genre) => _buildGenreChip(genre)).toList(),
          ),
        ),

        const SizedBox(height: 10),
        Text(_message, style: const TextStyle(color: Color(0xFFAD0000))),
        const Spacer(),

        // Botón de registro
        Align(
          alignment: Alignment.center,
          child: ElevatedButton(
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
        )
      ],
    ),
  );
}

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
      });
    },
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFAD0000) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? Colors.white :  const Color(0xFF112363), // Borde blanco cuando está seleccionado
          width: 2,
        ),
      ),
      child: Text(
        genre,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black, // Texto blanco cuando está seleccionado
        ),
      ),
    ),
  );
}


}
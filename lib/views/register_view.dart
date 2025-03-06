import 'package:flutter/material.dart';
import 'package:booknest/controllers/user_controller.dart';

// Vista para la acción de registro del usuario.
class RegisterView extends StatefulWidget {
  const RegisterView ({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _nameController = TextEditingController();
  final _userNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();
  final _imageController = TextEditingController();
  
  final UserController _userController = UserController();

  // Variable para mostrar el mensaje de error o éxito
  String _message = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registro de Usuario')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nombre Completo'),
            ),
            TextField(
              controller: _userNameController,
              decoration: const InputDecoration(labelText: 'Nombre Usuario'),
            ),
            TextField(
              controller: _ageController,
              decoration: const InputDecoration(labelText: 'Edad'),
            ),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _phoneNumberController,
              decoration: const InputDecoration(labelText: 'Número teléfono'),
            ),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Dirección'),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Contraseña'),
              obscureText: true,
            ),
            TextField(
              controller: _imageController,
              decoration: const InputDecoration(labelText: 'Imagen'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _registerUser,
              child: const Text('Registrarse'),
            ),
            const SizedBox(height: 20),
            Text(_message, style: const TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }

  // Método para registrar al usuario usando el controlador
  Future<void> _registerUser() async {
    final name = _nameController.text;
    final userName = _userNameController.text;
    final age = int.tryParse(_ageController.text) ?? 0;
    final email = _emailController.text;
    final phoneNumber = int.tryParse(_phoneNumberController.text) ?? 0;
    final address = _addressController.text;
    final password = _passwordController.text;
    final image = _imageController.text;

    final result = await _userController.registerUser(name, userName, age, email, phoneNumber, address, password, image);

    setState(() {
      if (result['success']) {
        _message = result['message']; // Éxito
      } else {
        _message = result['message']; // Error
      }
    });
  }
}
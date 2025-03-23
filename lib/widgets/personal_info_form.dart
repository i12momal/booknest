import 'dart:io';
import 'package:flutter/material.dart';
import 'package:booknest/widgets/custom_text_field.dart';
import 'package:booknest/widgets/image_picker.dart';

class PersonalInfoForm extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController userNameController;
  final TextEditingController emailController;
  final TextEditingController phoneNumberController;
  final TextEditingController addressController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final File? imageFile;
  final Function(File?) onImagePicked;
  final VoidCallback onNext;
  final GlobalKey<FormState> formKey;

  const PersonalInfoForm({
    super.key,
    required this.nameController,
    required this.userNameController,
    required this.emailController,
    required this.phoneNumberController,
    required this.addressController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.imageFile,
    required this.onImagePicked,
    required this.onNext,
    required this.formKey,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: formKey,
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
                    _buildTextField('Nombre y Apellidos', Icons.person, nameController),
                    _buildTextField('Dirección', Icons.home, addressController),
                    _buildTextField('Teléfono', Icons.phone, phoneNumberController),
                    _buildTextField('Correo Electrónico', Icons.email, emailController),
                    _buildTextField('Usuario', Icons.account_circle, userNameController),
                    _buildTextField('Contraseña', Icons.visibility, passwordController, isPassword: true),
                    _buildTextField('Confirmar Contraseña', Icons.visibility, confirmPasswordController, isPassword: true),
                    const SizedBox(height: 15),

                    ImagePickerWidget(
                      initialImage: imageFile,
                      onImagePicked: onImagePicked,
                    ),

                    const SizedBox(height: 22),
                    Align(
                      alignment: Alignment.center,
                      child: ElevatedButton(
                        onPressed: onNext,
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

  Widget _buildTextField(String label, IconData icon, TextEditingController controller, {bool isPassword = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        CustomTextField(
          icon: icon,
          hint: '',
          isPassword: isPassword,
          controller: controller,
        ),
        const SizedBox(height: 15),
      ],
    );
  }
}

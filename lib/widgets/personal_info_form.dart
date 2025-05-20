import 'dart:io';
import 'package:booknest/controllers/account_controller.dart';
import 'package:flutter/material.dart';
import 'package:booknest/widgets/custom_text_field.dart';
import 'package:booknest/widgets/image_picker.dart';

class PersonalInfoForm extends StatefulWidget {
  final TextEditingController nameController;
  final TextEditingController userNameController;
  final TextEditingController emailController;
  final TextEditingController phoneNumberController;
  final TextEditingController addressController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final TextEditingController? descriptionController;
  final File? imageFile;
  final Function(File?) onImagePicked;
  final VoidCallback onNext;
  final GlobalKey<FormState> formKey;
  final bool isEditMode;
  final String? imageUrl; 
  final String? originalEmail;
  final String? originalUsername;


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
    required this.isEditMode,
    this.imageUrl,
    this.descriptionController,
    this.originalEmail,
    this.originalUsername,
  });

  @override
  State<PersonalInfoForm> createState() => _PersonalInfoFormState();
}

class _PersonalInfoFormState extends State<PersonalInfoForm> {
  bool isPasswordModified = false;
  String? _userNameValidationMessage;
  late FocusNode _userNameFocusNode;

  String? _emailValidationMessage;
  late FocusNode _emailFocusNode;

  @override
  void initState() {
    super.initState();
    _userNameFocusNode = FocusNode();
    _emailFocusNode = FocusNode();

    _userNameFocusNode.addListener(() {
      if (!_userNameFocusNode.hasFocus) {
        validateUserName(widget.userNameController.text);
      }
    });

     _emailFocusNode.addListener(() {
      if (!_emailFocusNode.hasFocus) {
        validateEmail(widget.emailController.text);
      }
    });
  }

  @override
  void dispose() {
    _userNameFocusNode.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  Future<void> validateUserName(String username) async {
    final trimmed = username.trim();

    if (trimmed.isEmpty) {
      setState(() {
        _userNameValidationMessage = 'Por favor ingresa un nombre de usuario';
      });
    } else if (trimmed.length < 5) {
      setState(() {
        _userNameValidationMessage = 'Debe tener al menos 5 caracteres';
      });
    } else if (trimmed.length > 15) {
      setState(() {
        _userNameValidationMessage = 'Máximo 15 caracteres permitidos';
      });
    } else {
      // Validar solo si el nombre ha cambiado
      if (widget.isEditMode && trimmed == widget.originalUsername) {
        setState(() {
          _userNameValidationMessage = null;
        });
      } else {
        bool userNameExists = await AccountController().checkUsernameExists(trimmed);
        setState(() {
          _userNameValidationMessage = userNameExists ? 'Este nombre de usuario ya está en uso' : null;
        });
      }
    }
  }


  Future<void> validateEmail(String email) async {
    final trimmed = email.trim();

    if (trimmed.isEmpty) {
      setState(() {
        _emailValidationMessage = 'Por favor ingresa tu correo electrónico';
      });
    } else if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(trimmed)) {
      setState(() {
        _emailValidationMessage = 'Debe ser un correo electrónico válido';
      });
    } else {
      // Validar solo si el email ha cambiado
      if (widget.isEditMode && trimmed == widget.originalEmail) {
        setState(() {
          _emailValidationMessage = null;
        });
      } else {
        bool emailExists = await AccountController().checkEmailExists(trimmed);
        setState(() {
          _emailValidationMessage = emailExists ? 'Este correo ya está en uso' : null;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: widget.formKey,
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
                    _buildTextField(
                      'Nombre y Apellidos', 
                      Icons.person, 
                      widget.nameController, 
                      validator: (value) {
                        final trimmed = value?.trim() ?? '';
                        if (trimmed.isEmpty) {
                          return 'Por favor ingresa tu nombre completo';
                        } else if (trimmed.length < 5) {
                          return 'Debe tener al menos 5 caracteres';
                        } else if (trimmed.length > 30) {
                          return 'Máximo 30 caracteres permitidos';
                        }
                        return null;
                      },
                    ),
                    _buildTextField(
                      'Dirección', 
                      Icons.home, 
                      widget.addressController, 
                      validator: (value) {
                        final trimmed = value?.trim() ?? '';
                        if (trimmed.isEmpty) {
                          return 'Por favor ingresa tu dirección';
                        } else if (trimmed.length < 5) {
                          return 'Debe tener al menos 5 caracteres';
                        }
                        return null;
                      },
                    ),
                    _buildTextField(
                      'Teléfono', 
                      Icons.phone, 
                      widget.phoneNumberController, 
                      validator: (value) {
                        final trimmed = value?.trim() ?? '';
                        if (trimmed.isEmpty) {
                          return 'Por favor ingresa tu número de teléfono';
                        } else if (trimmed.length != 9) {
                          return 'Debe tener 9 dígitos';
                        }
                        return null;
                      },
                    ),
                    _buildTextField(
                      'Correo Electrónico', 
                      Icons.email, 
                      widget.emailController, 
                      validator: (value) {
                        return _emailValidationMessage;
                      },
                      onChanged: (value) {
                        validateEmail(value);
                      },
                      focusNode: _emailFocusNode,
                      readOnly: true, 
                    ),
                    _buildTextField(
                      'Usuario', 
                      Icons.account_circle, 
                      widget.userNameController, 
                      validator: (value) {
                        return _userNameValidationMessage;
                      },
                      onChanged: (value) {
                        validateUserName(value);
                      },
                      focusNode: _userNameFocusNode,
                    ),
                    if (widget.isEditMode) ...[
                      const Text(
                        "Contraseña",
                        style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      CustomTextField(
                        icon: Icons.visibility,
                        hint: '* Sólo si es modificada',
                        isPassword: true,
                        controller: widget.passwordController,
                        onChanged: (text) {
                          setState(() {
                            isPasswordModified = text.trim().isNotEmpty;
                          });
                        },
                        validator: (value) {
                          final trimmed = value?.trim() ?? '';
                          if (trimmed.isEmpty && isPasswordModified) {
                            return 'Por favor ingresa una contraseña';
                          } else if (trimmed.isNotEmpty && !RegExp(r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[@$!%*?&_-])[A-Za-z\d@$!%*?&_-]{8,}$').hasMatch(trimmed)) {
                            return 'Debe contener mayúsculas, minúsculas, números y carácteres especiales';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),
                      const Text(
                        "Confirmar Contraseña",
                        style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      CustomTextField(
                        icon: Icons.visibility,
                        hint: '* Sólo si es modificada',
                        isPassword: true,
                        controller: widget.confirmPasswordController,
                        validator: (value) {
                          final trimmedValue = value?.trim() ?? '';
                          final trimmedPassword = widget.passwordController.text.trim();
                          if (trimmedValue.isEmpty && isPasswordModified) {
                            return 'Por favor confirma tu contraseña';
                          } else if (trimmedValue.isNotEmpty && trimmedValue != trimmedPassword) {
                            return 'Las contraseñas no coinciden';
                          }
                          return null;
                        },
                      ),
                    ] else ...[
                      _buildTextField(
                        'Contraseña', 
                        Icons.visibility, 
                        widget.passwordController, 
                        isPassword: true, 
                        validator: (value) {
                          final trimmed = value?.trim() ?? '';
                          if (trimmed.isEmpty) {
                            return 'Por favor ingresa una contraseña';
                          } else if (!RegExp(r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[@$!%*?&_-])[A-Za-z\d@$!%*?&_-]{8,}$').hasMatch(trimmed)) {
                             return 'Debe contener mayúsculas, minúsculas, números y carácteres especiales';
                          }
                          return null;
                        },
                      ),
                      _buildTextField(
                        'Confirmar Contraseña', 
                        Icons.visibility, 
                        widget.confirmPasswordController, 
                        isPassword: true,
                        validator: (value) {
                          final trimmedValue = value?.trim() ?? '';
                          final trimmedPassword = widget.passwordController.text.trim();
                          if (trimmedValue.isEmpty) {
                            return 'Por favor confirma tu contraseña';
                          } else if (trimmedValue != trimmedPassword) {
                            return 'Las contraseñas no coinciden';
                          }
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 15),
                    _buildTextField(
                      'Descripción', 
                      Icons.description, 
                      widget.descriptionController!,
                      validator: (value) {
                        if (value != null && value.length > 30) {
                          return 'Máximo 30 caracteres permitidos';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                    ImagePickerWidget(
                      initialImage: widget.imageFile, 
                      imageUrl: widget.imageUrl, 
                      onImagePicked: widget.onImagePicked,
                    ),
                    const SizedBox(height: 22),
                    Align(
                      alignment: Alignment.center,
                      child: ElevatedButton(
                        onPressed: () async {
                          await Future.wait([
                            validateEmail(widget.emailController.text),
                            validateUserName(widget.userNameController.text),
                          ]);

                          bool isValid = widget.formKey.currentState?.validate() ?? false;

                          if (isValid && _emailValidationMessage == null && _userNameValidationMessage == null) {
                            widget.onNext();
                          } else {
                            setState(() {});
                          }
                        },
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
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, IconData icon, TextEditingController controller, {bool isPassword = false, String? Function(String?)? validator, ValueChanged<String>? onChanged, FocusNode? focusNode, bool readOnly = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        CustomTextField(
          validator: validator, 
          icon: icon,
          hint: '',
          isPassword: isPassword,
          controller: controller,
          onChanged: onChanged,
          focusNode: focusNode,
          readOnly: readOnly,
        ),
        const SizedBox(height: 15),
      ],
    );
  }
}

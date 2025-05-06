import 'package:booknest/controllers/account_controller.dart';
import 'package:booknest/views/login_view.dart';
import 'package:booknest/widgets/custom_text_field.dart';
import 'package:booknest/widgets/success_dialog.dart';
import 'package:flutter/material.dart';
import 'package:booknest/widgets/background.dart';

class ResetPasswordView extends StatefulWidget {
  const ResetPasswordView({super.key});

  @override
  State<ResetPasswordView> createState() => _ResetPasswordViewViewState();
}

class _ResetPasswordViewViewState extends State<ResetPasswordView> {
  final _emailController = TextEditingController();
  final _pinController = TextEditingController();
  final AccountController _accountController = AccountController();

  bool _isVerified = false;
  final _newPasswordController = TextEditingController();
  final _repeatPasswordController = TextEditingController();

  bool _isReadOnly = false;
  bool _isLoading = false;
  bool _isSubmitting = false;
  String _passwordErrorMessage = '';

  String _emailErrorMessage = '';
  String _pinErrorMessage = '';

  // Función que muestra el dialogo de éxito al recuperar la contraseña
  void _showSuccessDialog() {
    SuccessDialog.show(
      context,
      'Recuperación Exitosa', 
      '¡Ha recuperado y actualizado su contraseña con éxito!',
      () {
        Navigator.pop(context);
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginView()));
      },
    );
  }

  // Función que muestra el dialogo de error al recuperar la contraseña
  void _showErrorDialog() {
    SuccessDialog.show(
      context,
      'Error en la Recuperación', 
      'Se ha producido un error al intentar actualizar la contraseña.',
      () { },
    );
  }

  @override
  void initState() {
    super.initState();

    _emailController.addListener(() {
      if (_emailErrorMessage.isNotEmpty) {
        setState(() {
          _emailErrorMessage = '';
        });
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _pinController.dispose();
    _newPasswordController.dispose();
    _repeatPasswordController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Background(
        title: 'Recuperación de Contraseña',
        showNotificationIcon: false,
        onBack: () {
          Navigator.pop(context);
        },
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: screenHeight * 0.05),
                Image.asset(
                  'assets/images/reset_password.jpg',
                  height: screenHeight * 0.3,
                ),
                SizedBox(height: screenHeight * 0.05),
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: screenWidth * 0.95,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF687CFF), Color(0xFF2E3C94)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
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
                    padding: EdgeInsets.all(screenWidth * 0.05),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Correo Electrónico',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.01),
                        CustomTextField(icon: Icons.email, hint: '', controller: _emailController, readOnly: _isReadOnly),

                        SizedBox(height: screenHeight * 0.02),
                        const Text(
                          'PIN de Recuperación',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.01),
                        CustomTextField(icon: Icons.pin, hint: '', controller: _pinController, readOnly: _isReadOnly),
                        if (_pinErrorMessage.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0, bottom: 12.0),
                            child: Text(
                              _pinErrorMessage,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ValueListenableBuilder<String>(
                          valueListenable: _accountController.errorMessage,
                          builder: (context, value, child) {
                            if (value.isEmpty) return const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0, bottom: 12.0),
                              child: Text(
                                value,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          },
                        ),
                        SizedBox(height: screenHeight * 0.02),

                        if (!_isVerified)
                          Center(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFAD0000),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  side: const BorderSide(color: Colors.white, width: 3),
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.1,
                                  vertical: screenHeight * 0.02,
                                ),
                              ),
                              onPressed: _isLoading
                                ? null
                                : () async {
                                    FocusScope.of(context).unfocus();

                                    final email = _emailController.text.trim();
                                    final pin = _pinController.text.trim();

                                    // Limpiar mensajes de error previos
                                    setState(() {
                                      _emailErrorMessage = '';  
                                      _pinErrorMessage = '';   
                                      _isLoading = true;
                                    });

                                    // Llamar al controlador para verificar el email y el PIN
                                    final response = await _accountController.verifyEmailAndPin(email, pin);

                                    // Manejar la respuesta
                                    if (response['success'] == false) {
                                      setState(() {
                                        _emailErrorMessage = '';  
                                        _pinErrorMessage = response['message']; 
                                      });
                                    } else {
                                      // Si la verificación es exitosa, proceder
                                      setState(() {
                                        _isVerified = true;
                                        _isReadOnly = true;
                                      });
                                    }

                                    setState(() {
                                      _isLoading = false;
                                    });
                                },

                              child: _isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Enviar',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),


                        if (_isVerified) ...[
                          const Text(
                            'Nueva Contraseña',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          CustomTextField(icon: Icons.visibility, hint: '', isPassword: true, controller: _newPasswordController),
                          const SizedBox(height: 10),
                          const Text(
                            'Repetir Contraseña',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          CustomTextField(icon: Icons.visibility, hint: '', isPassword: true, controller: _repeatPasswordController),
                           if (_passwordErrorMessage.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                _passwordErrorMessage,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          Center(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFAD0000),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  side: const BorderSide(color: Colors.white, width: 3),
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.1,
                                  vertical: screenHeight * 0.02,
                                ),
                              ),
                              onPressed: _isSubmitting
                                  ? null
                                  : () async {
                                      final newPass = _newPasswordController.text.trim();
                                      final repeatPass = _repeatPasswordController.text.trim();

                                        // Validar las contraseñas antes de proceder
                                        if (newPass.isEmpty || repeatPass.isEmpty) {
                                          setState(() {
                                            _passwordErrorMessage = 'Por favor, ingrese ambas contraseñas';
                                          });
                                          return;
                                        }

                                        if (newPass != repeatPass) {
                                          setState(() {
                                            _passwordErrorMessage = 'Las contraseñas no coinciden';
                                          });
                                          return;
                                        }

                                        // Validar si las contraseñas cumplen con los requisitos
                                        if (!RegExp(r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[@$!%*?&_-])[A-Za-z\d@$!%*?&_-]{8,}$').hasMatch(newPass)) {
                                          setState(() {
                                            _passwordErrorMessage = 'La contraseña debe tener al menos 8 caracteres, incluir mayúsculas, minúsculas, números y símbolos';
                                          });
                                          return;
                                        }

                                        // Si las contraseñas son válidas, eliminamos el mensaje de error
                                        setState(() {
                                          _passwordErrorMessage = '';
                                        });

                                        setState(() {
                                          _isSubmitting = true;
                                        });

                                      final email = _emailController.text.trim();
                                      final pin = _pinController.text.trim();

                                      setState(() {
                                        _isSubmitting = true;
                                      });

                                      final success = await _accountController.updatePassword(email, pin, newPass);

                                      setState(() {
                                        _isSubmitting = false;
                                      });

                                      if (success && context.mounted) {
                                        _showSuccessDialog();
                                      } else {
                                        _showErrorDialog();
                                      }
                                    },
                              child: _isSubmitting
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Restablecer Contraseña',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),

                        ],

                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
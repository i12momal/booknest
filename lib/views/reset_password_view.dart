import 'package:booknest/controllers/account_controller.dart';
import 'package:booknest/views/login_view.dart';
import 'package:booknest/widgets/background.dart';
import 'package:booknest/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ResetPasswordView extends StatefulWidget {
  final bool fromDeepLink;

  const ResetPasswordView({super.key, this.fromDeepLink = false});

  @override
  State<ResetPasswordView> createState() => _ResetPasswordViewState();
}

class _ResetPasswordViewState extends State<ResetPasswordView> {
  final _emailController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _repeatPasswordController = TextEditingController();

  String _emailErrorMessage = '';
  String _passwordErrorMessage = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _emailController.addListener(() {
      if (_emailErrorMessage.isNotEmpty && _emailController.text.isNotEmpty) {
        setState(() {
          _emailErrorMessage = '';
        });
      }
    });

    _newPasswordController.addListener(() {
      if (_passwordErrorMessage.isNotEmpty) {
        setState(() => _passwordErrorMessage = '');
      }
    });

    _repeatPasswordController.addListener(() {
      if (_passwordErrorMessage.isNotEmpty) {
        setState(() => _passwordErrorMessage = '');
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _newPasswordController.dispose();
    _repeatPasswordController.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _emailErrorMessage = 'Ingresa tu correo electrónico');
      return;
    }

    setState(() {
      _isLoading = true;
      _emailErrorMessage = '';
    });

    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'booknest://reset-password',
      );

      FocusScope.of(context).unfocus();

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Correo enviado'),
            content: const Text('Revisa tu correo y sigue el enlace para continuar.'),
            actions: [
              TextButton(
                onPressed: () {
                  FocusScope.of(context).requestFocus(FocusNode());
                  Navigator.of(context).pop();
                },
                child: const Text('Aceptar'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      final errorMessage = e.toString();
      setState(() {
        if (errorMessage.contains('Unable to validate email address') || errorMessage.contains('validation_failed')) {
          _emailErrorMessage = 'El correo introducido no existe';
        } else {
          _emailErrorMessage = 'Error: Inténtelo de nuevo más tarde';
        }
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    final newPassword = _newPasswordController.text.trim();
    final repeatPassword = _repeatPasswordController.text.trim();

    if (newPassword != repeatPassword) {
      setState(() => _passwordErrorMessage = 'Las contraseñas no coinciden');
      return;
    }

    if (newPassword.isEmpty || repeatPassword.isEmpty) {
      setState(() => _passwordErrorMessage = 'Introduzca todos los campos');
      return;
    }

    if (newPassword.isNotEmpty && repeatPassword.isNotEmpty && !RegExp(r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[@$!%*?&_-])[A-Za-z\d@$!%*?&_-]{8,}$')
        .hasMatch(newPassword)) {
      setState(() => _passwordErrorMessage =
          'Debe tener una longitud mínima de 8 caracteres y contener mayúsculas, minúsculas, números y carácteres especiales');
      return;
    }

    setState(() {
      _passwordErrorMessage = '';
      _isLoading = true;
    });

    try {
      final session = Supabase.instance.client.auth.currentSession;
      final user = Supabase.instance.client.auth.currentUser;

      if (session == null || user == null) {
        setState(() => _passwordErrorMessage =
            'Sesión no activa. Abre el enlace desde tu correo nuevamente.');
        return;
      }

      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      final newPasswordHash = AccountController().generatePasswordHash(newPassword);
      await Supabase.instance.client.from('User').update({
        'password': newPasswordHash,
        'confirmPassword': newPasswordHash,
      }).eq('id', user.id);

      if (context.mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      final errorMessage = e.toString();
      setState(() {
        if (errorMessage.contains('New password should be different from the old password')) {
          _emailErrorMessage = 'La nueva contraseña debe ser distinta a la anterior.';
        } else {
          _emailErrorMessage = 'Error: Inténtelo de nuevo más tarde';
        }
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Éxito'),
        content: const Text('¡Contraseña actualizada!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginView()),
                (route) => false,
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
  final screenWidth = MediaQuery.of(context).size.width;
  final screenHeight = MediaQuery.of(context).size.height;

  final isMobile = screenWidth < 600;
  final isTablet = screenWidth >= 600 && screenWidth < 1024;
  final isDesktop = screenWidth >= 1024;

  final maxContainerWidth = isMobile
      ? screenWidth * 0.95
      : isTablet
          ? 450.0
          : 500.0;

  return GestureDetector(
    onTap: () => FocusScope.of(context).unfocus(),
    child: Background(
      title: 'Recuperar Contraseña',
      showNotificationIcon: false,
      onBack: () => Navigator.pop(context),
      child: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 16.0 : 32.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContainerWidth),
            child: Column(
              children: [
                SizedBox(height: screenHeight * 0.05),
                Image.asset(
                  'assets/images/reset_password.jpg',
                  height: isMobile
                      ? screenHeight * 0.25
                      : isTablet
                          ? screenHeight * 0.30
                          : screenHeight * 0.35,
                ),
                SizedBox(height: screenHeight * 0.08),
                _buildGradientCard(screenWidth, screenHeight, isMobile),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

Widget _buildGradientCard(double screenWidth, double screenHeight, bool isMobile) {
  return Container(
    width: double.infinity,
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
    padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
    child: widget.fromDeepLink
        ? _buildPasswordFields(screenHeight, screenWidth)
        : _buildEmailField(screenHeight, screenWidth),
  );
}

  Widget _buildEmailField(double screenHeight, double screenWidth) {
    return Column(
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
        CustomTextField(
          icon: Icons.email,
          hint: '',
          controller: _emailController,
        ),
        if (_emailErrorMessage.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              _emailErrorMessage,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        SizedBox(height: screenHeight * 0.03),
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
            onPressed: _isLoading ? null : _sendResetLink,
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
                    'Enviar enlace',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordFields(double screenHeight, double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nueva Contraseña',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: screenHeight * 0.01),
        CustomTextField(
          icon: Icons.lock,
          hint: '',
          controller: _newPasswordController,
          isPassword: true,
        ),
        const SizedBox(height: 16),
        const Text(
          'Confirmar Contraseña',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: screenHeight * 0.01),
        CustomTextField(
          icon: Icons.lock_outline,
          hint: '',
          controller: _repeatPasswordController,
          isPassword: true,
        ),
        if (_passwordErrorMessage.isNotEmpty)
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
        SizedBox(height: screenHeight * 0.03),
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
            onPressed: _isLoading ? null : _resetPassword,
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
                    'Actualizar contraseña',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}


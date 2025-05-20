import 'package:booknest/controllers/account_controller.dart';
import 'package:booknest/views/login_view.dart';
import 'package:booknest/widgets/success_dialog.dart';
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

  // Enviar enlace de restablecimiento
  Future<void> _sendResetLink() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _emailErrorMessage = 'Ingresa tu correo');
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

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Correo enviado'),
            content: const Text('Revisa tu correo y sigue el enlace para continuar.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() => _emailErrorMessage = 'Error: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Restablecer contraseña desde el enlace
  Future<void> _resetPassword() async {
    final newPassword = _newPasswordController.text.trim();
    final repeatPassword = _repeatPasswordController.text.trim();

    if (newPassword != repeatPassword) {
      setState(() => _passwordErrorMessage = 'Las contraseñas no coinciden');
      return;
    }

    if (!RegExp(r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[@$!%*?&_-])[A-Za-z\d@$!%*?&_-]{8,}$')
        .hasMatch(newPassword)) {
      setState(() => _passwordErrorMessage =
          'Debe tener 8+ caracteres, mayúsculas, minúsculas, número y símbolo');
      return;
    }

    setState(() {
      _passwordErrorMessage = '';
      _isLoading = true;
    });

    try {
      final session = Supabase.instance.client.auth.currentSession;

      if (session == null) {
        setState(() => _passwordErrorMessage =
            'Sesión no activa. Abre el enlace desde tu correo nuevamente.');
        return;
      }

      final user = Supabase.instance.client.auth.currentUser;

      if (user == null) {
        setState(() => _passwordErrorMessage =
            'No se pudo recuperar el usuario actual.');
        return;
      }

      // 1. Actualizar la contraseña del sistema de auth
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      // 2. Actualizar los campos personalizados
      final newPasswordHash = AccountController().generatePasswordHash(newPassword);
      await Supabase.instance.client.from('User').update({
        'password': newPasswordHash,
        'confirmPassword': newPasswordHash,
      }).eq('id', user.id);

      if (context.mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      setState(() => _passwordErrorMessage = 'Error: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog() {
    SuccessDialog.show(
      context,
      'Éxito',
      '¡Contraseña actualizada!',
      () {
        Navigator.pop(context);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginView()),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar Contraseña')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: widget.fromDeepLink ? _buildPasswordForm() : _buildEmailForm(),
      ),
    );
  }

  Widget _buildEmailForm() {
    return Column(
      children: [
        TextField(
          controller: _emailController,
          decoration: InputDecoration(
            labelText: 'Correo Electrónico',
            errorText: _emailErrorMessage.isEmpty ? null : _emailErrorMessage,
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _isLoading ? null : _sendResetLink,
          child: _isLoading
              ? const CircularProgressIndicator()
              : const Text('Enviar enlace'),
        ),
      ],
    );
  }

  Widget _buildPasswordForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Ingresa tu nueva contraseña'),
        const SizedBox(height: 20),
        TextField(
          controller: _newPasswordController,
          decoration: const InputDecoration(labelText: 'Nueva contraseña'),
          obscureText: true,
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _repeatPasswordController,
          decoration: const InputDecoration(labelText: 'Repetir contraseña'),
          obscureText: true,
        ),
        if (_passwordErrorMessage.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _passwordErrorMessage,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _isLoading ? null : _resetPassword,
          child: _isLoading
              ? const CircularProgressIndicator()
              : const Text('Actualizar contraseña'),
        ),
      ],
    );
  }
}

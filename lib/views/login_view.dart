import 'package:booknest/controllers/account_controller.dart';
import 'package:booknest/views/edit_book_view.dart';
import 'package:booknest/views/home_view.dart';
import 'package:booknest/views/owner_profile_view.dart';
import 'package:flutter/material.dart';
import 'package:booknest/views/register_view.dart';
import 'package:booknest/views/reset_password_view.dart';
import 'package:booknest/widgets/background.dart';
import 'package:booknest/widgets/custom_text_field.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _userNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final AccountController _accountController = AccountController();

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Background(
        title: 'Iniciar Sesión',
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
                Image.asset(
                  'assets/images/login_image.png',
                  height: screenHeight * 0.3,
                ),
                SizedBox(height: screenHeight * 0.03),
                Container(
                  width: screenWidth * 0.9,
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
                        'Usuario',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.01),
                      CustomTextField(icon: Icons.account_circle, hint: '', controller: _userNameController),
                      SizedBox(height: screenHeight * 0.02),
                      const Text(
                        'Contraseña',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.01),
                      CustomTextField(icon: Icons.visibility, hint: '', isPassword: true, controller: _passwordController),
                      ValueListenableBuilder<String>(
                        valueListenable: _accountController.errorMessage,
                        builder: (context, error, _) {
                          return error.isEmpty
                              ? Container() // Si no hay error, no mostramos nada
                              : Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    error, // El mensaje de error
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 14
                                    ),
                                  ),
                                );
                        },
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      Align(
                        alignment: Alignment.center,
                        child: FittedBox(
                          fit: BoxFit.scaleDown, 
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const RegisterView()),
                              );
                            },
                            child: const Text(
                              '¿No tiene una cuenta? Cree una aquí',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.center,
                        child: FittedBox(
                          fit: BoxFit.scaleDown, 
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const ResetPasswordView()),
                              );
                            },
                            child: const Text(
                              '¿Ha olvidado su contraseña?',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.02),
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
                          onPressed: () async {
                            FocusScope.of(context).unfocus();
                            await _accountController.login(
                              _userNameController.text.trim(),
                              _passwordController.text.trim()
                            );

                            if (_accountController.errorMessage.value.isEmpty && context.mounted) {
                              final userId = await _accountController.getCurrentUserId();
                              print("Id del usuario que acaba de iniciar sesión: $userId");
                              if (userId != null && context.mounted) {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    //builder: (context) => EditUserView(userId: userId),
                                    //builder: (context) => const AddBookView(),
                                    //builder: (context) => const EditBookView(bookId: 2),
                                    builder: (context) => const HomeView(),
                                    //builder: (context) => const OwnerProfileView(userId: '3ff9ad25-2c42-449b-b453-6f7bdb8f15ac'),
                                  ),
                                );
                              }
                            } 
                          },
                          child: const Text(
                            'Iniciar Sesión',
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:booknest/entities/models/user_model.dart';
import 'package:booknest/views/home_view.dart';
import 'package:booknest/views/owner_profile_view.dart';
import 'package:booknest/views/user_profile_view.dart';
import 'package:flutter/material.dart'; 
import 'services/base_service.dart';
import 'views/login_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializamos Supabase antes de correr la aplicación
  await BaseService.initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BookNest',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'BookNest Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HomeView()),
                );
              },
              style: ElevatedButton.styleFrom(
                minimumSize: Size(screenWidth * 0.8, 50),
                backgroundColor: const Color(0xFF61BBFF),
                side: const BorderSide(
                  color: Colors.white,
                  width: 2,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              ),
              child: const Text(
                'Home View',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20), // Espacio entre los botones
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginView()),
                );
              },
              style: ElevatedButton.styleFrom(
                minimumSize: Size(screenWidth * 0.8, 50),
                backgroundColor: const Color(0xFF61BBFF),
                side: const BorderSide(
                  color: Colors.white,
                  width: 2,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              ),
              child: const Text(
                'Login',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const OwnerProfileView(userId: 'c3560a09-f261-4f39-ae15-bf6d16ea9b2b')),
                );
              },
              style: ElevatedButton.styleFrom(
                minimumSize: Size(screenWidth * 0.8, 50),
                backgroundColor: const Color(0xFF61BBFF),
                side: const BorderSide(
                  color: Colors.white,
                  width: 2,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              ),
              child: const Text(
                'Profile owner',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UserProfileView(userId: 'c3560a09-f261-4f39-ae15-bf6d16ea9b2b')),
                );
              },
              style: ElevatedButton.styleFrom(
                minimumSize: Size(screenWidth * 0.8, 50),
                backgroundColor: const Color(0xFF61BBFF),
                side: const BorderSide(
                  color: Colors.white,
                  width: 2,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              ),
              child: const Text(
                'Profile user',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
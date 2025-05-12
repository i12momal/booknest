import 'package:booknest/views/register_view.dart';
import 'package:flutter/material.dart'; 
import 'services/base_service.dart';
import 'views/login_view.dart';
import 'package:video_player/video_player.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
      home: const SplashVideoPage(),
    );
  }
}

// SplashVideoPage que muestra el video de introducción
class SplashVideoPage extends StatefulWidget {
  const SplashVideoPage({super.key});

  @override
  State<SplashVideoPage> createState() => _SplashVideoPageState();
}

class _SplashVideoPageState extends State<SplashVideoPage> with TickerProviderStateMixin {
  late VideoPlayerController _controller;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _videoFadeAnimation; // Animación específica para desvanecer el video
  bool _showHome = false;

  @override
  void initState() {
    super.initState();

    _controller = VideoPlayerController.asset('assets/gifs/plumas2.mp4')
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
      });

    // Animation controller para desvanecer el video y la página de inicio
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600), // Duración extendida para el fade de los elementos
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    // Animación de desvanecimiento del video (se vuelve más transparente)
    _videoFadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeInOut,
      ),
    );

    _controller.addListener(() {
      if (_controller.value.position >= _controller.value.duration - const Duration(seconds: 2) && !_showHome) {
        _fadeController.forward();
        _showHome = true;

        // Esperar a que termine el fade y luego navegar
        Future.delayed(const Duration(milliseconds: 1600), () {
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 800),
              pageBuilder: (_, __, ___) => const MyHomePage(title: ''),
              transitionsBuilder: (_, animation, __, child) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
            ),
          );
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FadeTransition(
            opacity: _fadeAnimation,
            child: const MyHomePage(title: ''),
          ),

          // Video que se desvanece después de un tiempo
          _controller.value.isInitialized
              ? FadeTransition(
                  opacity: _videoFadeAnimation, // Aquí aplicamos el desvanecimiento al video
                  child: SizedBox.expand(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _controller.value.size.width,
                        height: _controller.value.size.height,
                        child: VideoPlayer(_controller),
                      ),
                    ),
                  ),
                )
              : const SizedBox.expand(child: ColoredBox(color: Colors.white)),
        ],
      ),
    );
  }
}


// MyHomePage con animaciones escalonadas para cada elemento
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _titleAnimation;
  late Animation<double> _logoAnimation;
  late Animation<double> _buttonsAnimation;

  @override
  void initState() {
    super.initState();

    // Inicialización de los controladores de animación (sin iniciar aún)
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    // Animaciones escalonadas para cada elemento (sin iniciar aún)
    _titleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: const Interval(0.0, 0.3, curve: Curves.easeIn)),
    );
    _logoAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: const Interval(0.3, 0.6, curve: Curves.easeIn)),
    );
    _buttonsAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: const Interval(0.6, 1.0, curve: Curves.easeIn)),
    );

      _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              width: screenWidth * 0.98,
              height: screenHeight * 0.95,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF112363), width: 4),
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 35),
              child: Column(
                children: [
                  // Título con animación de desvanecimiento
                  FadeTransition(
                    opacity: _titleAnimation,
                    child: Image.asset(
                      'assets/images/titulo.png',
                      width: double.infinity,
                      height: screenHeight * 0.15,
                      fit: BoxFit.contain,
                    ),
                  ),
                  // Logo con animación de desvanecimiento
                  Expanded(
                    child: Center(
                      child: FadeTransition(
                        opacity: _logoAnimation,
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: screenWidth * 0.9,
                          height: screenHeight * 0.6,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  // Contenedor de botones con animación de desvanecimiento
                  FadeTransition(
                    opacity: _buttonsAnimation,
                    child: Container(
                      width: screenWidth * 0.85,
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
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LoginView(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              minimumSize: Size(screenWidth * 0.8, 50),
                              backgroundColor: const Color(0xFFAD0000),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                                side: const BorderSide(color: Colors.white, width: 3),
                              ),
                            ),
                            child: const Text(
                              'Iniciar Sesión',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const RegisterView(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              minimumSize: Size(screenWidth * 0.8, 50),
                              backgroundColor: const Color(0xFFAD0000),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                                side: const BorderSide(color: Colors.white, width: 3),
                              ),
                            ),
                            child: const Text(
                              'Registro',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
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
          ),
        ),
      ),
    );
  }
}
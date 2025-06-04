import 'package:booknest/views/login_view.dart';
import 'package:booknest/views/register_view.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

// Vista para la acción de Mostrar el vídeo al iniciar la aplicación
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
        Future.delayed(Duration.zero, () {
          if (mounted) {
            setState(() {});
            _controller.play();
          }
        });
      });

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _videoFadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeInOut,
      ),
    );

    _controller.addListener(() {
      if (_controller.value.isInitialized &&
          _controller.value.position >= _controller.value.duration - const Duration(seconds: 2) &&
          !_showHome) {
        _fadeController.forward();
        _showHome = true;

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
                  opacity: _videoFadeAnimation, // Desvanecimiento al video
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

    bool isMobile = screenWidth < 600;
    bool isTablet = screenWidth >= 600 && screenWidth < 1024;

    double maxContainerWidth = isMobile
        ? screenWidth * 0.9
        : isTablet
            ? 450
            : 500;

    double horizontalPadding = isMobile ? screenWidth * 0.05 : 30;

    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        child: Transform.translate(
          offset: const Offset(0, 11),
          child: Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                width: screenWidth * 0.99,
                height: screenHeight * 0.95,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF112363), width: 4),
                  borderRadius: BorderRadius.circular(20),
                ),
                clipBehavior: Clip.none,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 55),
                      child: Column(
                        children: [
                          const SizedBox(height: 100),

                          // Imagen de logo
                          FadeTransition(
                            opacity: _logoAnimation,
                            child: Image.asset(
                              'assets/images/logo.png',
                              width: screenWidth * 0.9,
                              height: screenHeight * 0.43,
                              fit: BoxFit.contain,
                            ),
                          ),
                          
                          // Botones
                          FadeTransition(
                            opacity: _buttonsAnimation,
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(maxWidth: maxContainerWidth),
                                child: Container(
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
                                  padding: EdgeInsets.symmetric(
                                    horizontal: screenWidth * 0.05,
                                    vertical: 50,
                                  ),
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
                                      const SizedBox(height: 40),
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
                            ),
                          ),
                        ],
                      ),
                    ),

                    // AppBar
                      Container(
                        height: 160,
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF112363), Color(0xFF2140AF)],
                            begin: Alignment.topLeft,
                            end: Alignment.centerRight,
                            stops: [0.42, 0.74],
                          ),
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                            topLeft: Radius.circular(14),
                            topRight: Radius.circular(14),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          widget.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                    // Imagen encima del AppBar
                    Positioned(
                      top: 40,
                      left: 0,
                      right: 0,
                      child: FadeTransition(
                        opacity: _titleAnimation,
                        child: Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.asset(
                              'assets/images/titulo.png',
                              height: 80,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

}
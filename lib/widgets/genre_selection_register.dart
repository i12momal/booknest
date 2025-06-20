import 'package:flutter/material.dart';
import 'package:booknest/views/login_view.dart';
import 'package:booknest/widgets/genre_chip.dart';

// Widget para el container de selección de categorías en el registro de un usuario
class GenreSelectionRegisterWidget extends StatelessWidget {
  final List<String> genres;
  final List<String> selectedGenres;
  final String message;
  final ValueChanged<String> onGenreSelected;
  final VoidCallback onRegister;
  final bool isEditMode;
  final bool isLoading;

  const GenreSelectionRegisterWidget({
    super.key,
    required this.isEditMode,
    required this.genres,
    required this.selectedGenres,
    required this.message,
    required this.onGenreSelected,
    required this.onRegister,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final containerHeight = isMobile ? 450.0 : 300.0;
        final horizontalPadding = isMobile ? 16.0 : 64.0;

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Text(
                    'Seleccione sus géneros favoritos',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 5),
                  Icon(Icons.favorite_border, size: 20),
                ],
              ),
              const SizedBox(height: 18),

              // El contenido que puede crecer, lo hacemos scrollable y lo metemos en Expanded para que ocupe el espacio disponible
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(
                        height: containerHeight,
                        child: Container(
                          width: constraints.maxWidth,
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
                          padding: const EdgeInsets.all(16.0),
                          child: Scrollbar(
                            child: SingleChildScrollView(
                              child: Wrap(
                                spacing: 16.0,
                                runSpacing: 12.0,
                                children: genres.map((genre) => GenreChip(
                                  genre: genre,
                                  isSelected: selectedGenres.contains(genre),
                                  onTap: () => onGenreSelected(genre),
                                )).toList(),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),
                      Text(message, style: const TextStyle(color: Color(0xFFAD0000))),

                      const SizedBox(height: 20),

                      if (!isEditMode) ...[
                        Align(
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const LoginView()),
                                    );
                                  },
                                  child: const Text(
                                    '¿Ya tiene una cuenta? ¡Inicie sesión!',
                                    style: TextStyle(color: Colors.black),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: isLoading ? null : () async {
                                  onRegister();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFAD0000),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                    side: const BorderSide(color: Color(0xFF700101), width: 3),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                                ),
                                child: isLoading 
                                    ? const CircularProgressIndicator(backgroundColor: Color(0xFFAD0000), color: Color(0xFFFFFFFF))
                                    : const Text(
                                        "Registrarse",
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
                      ] else ...[
                        Align(
                          alignment: Alignment.center,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : onRegister,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFAD0000),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                                side: const BorderSide(color: Color(0xFF700101), width: 3),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                            ),
                            child: isLoading 
                                ? const CircularProgressIndicator(backgroundColor: Color(0xFFAD0000), color: Color(0xFFFFFFFF))
                                : const Text(
                                    "Guardar",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

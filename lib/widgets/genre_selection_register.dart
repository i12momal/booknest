import 'package:flutter/material.dart';
import 'package:booknest/views/login_view.dart';
import 'package:booknest/widgets/genre_chip.dart';

class GenreSelectionRegisterWidget extends StatelessWidget {
  final List<String> genres;
  final List<String> selectedGenres;
  final String message;
  final ValueChanged<String> onGenreSelected;
  final VoidCallback onRegister;
  final bool isEditMode;

  const GenreSelectionRegisterWidget({
    super.key,
    required this.isEditMode,
    required this.genres,
    required this.selectedGenres,
    required this.message,
    required this.onGenreSelected,
    required this.onRegister,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
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

              // Contenedor desplazable
              SizedBox(
                height: 300, // Altura máxima antes de permitir el scroll
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

              const Spacer(),

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
                        onPressed: onRegister,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFAD0000),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                            side: const BorderSide(color: Color.fromARGB(255, 112, 1, 1), width: 3),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                        ),
                        child: const Text(
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
                    onPressed: onRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFAD0000),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                        side: const BorderSide(color: Color.fromARGB(255, 112, 1, 1), width: 3),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    ),
                    child: const Text(
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
        );
      },
    );
  }

}
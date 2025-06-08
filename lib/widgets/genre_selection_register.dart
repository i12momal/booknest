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
    final ScrollController scrollController = ScrollController();
    final isWeb = MediaQuery.of(context).size.width > 600;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = isWeb ? 600.0 : constraints.maxWidth;

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título e ícono en línea
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        'Seleccione sus géneros favoritos',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.favorite_border, size: 20),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Contenedor con scroll
                  SizedBox(
                    height: 450,
                    child: Container(
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
                        controller: scrollController,
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          controller: scrollController,
                          child: Wrap(
                            spacing: 16.0,
                            runSpacing: 12.0,
                            alignment: WrapAlignment.center,
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
                  Text(
                    message,
                    style: const TextStyle(color: Color(0xFFAD0000)),
                    textAlign: TextAlign.center,
                  ),

                  const Spacer(),

                  // Botón y texto inferior
                  Align(
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        if (!isEditMode)
                          Column(
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
                            ],
                          ),
                        ElevatedButton(
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
                              ? const CircularProgressIndicator(
                                  backgroundColor: Color(0xFFAD0000),
                                  color: Color(0xFFFFFFFF),
                                )
                              : Text(
                                  isEditMode ? "Guardar" : "Registrarse",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
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
        );
      },
    );
  }
}

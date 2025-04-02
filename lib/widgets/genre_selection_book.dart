import 'package:flutter/material.dart';
import 'package:booknest/widgets/genre_chip.dart';

class GenreSelectionBookWidget extends StatelessWidget {
  final List<String> genres;
  final List<String> selectedGenres;
  final String message;
  final ValueChanged<String> onGenreSelected;
  final VoidCallback onRegister;
  final bool isEditMode;

  const GenreSelectionBookWidget({
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título con icono
        const Row(
          children: [
            Text(
              'Géneros asociados',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(width: 8),
            Icon(
              Icons.favorite_border,
              size: 18,
              color: Colors.black,
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Contenedor con scroll si hay muchos géneros
        Container(
          width: double.infinity,
          height: 300, // Altura máxima con scroll
          padding: const EdgeInsets.all(16.0),
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
          child: Scrollbar(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 12.0,
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
        const SizedBox(height: 2),
        
        Text(
          message,
          style: const TextStyle(color: Color(0xFFAD0000)),
        ),
        const SizedBox(height: 2),

        Align(
          alignment: Alignment.center,
          child: ElevatedButton(
            onPressed: onRegister,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFAD0000),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
                side: const BorderSide(
                  color: Color.fromARGB(255, 112, 1, 1),
                  width: 3,
                ),
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
      ],
    );
  }
}

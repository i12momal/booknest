import 'package:booknest/widgets/genre_selection_book.dart';
import 'package:booknest/widgets/summary_input.dart';
import 'package:flutter/material.dart';

class GenreAndSummarySelectionWidget extends StatelessWidget {
  final List<String> genres;
  final List<String> selectedGenres;
  final String message;
  final ValueChanged<String> onGenreSelected;
  final VoidCallback onRegister;
  final TextEditingController summaryController;
  final bool isEditMode;

  const GenreAndSummarySelectionWidget({
    super.key,
    required this.isEditMode,
    required this.genres,
    required this.selectedGenres,
    required this.message,
    required this.onGenreSelected,
    required this.onRegister,
    required this.summaryController,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView( 
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Primer widget: Resumen
            SummaryInputWidget(controller: summaryController),

            const SizedBox(height: 30),

            // Segundo widget: Selección de géneros
            GenreSelectionBookWidget(
              isEditMode: isEditMode,
              genres: genres,
              selectedGenres: selectedGenres,
              message: message,
              onGenreSelected: onGenreSelected,
              onRegister: onRegister,
            ),
          ],
        ),
      ),
    );
  }
}

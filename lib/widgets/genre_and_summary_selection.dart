import 'package:booknest/widgets/genre_selection_book.dart';
import 'package:booknest/widgets/summary_input.dart';
import 'package:flutter/material.dart';

class GenreAndSummarySelectionWidget extends StatefulWidget {
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
  State<GenreAndSummarySelectionWidget> createState() => _GenreAndSummarySelectionWidgetState();
}

class _GenreAndSummarySelectionWidgetState
    extends State<GenreAndSummarySelectionWidget> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Primer widget: Resumen
            SummaryInputWidget(controller: widget.summaryController),

            const SizedBox(height: 30),

            // Segundo widget: Selección de géneros
            GenreSelectionBookWidget(
              isEditMode: widget.isEditMode,
              genres: widget.genres,
              selectedGenres: widget.selectedGenres,
              message: widget.message,
              onGenreSelected: widget.onGenreSelected,
              onRegister: widget.onRegister,
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:booknest/widgets/genre_selection_book.dart';
import 'package:booknest/widgets/summary_input.dart';
import 'package:flutter/material.dart';

class GenreAndSummarySelectionWidget extends StatefulWidget {
  final List<String> genres;
  final List<String> selectedGenres;
  final String summaryError;
  final String genreError;
  final ValueChanged<String> onGenreSelected;
  final VoidCallback onRegister;
  final TextEditingController summaryController;
  final bool isEditMode;
  final bool isLoading;
  final VoidCallback onSummaryChanged;

  const GenreAndSummarySelectionWidget({
    super.key,
    required this.isEditMode,
    required this.genres,
    required this.selectedGenres,
    required this.onGenreSelected,
    required this.onRegister,
    required this.summaryController,
    required this.isLoading,
    required this.summaryError,
    required this.genreError,
    required this.onSummaryChanged,
  });

  @override
  State<GenreAndSummarySelectionWidget> createState() => _GenreAndSummarySelectionWidgetState();
}

class _GenreAndSummarySelectionWidgetState extends State<GenreAndSummarySelectionWidget> {

  @override
  void initState() {
    super.initState();
    widget.summaryController.addListener(_onSummaryChanged);
  }

  void _onSummaryChanged() {
    if (widget.summaryError.isNotEmpty) {
      widget.onSummaryChanged();
    }
  }

  @override
  void dispose() {
    widget.summaryController.removeListener(_onSummaryChanged);
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Primer widget: Resumen
            SummaryInputWidget(
              controller: widget.summaryController,
              onChanged: widget.onSummaryChanged,
            ),

            // Mostrar mensaje de error si existe
            if (widget.summaryError.isNotEmpty) 
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Text(
                  widget.summaryError,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                  ),
                ),
              ),

            const SizedBox(height: 30),

            // Segundo widget: Selección de géneros
            GenreSelectionBookWidget(
              isEditMode: widget.isEditMode,
              genres: widget.genres,
              selectedGenres: widget.selectedGenres,
              message: widget.genreError,
              onGenreSelected: widget.onGenreSelected,
              onRegister: widget.onRegister,
              isLoading: widget.isLoading,
            ),
          ],
        ),
      ),
    );
  }
}

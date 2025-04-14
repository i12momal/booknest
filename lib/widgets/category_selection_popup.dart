import 'package:booknest/widgets/genre_chip.dart';
import 'package:flutter/material.dart';

class CategorySelectionPopup extends StatelessWidget {
  final List<String> allCategories;
  final List<String> selectedCategories;
  final ValueChanged<String> onCategorySelected;
  final VoidCallback onSave;

  const CategorySelectionPopup({
    super.key,
    required this.allCategories,
    required this.selectedCategories,
    required this.onCategorySelected,
    required this.onSave,
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
                    'Seleccione las categorías',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 5),
                  Icon(Icons.favorite_border, size: 20),  // Icono de categoría
                ],
              ),
              const SizedBox(height: 18),

              // Contenedor desplazable para categorías
              Container(
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
                      alignment: WrapAlignment.start,  // Centra los chips horizontalmente
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: allCategories.map((category) => GenreChip(
                        genre: category,
                        isSelected: selectedCategories.contains(category),
                        onTap: () => onCategorySelected(category),
                      )).toList(),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Botón para confirmar la selección
              Align(
                alignment: Alignment.center,
                child: ElevatedButton(
                  onPressed: onSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFAD0000),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                      side: const BorderSide(color: Color.fromARGB(255, 112, 1, 1), width: 3),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  ),
                  child: const Text(
                    "Confirmar Selección",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
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

import 'package:booknest/widgets/genre_chip.dart';
import 'package:flutter/material.dart';

class CategorySelectionPopup extends StatefulWidget {
  final List<String> allCategories;
  final List<String> selectedCategories;
  final void Function(List<String>) onSave;
  final bool isLoading;

  const CategorySelectionPopup({
    super.key,
    required this.allCategories,
    required this.selectedCategories,
    required this.onSave,
    this.isLoading = false,
  });

  @override
  State<CategorySelectionPopup> createState() => _CategorySelectionPopupState();
}

class _CategorySelectionPopupState extends State<CategorySelectionPopup> {
  late List<String> _selectedCategories;

  @override
  void initState() {
    super.initState();
    _selectedCategories = List.from(widget.selectedCategories);
  }

  void _toggleSelection(String category) {
    setState(() {
      if (_selectedCategories.contains(category)) {
        _selectedCategories.remove(category);
      } else {
        _selectedCategories.add(category);
      }
    });
  }

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
                  Icon(Icons.favorite_border, size: 20),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 250,
                child: Container(
                  width: constraints.maxWidth,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF687CFF), Color(0xFF2E3C94)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF112363), width: 3),
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
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: widget.allCategories.map((category) {
                          return GenreChip(
                            genre: category,
                            isSelected: _selectedCategories.contains(category),
                            onTap: () => _toggleSelection(category),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.center,
                child: widget.isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                  onPressed: () => widget.onSave(_selectedCategories),
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

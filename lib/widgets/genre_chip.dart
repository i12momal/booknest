import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';

class GenreChip extends StatelessWidget {
  final String genre;
  final bool isSelected;
  final VoidCallback onTap;

  const GenreChip({
    super.key,
    required this.genre,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFAD0000) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.white : const Color(0xFF112363),
            width: 2,
          ),
        ),
        child: AutoSizeText(
          genre,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}

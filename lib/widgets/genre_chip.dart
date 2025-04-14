import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';

class GenreChip extends StatelessWidget {
  final String genre;
  final bool isSelected;
  final VoidCallback onTap;
  final double fontSize;  // Añadir un parámetro para controlar el tamaño de la fuente

  const GenreChip({
    super.key,
    required this.genre,
    required this.isSelected,
    required this.onTap,
    this.fontSize = 14.0,  // Valor por defecto para el tamaño de la fuente
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),  // Reducir el padding
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFAD0000) : Colors.white,
          borderRadius: BorderRadius.circular(16),  // Reducir el radio del borde
          border: Border.all(
            color: isSelected ? Colors.white : const Color(0xFF112363),
            width: 2,
          ),
        ),
        child: AutoSizeText(
          genre,
          style: TextStyle(
            fontSize: fontSize,  // Cambiar el tamaño de la fuente
            color: isSelected ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}

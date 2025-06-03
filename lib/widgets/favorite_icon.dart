import 'package:booknest/controllers/user_controller.dart';
import 'package:booknest/entities/models/book_model.dart';
import 'package:flutter/material.dart';

// Widget para el icono de favoritos de un libro
class FavoriteIcon extends StatefulWidget {
  final Book book;

  const FavoriteIcon({super.key, required this.book});

  @override
  State<FavoriteIcon> createState() => _FavoriteIconState();
}

class _FavoriteIconState extends State<FavoriteIcon> {
  bool isFavorite = false;

  @override
  void initState() {
    super.initState();
    _checkIfFavorite();
  }

  // Verificar si el libro ya está en favoritos al iniciar
  void _checkIfFavorite() async {
    final result = await UserController().isFavorite(widget.book.id);
    setState(() {
      isFavorite = result['isFavorite'] ?? false;
    });
  }

  // Función que maneja el añadir/quitar un libro de favoritos
  void toggleFavorite() async {
    print("toggleFavorite ha sido llamado");
    
    setState(() {
      isFavorite = !isFavorite;
    });

    if (isFavorite) {
      print("Agregando a favoritos");
      await UserController().addToFavorites(widget.book.id);
    } else {
      print("Eliminando de favoritos");
      await UserController().removeFromFavorites(widget.book.id);
    }
  }


  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        isFavorite ? Icons.favorite : Icons.favorite_border,
        color: isFavorite ? Colors.red : Colors.grey,
      ),
      onPressed: toggleFavorite,
    );
  }

}
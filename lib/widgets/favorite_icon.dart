import 'package:booknest/controllers/book_controller.dart';
import 'package:booknest/entities/models/book_model.dart';
import 'package:flutter/material.dart';

class FavoriteIcon extends StatefulWidget {
  final Book book;

  const FavoriteIcon({super.key, required this.book});

  @override
  State<FavoriteIcon> createState() => _FavoriteIconState();
}

class _FavoriteIconState extends State<FavoriteIcon> {
  bool isFavorite = false;

  void toggleFavorite() async {
    setState(() {
      isFavorite = !isFavorite;
    });

    if (isFavorite) {
      //await BookController().addToFavorites(widget.book.id);
    } else {
      //await BookController().removeFromFavorites(widget.book.id);
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

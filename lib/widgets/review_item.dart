import 'package:flutter/material.dart';

class ReviewItem extends StatelessWidget {
  final String name;
  final int rating;
  final String comment;
  final ImageProvider imageProvider;
  final bool isOwner;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ReviewItem({
    super.key,
    required this.name,
    required this.rating,
    required this.comment,
    required this.imageProvider,
    required this.isOwner,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundImage: imageProvider,
                  radius: 30,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: List.generate(
                          5,
                          (index) => Icon(
                            index < rating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (comment.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 8.0, right: 8.0, top: 8.0),
              child: Text(comment),
            ),

          // Botones de editar y eliminar, solo si es el dueño de la reseña
          if (isOwner)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                    padding: EdgeInsets.zero,
                    onPressed: onEdit,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                    padding: EdgeInsets.zero,
                    onPressed: onDelete,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

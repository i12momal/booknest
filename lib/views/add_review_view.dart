import 'package:booknest/controllers/account_controller.dart';
import 'package:booknest/controllers/review_controller.dart';
import 'package:booknest/entities/models/book_model.dart';
import 'package:booknest/widgets/background.dart';
import 'package:booknest/widgets/tap_bubble_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

// Vista para la acción de Añadir una nueva Reseña
class AddReviewView extends StatefulWidget {
  final Book book;

  const AddReviewView({super.key, required this.book});

  @override
  State<AddReviewView> createState() => _AddReviewViewState();
}

class _AddReviewViewState extends State<AddReviewView> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _commentController = TextEditingController();
  double _rating = 0;
  bool _showRatingError = false;
  bool _showCommentError = false;
  bool _isSubmitting = false;
  String? userId;

  final ReviewController _reviewController = ReviewController();

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  // Función que muestra el dialogo de éxito al añadir una nueva reseña
  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Creación Exitosa'),
        content: const Text('¡Tu reseña ha sido creada con éxito!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, true);
            },
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  // Función para obtener el id del usuario actual
  Future<void> _loadUserId() async {
    final id = await AccountController().getCurrentUserId();
    setState(() {
      userId = id;
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Background(
        title: widget.book.title,
        onBack: () => Navigator.pop(context),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              // Imagen del libro y detalles
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF112363)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        widget.book.cover,
                        height: 140,
                        width: 90,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TapBubbleText(
                            text: widget.book.title,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.person, size: 16, color: Colors.grey),
                              const SizedBox(width: 6),
                              Expanded(
                                child: TapBubbleText(
                                  text: widget.book.author,
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.qr_code, size: 16, color: Colors.grey),
                              const SizedBox(width: 6),
                              Text(widget.book.isbn),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.menu_book, size: 16, color: Colors.grey),
                              const SizedBox(width: 6),
                              Text('${widget.book.pagesNumber} pág'),
                              const SizedBox(width: 12),
                              const Icon(Icons.language, size: 16, color: Colors.grey),
                              const SizedBox(width: 6),
                              Text(widget.book.language),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 45),
              const Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Valoración', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(width: 8),
                    Icon(Icons.star_border),
                  ],
                ),
              ),
              const Divider(thickness: 1, color: Color(0xFF112363)),
              const SizedBox(height: 12),
              // Estrellas
              Center(
                child: RatingBar.builder(
                  initialRating: _rating,
                  minRating: 1,
                  direction: Axis.horizontal,
                  allowHalfRating: false,
                  itemCount: 5,
                  itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
                  onRatingUpdate: (rating) {
                    setState(() {
                      _rating = rating;
                      _showRatingError = false;
                    });
                  },
                ),
              ),
              // Mensaje de error debajo del RatingBar
              if (_showRatingError)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Center(
                    child: Text(
                      'Por favor, selecciona una valoración',
                      style: TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ),
                ),
              const SizedBox(height: 40),
              const Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Comentario', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(width: 8),
                    Icon(Icons.comment),
                  ],
                ),
              ),
              const Divider(thickness: 1, color: Color(0xFF112363)),
              const SizedBox(height: 25),
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2140AF), Color(0xFF6F8DEB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(12),
                child: Form(
                  key: _formKey,
                  child: TextFormField(
                    controller: _commentController,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      hintText: 'Escribe tu reseña aquí...',
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: Colors.black),
                    ),
                    onChanged: (value) {
                      // Eliminar el mensaje de error cuando se escribe algo
                      if (value.trim().isNotEmpty && _showCommentError) {
                        setState(() {
                          _showCommentError = false;
                        });
                      }
                    },
                  ),
                ),
              ),
              // Mensaje de error del comentario debajo del contenedor
              if (_showCommentError)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Center(
                    child: Text(
                      'Por favor, ingresa un comentario',
                      style: TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ),
                ),
              const SizedBox(height: 30),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFAD0000),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                      side: const BorderSide(color: Color(0xFF700101), width: 3),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.2,
                      vertical: screenHeight * 0.015,
                    ),
                  ),
                  onPressed: () async {
                    if (_isSubmitting) return;

                    final isCommentValid = _commentController.text.trim().isNotEmpty;
                    final isRatingValid = _rating > 0;

                    setState(() {
                      _showCommentError = !isCommentValid;
                      _showRatingError = !isRatingValid;
                    });

                    if (isCommentValid && isRatingValid) {
                      setState(() {
                        _isSubmitting = true;
                      });

                      final response = await _reviewController.addReview(
                        _commentController.text.trim(),
                        _rating.toInt(),
                        userId ?? '',
                        widget.book.id,
                      );

                      setState(() {
                        _isSubmitting = false;
                      });

                      if (response['success']) {
                        _showSuccessDialog();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(response['message'] ?? 'Error al guardar la reseña')),
                        );
                      }
                    }
                  },

                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Añadir Reseña',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}
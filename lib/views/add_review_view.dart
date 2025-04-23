import 'package:flutter/material.dart';

class AddReviewView extends StatefulWidget {
  final int bookId;

  const AddReviewView({super.key, required this.bookId});

  @override
  State<AddReviewView> createState() => _AddReviewViewState();
}

class _AddReviewViewState extends State<AddReviewView> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _commentController = TextEditingController();
  double _rating = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Añadir Reseña')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Calificación:'),
              Slider(
                value: _rating,
                min: 0,
                max: 5,
                divisions: 5,
                label: _rating.toString(),
                onChanged: (value) {
                  setState(() {
                    _rating = value;
                  });
                },
              ),
              const SizedBox(height: 20),
              const Text('Comentario:'),
              TextFormField(
                controller: _commentController,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'Escribe tu reseña aquí...',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingresa un comentario';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // Lógica para guardar la reseña
                      // Aquí podrías hacer una llamada a tu API para guardar la reseña en la base de datos
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Reseña añadida')),
                      );
                      Navigator.pop(context); // Regresar a los detalles del libro
                    }
                  },
                  child: const Text('Enviar Reseña'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

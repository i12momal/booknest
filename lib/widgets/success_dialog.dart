import 'package:flutter/material.dart';

// Widget para mostrar un dialogo de éxito
class SuccessDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onAccept;

  // Constructor del widget
  const SuccessDialog({
    super.key,
    required this.title,
    required this.message,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: <Widget>[
        TextButton(
          child: const Text('Aceptar'),
          onPressed: () {
            onAccept();
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }

  // Método estático para mostrar el diálogo de éxito desde cualquier parte de la app
  static void show(BuildContext context, String title, String message, VoidCallback onAccept) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SuccessDialog(
          title: title,
          message: message,
          onAccept: onAccept,
        );
      },
    );
  }
}

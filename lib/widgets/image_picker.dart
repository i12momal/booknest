import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

// Widget para gestionar el diseño y la subida de una imagen
class ImagePickerWidget extends StatefulWidget {
  final File? initialImage;
  final String? imageUrl;
  final ValueChanged<File?> onImagePicked;

  const ImagePickerWidget({super.key, this.initialImage, this.imageUrl, required this.onImagePicked});

  @override
  State<ImagePickerWidget> createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    _imageFile = widget.initialImage;
  }

  // Función para seleccionar una imagen de la galería
  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
      widget.onImagePicked(_imageFile);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Foto',
              style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.file_present_sharp, color: Colors.black),
              onPressed: _pickImage,
            ),
          ],
        ),
        // Mostrar la imagen en un CircleAvatar
        Center(
          child: CircleAvatar(
            radius: 50,
            backgroundImage: _imageFile != null
                ? FileImage(_imageFile!) // Imagen seleccionada
                : (widget.imageUrl != null && widget.imageUrl!.isNotEmpty && widget.imageUrl!.startsWith('http'))
                    ? NetworkImage(widget.imageUrl!) // Imagen de la URL si está disponible
                    : const AssetImage('assets/images/default.png') as ImageProvider, // Imagen predeterminada
          ),
        ),
      ],
    );
  }

}
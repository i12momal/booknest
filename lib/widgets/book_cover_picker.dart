import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class BookCoverPickerWidget extends StatefulWidget {
  final File? initialCoverImage;
  final String? coverImageUrl;
  final ValueChanged<File?> onCoverImagePicked;

  const BookCoverPickerWidget({
    super.key,
    this.initialCoverImage,
    this.coverImageUrl,
    required this.onCoverImagePicked,
  });

  @override
  State<BookCoverPickerWidget> createState() => _BookCoverPickerWidgetState();
}

class _BookCoverPickerWidgetState extends State<BookCoverPickerWidget> {
  File? _coverImageFile;

  @override
  void initState() {
    super.initState();
    _coverImageFile = widget.initialCoverImage;
  }

  // Función para seleccionar la portada
  Future<void> _pickCoverImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _coverImageFile = File(pickedFile.path);
      });
      widget.onCoverImagePicked(_coverImageFile);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 15),
        const Text(
          'Portada',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 5),
        
        // Aquí centramos solo la imagen
        Center(  
          child: GestureDetector(
            onTap: _pickCoverImage, // Acción para seleccionar la portada
            child: Container(
              width: 100, // Ajusta el tamaño del cuadrado
              height: 150, // Ajusta el tamaño del cuadrado
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                image: DecorationImage(
                  image: _coverImageFile != null
                      ? FileImage(_coverImageFile!) // Si hay un archivo, lo mostramos
                      : widget.coverImageUrl != null && widget.coverImageUrl!.isNotEmpty && widget.coverImageUrl!.startsWith('http')
                          ? NetworkImage(widget.coverImageUrl!) // Si hay una URL válida, la mostramos
                          : const AssetImage('assets/images/portada.png') as ImageProvider, // Si no, mostramos una imagen predeterminada
                  fit: BoxFit.cover, // Cambié a BoxFit.cover para que la imagen se recorte apropiadamente si es necesario
                  alignment: Alignment.center,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerWidget extends StatefulWidget {
  final File? initialImage;
  final ValueChanged<File?> onImagePicked;

  const ImagePickerWidget({super.key, this.initialImage, required this.onImagePicked});

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
        const SizedBox(height: 6),
        Center(
          child: ClipOval(
            child: _imageFile != null
                ? Image.file(
                    _imageFile!,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  )
                : Image.asset(
                    'assets/images/default.png',
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
          ),
        ),
      ],
    );
  }
}

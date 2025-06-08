import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:io' show File; // Solo para móvil
import 'package:flutter/foundation.dart' show kIsWeb;

// Widget para gestionar el diseño y la subida de una imagen
class ImagePickerWidget extends StatefulWidget {
  final File? initialImage;
  final Uint8List? initialImageWebBytes; // Para web
  final String? imageUrl;
  final ValueChanged<File?>? onImagePickedMobile;
  final ValueChanged<Uint8List?>? onImagePickedWeb;

  const ImagePickerWidget({
    super.key,
    this.initialImage,
    this.initialImageWebBytes,
    this.imageUrl,
    this.onImagePickedMobile,
    this.onImagePickedWeb,
  });

  @override
  State<ImagePickerWidget> createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  File? _imageFile;
  Uint8List? _imageBytesWeb;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _imageBytesWeb = widget.initialImageWebBytes;
    } else {
      _imageFile = widget.initialImage;
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _imageBytesWeb = bytes;
        });
        if (widget.onImagePickedWeb != null) widget.onImagePickedWeb!(bytes);
      } else {
        final file = File(pickedFile.path);
        setState(() {
          _imageFile = file;
        });
        if (widget.onImagePickedMobile != null) widget.onImagePickedMobile!(file);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider imageProvider;

    if (kIsWeb) {
      if (_imageBytesWeb != null) {
        imageProvider = MemoryImage(_imageBytesWeb!);
      } else if (widget.imageUrl != null && widget.imageUrl!.startsWith('http')) {
        imageProvider = NetworkImage(widget.imageUrl!);
      } else {
        imageProvider = const AssetImage('assets/images/default.png');
      }
    } else {
      if (_imageFile != null) {
        imageProvider = FileImage(_imageFile!);
      } else if (widget.imageUrl != null && widget.imageUrl!.startsWith('http')) {
        imageProvider = NetworkImage(widget.imageUrl!);
      } else {
        imageProvider = const AssetImage('assets/images/default.png');
      }
    }

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
        Center(
          child: CircleAvatar(
            radius: 50,
            backgroundImage: imageProvider,
          ),
        ),
      ],
    );
  }
}
